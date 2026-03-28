# checkpoint_waf_agent

Ansible role for installing and registering [Check Point CloudGuard AppSec](https://www.checkpoint.com/cloudguard/appsec/) (WAF) as a rootless Docker Compose service on Ubuntu/Debian hosts. Includes Yandex Cloud container registry support and a certificate crawler for Yandex Certificate Manager.

## Requirements

- Ubuntu Noble (24.04) or Debian
- Ansible >= 2.1
- Collections: `community.general`, `community.docker`
- Role dependency: `docker_rootless` (must be available in your roles path)
- `jq` and `curl` on the target host (installed automatically in molecule runs)

---

## Role Variables

### Defaults (`defaults/checkpoint_waf_agent_defaults.yml`)

| Variable | Default | Description |
|---|---|---|
| `path_backend_config` | `/opt/CloudGuard/WAF` | Root directory for all WAF agent config and data |
| `path_cp_agent_waf_data` | `{{ path_backend_config }}/Data` | Agent operational data directory |
| `path_cp_agent_waf_certs` | `{{ path_backend_config }}/Certs` | TLS certificates directory (mounted into container) |
| `path_cp_agent_waf_configuration` | `{{ path_backend_config }}/AgentConfiguration` | Agent configuration directory |
| `path_cp_nginx_configuration` | `{{ path_backend_config }}/NginxConfiguration` | Nginx configuration directory |
| `path_cp_agent_waf_logs` | `{{ path_backend_config }}/Logs` | Agent log directory |
| `docker_registry_url` | `docker.io` | Docker registry URL |
| `docker_registry_folder` | `checkpoint` | Registry namespace/folder |
| `docker_cp_agent_image` | `cloudguard-appsec-standalone:1185074` | WAF agent image name and tag |
| `docker_full_image_path` | `{{ docker_registry_url }}/{{ docker_registry_folder }}/{{ docker_cp_agent_image }}` | Full image reference (computed) |
| `use_yandex_container_registry` | `false` | Pull image from Yandex Container Registry using IAM token |
| `gaddr` | `169.254.169.254` | Yandex metadata service address |
| `gpath` | `computeMetadata/v1/instance/service-accounts` | Yandex metadata service path |
| `iam_link` | `http://{{ gaddr }}/{{ gpath }}/default/token` | Full IAM token endpoint URL |
| `yandex_cloud_token` | `fakekey` | Static Yandex Cloud token (used in molecule tests) |

### Defaults (`defaults/docker_defaults.yml`)

| Variable | Default | Description |
|---|---|---|
| `docker_user` | `docker-adm` | System user that runs Docker rootless |
| `docker_rootful` | `false` | Run Docker in rootful mode |
| `docker_rootful_enabled` | `false` | Enable rootful Docker service |
| `docker_rootful_opts` | see defaults | Extra options for rootful Docker daemon |
| `docker_add_alias` | `true` | Add `docker` shell alias for the docker user |
| `docker_user_bashrc` | `false` | Modify docker user `.bashrc` |
| `docker_allow_privileged_ports` | `false` | Allow binding to ports < 1024 |
| `docker_allow_ping` | `false` | Allow ICMP ping in containers |
| `docker_compose` | `true` | Install Docker Compose |
| `docker_service_restart` | `false` | Restart Docker service after install |
| `docker_daemon_json_template` | `daemon_no_snapshotter.json.j2` | Template for Docker daemon config (disables containerd snapshotter) |
| `path_docker` | `/opt/Docker/root` | Docker root directory |
| `path_docker_root` | `/opt/Docker/root/lib` | Docker data-root directory |

### Required Variables (`vars/`)

These must be provided — typically via an encrypted `vars/secrets.yml` or vault.

| Variable | Description |
|---|---|
| `cp_waf_agent_authorization_token` | Check Point WAF agent registration token |
| `yandex_cloud_token_static` | Static Yandex Cloud IAM token (used in molecule/testing) |

### Optional Variables

| Variable | Description |
|---|---|
| `cp_waf_agent_cpu_limits` | CPU limit for the WAF agent container (e.g. `"2.6"`) |
| `cp_waf_agent_mem_limits` | Memory limit for the WAF agent container (e.g. `"1GB"`) |
| `nginx_certs` | List of `[filename, content]` pairs to write into the certs directory |
| `yc_certificates_ids` | List of Yandex Certificate Manager certificate IDs to fetch |
| `yandex_certificate_crawler_schedule` | Systemd OnCalendar schedule for cert crawler (default: `*-*-* 19:00:00`) |
| `nginx_limits` | List of nginx rate/connection limit zones (see example below) |
| `nginx_servers` | List of nginx virtual server definitions (see example below) |

---

## nginx_limits

Defines `limit_conn_zone` and `limit_req_zone` directives written to `NginxConfiguration/limits.conf`.

```yaml
nginx_limits:
  - conn:
      zone: "app_conn:5m"
  - req:
      zone: "app_req:5m"
      rate: "30r/s"
```

---

## nginx_servers

Defines virtual server blocks written to `NginxConfiguration/upstreams.conf`. Each server listens on 443 SSL and proxies to upstream backends.

```yaml
nginx_servers:
  - server_name: "example.com"
    limits:
      - type: "req"
        zone: "app_req"
        burst: "20"
      - type: "conn"
        zone: "app_conn"
        requests: "10000"
    client_body_timeout: "30s"
    client_header_timeout: "30s"
    ssl_stapling: "on"
    ssl_stapling_verify: "on"
    ssl_session_tickets: "off"
    ssl_session_timeout: "6h"
    ssl_protocols:
      - "TLSv1.2"
      - "TLSv1.3"
    ssl_ciphers:
      - "ECDHE-ECDSA-AES128-GCM-SHA256"
      - "ECDHE-RSA-AES128-GCM-SHA256"
      - "ECDHE-ECDSA-AES256-GCM-SHA384"
      - "ECDHE-RSA-AES256-GCM-SHA384"
    ssl_prefer_server_ciphers: "on"
    certificate_name: "app"   # resolves to app-crt.pem / app-key.pem in certs dir
    locations:
      - path: "/"
        proxy_pass: "http://10.10.10.10"
        proxy_host: "example.com"
        proxy_connect_timeout: "60s"
        proxy_send_timeout: "60s"
        proxy_read_timeout: "60s"
```

Location options:

| Key | Required | Description |
|---|---|---|
| `path` | yes | Location path |
| `proxy_pass` | yes | Upstream URL |
| `proxy_host` | yes | Value for `Host` header |
| `cors_headers` | no | Add CORS headers (`true`/`false`) |
| `api_host` | no | `Access-Control-Allow-Origin` host (when `cors_headers: true`) |
| `proxy_header_strategy` | no | `purge` (WebSocket upgrade) or `keep-alive` |
| `ssl_forward` | no | Enable `proxy_ssl_name` / `proxy_ssl_server_name` |
| `proxy_connect_timeout` | no | Default `60s` |
| `proxy_send_timeout` | no | Default `60s` |
| `proxy_read_timeout` | no | Default `60s` |
| `proxy_pass_request_headers` | no | Default `on` |

---

## nginx_certs

Copy TLS certificate/key content directly into the certs directory:

```yaml
app_key: |
  -----BEGIN PRIVATE KEY-----
  ...
app_pem: |
  -----BEGIN CERTIFICATE-----
  ...

nginx_certs:
  - ["app-key.pem", "{{ app_key }}"]
  - ["app-crt.pem", "{{ app_pem }}"]
```

---

## Yandex Certificate Crawler

When `yc_certificates_ids` is defined, the role installs a systemd timer that periodically fetches certificates from Yandex Certificate Manager and writes them to `path_cp_agent_waf_certs`.

```yaml
yc_certificates_ids:
  - "fpq1abc2def3ghi4jkl5"
  - "fpq6mno7pqr8stu9vwx0"

yandex_certificate_crawler_schedule: "*-*-* 03:00:00"
```

When `use_yandex_container_registry: true`, the role fetches an IAM token from the instance metadata service and uses it to authenticate with the Yandex Container Registry before pulling the WAF agent image.

---

## Dependencies

- Role: `docker_rootless` — installs and configures rootless Docker for `docker_user`

---

## Example Playbook

Minimal example using Docker Hub image:

```yaml
- hosts: waf_nodes
  become: true
  vars_files:
    - vars/secrets.yml
  roles:
    - role: cp_waf_agent
```

With Yandex Container Registry and full nginx config:

```yaml
- hosts: waf_nodes
  become: true
  vars_files:
    - vars/secrets.yml
  vars:
    use_yandex_container_registry: true
    docker_registry_url: "cr.yandex"
    docker_registry_folder: "crp8cgfah9nqgde7q9rm/checkpoint"
    docker_cp_agent_image: "cloudguard-appsec-standalone:1185074"

    cp_waf_agent_cpu_limits: "2.6"
    cp_waf_agent_mem_limits: "1GB"

    yc_certificates_ids:
      - "fpq1abc2def3ghi4jkl5"

    nginx_limits:
      - conn:
          zone: "app_conn:5m"
      - req:
          zone: "app_req:5m"
          rate: "30r/s"

    nginx_servers:
      - server_name: "api.example.com"
        limits:
          - type: "req"
            zone: "app_req"
            burst: "20"
        client_body_timeout: "30s"
        client_header_timeout: "30s"
        ssl_stapling: "on"
        ssl_stapling_verify: "on"
        ssl_session_tickets: "off"
        ssl_session_timeout: "6h"
        ssl_protocols:
          - "TLSv1.2"
          - "TLSv1.3"
        ssl_ciphers:
          - "ECDHE-ECDSA-AES128-GCM-SHA256"
          - "ECDHE-RSA-AES128-GCM-SHA256"
        ssl_prefer_server_ciphers: "on"
        certificate_name: "api"
        locations:
          - path: "/"
            proxy_pass: "http://10.10.10.10:8080"
            proxy_host: "api.example.com"

  roles:
    - role: cp_waf_agent
```

`vars/secrets.yml` (encrypt with ansible-vault):

```yaml
cp_waf_agent_authorization_token: "your-checkpoint-token-here"
yandex_cloud_token_static: "your-yc-iam-token-here"  # for molecule/testing only
```

---

## Tags

| Tag | Description |
|---|---|
| `docker` | Run only Docker installation tasks |
| `checkpoint_waf_agent` | Run only WAF agent installation tasks |

---

## License

MIT

## Author

Daniel Dalavurak — Polar Team

---

## Diffusion

This role is managed with [Diffusion](https://github.com/Polar-Team/diffusion) — a cross-platform CLI tool written in Go by Polar Team that streamlines Ansible role testing with Molecule. It provides an integrated environment for role development, testing, and validation with built-in support for container registries, HashiCorp Vault integration, dependency locking, and linting.

Key capabilities:
- Docker-based Molecule testing with a pre-built container (`polar-team/diffusion-molecule-container`)
- Lock file system (`diffusion.lock`) for reproducible Python, Ansible, collection, and role versions
- Integrated yamllint and ansible-lint with rules defined in `diffusion.toml`
- Support for public (ghcr.io, docker.io) and private registries (Yandex Cloud, AWS ECR, GCP)
- Optional HashiCorp Vault integration for credential management
- Build cache for Docker images, collections, and Python packages

Current `diffusion.toml` settings for this role:

| Setting | Value |
|---|---|
| Container registry | `ghcr.io` (Public) |
| Molecule image | `polar-team/diffusion-molecule-container:latest-amd64` |
| Python | `3.11 – 3.13`, pinned `3.13` |
| Ansible | `>=13.0.0` → resolved `13.4.0` |
| ansible-lint | `>=24.0.0` → resolved `26.3.0` |
| molecule | `>=24.0.0` → resolved `26.3.0` |
| yamllint | `>=1.35.0` → resolved `1.38.0` |
| `community.general` | `>=12.2.0` → resolved `12.4.0` |
| `community.docker` | `>=5.0.6` → resolved `5.0.6` |
| `konstruktoid.docker_rootless` | `<1.12.0` → resolved `v1.11.0` |
| Vault | disabled |
| Cache | enabled (Docker + uv) |

The `diffusion.lock` file is auto-generated — do not edit it manually.

---

## Contributing

1. Fork the repository and create a feature branch from `main`.

2. Install Diffusion — see the [official installation guide](https://github.com/Polar-Team/diffusion):
   ```bash
   # Using Go
   go install github.com/Polar-Team/diffusion@latest

   # Windows (Chocolatey)
   choco install diffusion
   ```

3. Make your changes, then run linting:
   ```bash
   diffusion molecule --lint
   ```

4. Run the molecule converge and verify tests:
   ```bash
   # Apply the role to the test container
   diffusion molecule --converge

   # Run verification tests
   diffusion molecule --verify

   # Check idempotence
   diffusion molecule --idempotence

   # Clean up
   diffusion molecule --destroy
   ```
   Tests run against Ubuntu 24.04 with systemd inside the Diffusion molecule container.

5. If you change role dependencies (collections, roles, Python/tool versions), update `diffusion.toml` and regenerate the lock file:
   ```bash
   diffusion deps lock
   ```
   Verify the lock file is in sync before opening a PR:
   ```bash
   diffusion deps check
   ```

6. Open a pull request with a clear description of what changed and why.

Linting rules (yamllint + ansible-lint) are defined in `diffusion.toml` and enforced by CI automatically.
