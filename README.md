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
<!-- begin role_variables -->

## Role Variables

| Variable | Type | Default | Source | Description |
|----------|------|---------|--------|-------------|
| `checkpoint_waf_multi_agent` | bool | `false` | defaults/checkpoint_waf_agent_defaults.yml | Enable multi-agent mode to deploy multiple WAF profiles on a single host |
| `cp_waf_agent_authorization_token` | string | **required** | defaults/checkpoint_waf_agent_defaults.yml | Check Point WAF agent registration token (override with vault or secrets) |
| `cp_waf_agent_cpu_limits` | string | *optional* | defaults/checkpoint_waf_agent_defaults.yml | CPU limits for the WAF agent container (e.g., "2.6") |
| `cp_waf_agent_mem_limits` | string | *optional* | defaults/checkpoint_waf_agent_defaults.yml | Memory limits for the WAF agent container (e.g., "1GB") |
| `cp_waf_agent_multi_envs` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of per-profile environment configurations with image family and certificate IDs |
| `cp_waf_agent_multi_images` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of Docker image families with registry and image configuration per family |
| `cp_waf_agent_multi_network` | dict | *optional* | defaults/checkpoint_waf_agent_defaults.yml | Docker bridge network configuration for multi-agent containers (subnet, gateway) |
| `cp_waf_agent_multi_resources` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of per-profile Docker resource limits (CPU and memory) |
| `cp_waf_agent_multi_secrets` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of per-profile WAF agent tokens for registration with Check Point |
| `cp_waf_agent_multi_services` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of service profiles with port mappings and profile identifiers |
| `docker_add_alias` | bool | `true` | defaults/docker_defaults.yml | Add Docker alias to user bashrc |
| `docker_allow_ping` | bool | `false` | defaults/docker_defaults.yml | Allow Docker containers to ping |
| `docker_allow_privileged_ports` | bool | `false` | defaults/docker_defaults.yml | Allow Docker to bind privileged ports (< 1024) |
| `docker_compose` | bool | `true` | defaults/docker_defaults.yml | Enable Docker Compose installation |
| `docker_cp_agent_image` | string | `"cloudguard-appsec-standalone:1580296"` | defaults/checkpoint_waf_agent_defaults.yml | Image name with tag. |
| `docker_daemon_json_template` | string | `daemon_no_snapshotter.json.j2` | defaults/docker_defaults.yml | Template for Docker daemon configuration |
| `docker_full_image_path` | string | `{{{, docker_registry_url + "/" +, docker_registry_folder +, "/" + docker_cp_agent_image, }}}` | defaults/checkpoint_waf_agent_defaults.yml | Full docker image pull path. It could be resolved by docker_registry_folder, docker_cp_agent_image and docker_registry_url - as it's jinja2 shortage |
| `docker_registry_folder` | string | `"checkpoint"` | defaults/checkpoint_waf_agent_defaults.yml | Docker registry folder name. |
| `docker_registry_url` | string | `"docker.io"` | defaults/checkpoint_waf_agent_defaults.yml | Docker registry name |
| `docker_rootful` | bool | `false` | defaults/docker_defaults.yml | Enable rootful Docker (not recommended) |
| `docker_rootful_enabled` | bool | `false` | defaults/docker_defaults.yml | Enable rootful Docker daemon |
| `docker_rootful_opts` | string | `{--live-restore --icc=false --default-ulimit nproc=512:1024, --default-ulimit nofile=100:200 -H fd://}` | defaults/docker_defaults.yml | Docker daemon options for rootful mode |
| `docker_rootless_service_template` | string | `docker_rootless_cgroupdriver.service.j2` | defaults/docker_defaults.yml | Template for Docker rootless systemd service |
| `docker_service_restart` | bool | `false` | defaults/docker_defaults.yml | Restart Docker service after configuration changes |
| `docker_user` | string | `docker-adm` | defaults/docker_defaults.yml | Docker user for rootless Docker installation |
| `docker_user_bashrc` | bool | `false` | defaults/docker_defaults.yml | Extend Docker user bashrc configuration |
| `gaddr` | string | `"169.254.169.254"` | defaults/checkpoint_waf_agent_defaults.yml | Magic link accessable from VM instance. |
| `gpath` | string | `"computeMetadata/v1/instance/service-accounts"` | defaults/checkpoint_waf_agent_defaults.yml | Magic Link path to service account access token |
| `iam_link` | string | `"http://{{ gaddr }}/{{ gpath }}/default/token"` | defaults/checkpoint_waf_agent_defaults.yml | Full iam link. It could be resolved by gaddr and gpath automatically - as it's jinja2 shortage |
| `inventory_dir` | - | - | tasks/checkpoint_waf_agent_install.yml | - |
| `multi_profile` | - | - | templates/cp_waf_agent.service.j2 | - |
| `multi_secret` | - | - | templates/.CP_WAF_AGENT_TOKEN.j2 | - |
| `nginx_certs` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of certificate content pairs to copy directly into certs directory |
| `nginx_limits` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of nginx limit definitions for rate limiting and connection limiting |
| `nginx_servers` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of nginx virtual server configurations with SSL and proxy settings |
| `path_backen_config` | - | - | templates/Env.j2 | - |
| `path_backend_config` | string | `"/opt/CloudGuard/WAF"` | defaults/checkpoint_waf_agent_defaults.yml | Path to docker-compose and config files |
| `path_cp_agent_waf_certs` | string | `"{{ path_backend_config }}/Certs"` | defaults/checkpoint_waf_agent_defaults.yml | Path where Checkpoint CloudGuard agent will storre Certificates. It could be resolved by path_backend_config automatically to Certs - as it's jinja2 shortage |
| `path_cp_agent_waf_configuration` | string | `"{{ path_backend_config }}/AgentConfiguration"` | defaults/checkpoint_waf_agent_defaults.yml | Path where Agent Configuration will be stored.It could be resolved by path_backend_config automatically to AgentConfiguration - as it's jinja2 shortage |
| `path_cp_agent_waf_data` | string | `"{{ path_backend_config }}/Data"` | defaults/checkpoint_waf_agent_defaults.yml | Path where Checkpoint CloudGuard agent will store data. It could be resolved by path_backend_config automatically to Data - as it's jinja2 shortage |
| `path_cp_agent_waf_logs` | string | `"{{ path_backend_config }}/Logs"` | defaults/checkpoint_waf_agent_defaults.yml | Path where Logs will be stored. It could be resolved by path_backend_config automatically to Logs - as it's jinja2 shortage |
| `path_cp_nginx_configuration` | string | `"{{ path_backend_config }}/NginxConfiguration"` | defaults/checkpoint_waf_agent_defaults.yml | Path where Nginx Configuration will be stored. It could be resolved by path_backend_config automatically to NginxConfiguration - as it's jinja2 shortage |
| `path_docker` | string | `/opt/Docker/root` | defaults/docker_defaults.yml | Docker installation directory |
| `path_docker_root` | string | `/opt/Docker/root/lib` | defaults/docker_defaults.yml | Docker root library directory |
| `playbook_dir` | - | - | tasks/checkpoint_waf_agent_install.yml | - |
| `profile_name` | - | - | templates/yandex_certificate_crawler_profile.service.j2 | - |
| `profile_yc_certificates_ids` | - | - | templates/yandex_certificate_crawler_profile.service.j2 | - |
| `role_name` | - | - | tasks/checkpoint_waf_agent_install.yml | - |
| `use_yandex_container_registry` | bool | `false` | defaults/checkpoint_waf_agent_defaults.yml | Does it required to autentificate to Yandex Cloud registry by using Magic Link token of SA? |
| `yandex_certificate_crawler_schedule` | string | *optional* | defaults/checkpoint_waf_agent_defaults.yml | Systemd timer schedule for certificate crawler (e.g., "*-*-* 03:00:00") |
| `yandex_cloud_token` | string | `"fakekey"` | defaults/checkpoint_waf_agent_defaults.yml | Yandex Cloud static token. |
| `yandex_cloud_token_static` | string | `"dummy-xxxx-xxxx-xxx"` | defaults/checkpoint_waf_agent_defaults.yml | Yandex Cloud static IAM token for testing (override with vault or secrets) |
| `yandex_crawler_script_files` | - | - | tasks/checkpoint_waf_agent_install.yml | - |
| `yc_certificates_ids` | list | *optional* | defaults/checkpoint_waf_agent_defaults.yml | List of Yandex Certificate Manager certificate IDs to fetch periodically |

<!-- end role_variables -->
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
    docker_cp_agent_image: "cloudguard-appsec-standalone:1567986"

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
| `checkpoint_waf_agent` | Run only single-agent WAF installation tasks |
| `checkpoint_waf_multi_agent` | Run only multi-agent WAF installation tasks |

---

## CI / CD

The repository includes three GitHub Actions workflows:

### Tests (`.github/workflows/tests.yml`)

Runs on every pull request and on manual dispatch. Executes the full Diffusion test suite: lint, molecule converge, verify, and idempotence checks against Ubuntu 24.04 with systemd.

### Scheduled Update (`.github/workflows/update.yml`)

Runs weekly (Monday 07:00 UTC) and on manual dispatch. Uses `diffusion-update` to check for dependency updates, runs the full test suite, and opens a PR titled `chore(deps): update diffusion dependencies` if anything changed.

### Release (`.github/workflows/release.yml`)

Triggered by pushing a `v*` tag. Creates a GitHub Release with auto-generated release notes, attaches a tarball with SLSA build provenance attestation, and publishes the role to Ansible Galaxy.

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
- Built-in Diffusion test framework for port and Docker container verification

Molecule scenarios are located in `scenarios/default/` and use the Diffusion test type. Verification tests check that expected ports (8443, 8080, 8117) are listening and the `cp_waf_agent` container is running.

Current `diffusion.toml` settings for this role:

| Setting | Value |
|---|---|
| Container registry | `ghcr.io` (Public) |
| Molecule image | `polar-team/diffusion-molecule-container:latest-amd64` |
| Python | `3.11 – 3.13`, pinned `3.13` |
| Ansible | `>=13.0.0` → resolved `14.1.0` |
| ansible-lint | `>=24.0.0` → resolved `26.4.0` |
| molecule | `>=24.0.0` → resolved `26.4.0` |
| yamllint | `>=1.35.0` → resolved `1.38.0` |
| `community.general` | `>=12.2.0` → resolved `13.1.0` |
| `community.docker` | `>=5.0.6` → resolved `5.2.1` |
| `konstruktoid.docker_rootless` | `>=1.13.0` → resolved `v1.23.0` |
| Tests | Diffusion (`type = "diffusion"`) |
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

---

## Multi-Agent Mode (`checkpoint_waf_multi_agent`)

Multi-agent mode deploys **multiple WAF profiles** on a single host, each running as an independent Docker container with its own directories, token, nginx config, ports, and certificate crawler.

Enable it by setting `checkpoint_waf_multi_agent: true` in your vars and providing the profile lists described below.

### How it works

- A **single `docker-compose.yml`** (rendered from `docker-compose-multi.yml.j2`) is deployed, containing one service per profile.
- Each profile gets its own subdirectory tree under `path_backend_config`:
  ```
  /opt/CloudGuard/WAF/
  ├── AgentConfiguration/<profile>/
  ├── NginxConfiguration/<profile>/
  ├── Certs/<profile>/
  ├── Data/<profile>/
  ├── Logs/<profile>/
  └── secrets/<profile>/.CP_WAF_AGENT_TOKEN
  ```
- A **per-profile systemd cert crawler service + timer** is installed for each profile.
- Each profile gets its own **`checkpoint_waf_agent_docker_<profile>.service`** systemd unit managing its docker-compose stack (start/stop/restart per profile independently).

### Required Variables

#### `cp_waf_agent_multi_services`
One entry per profile. Controls the profile identifier and port mappings used in the docker-compose stack.

```yaml
cp_waf_agent_multi_services:
  - profile_name: profile1      # unique identifier — used in dir names, container names
    https_port: 8443            # host port → container 443
    http_port: 8080             # host port → container 80
    health_port: 8117           # host port → container 8117 (nano-agent health)
  - profile_name: profile2
    https_port: 9443
    http_port: 9080
    health_port: 9117
```

#### `cp_waf_agent_multi_images`
Image families referenced by `cp_waf_agent_multi_envs`. Typically one entry unless profiles use different WAF builds. All fields except `family_name` are optional and fall back to the corresponding role defaults.

```yaml
cp_waf_agent_multi_images:
  - family_name: default          # referenced by cp_waf_agent_multi_envs[].image_family
    # Optional overrides (fall back to role defaults when omitted):
    # registry_url: "cr.yandex"
    # registry_folder: "crp8cgfah9nqgde7q9rm/checkpoint"
    # cp_agent_image: "cloudguard-appsec-standalone:1567986"
```

#### `cp_waf_agent_multi_envs`
Per-profile environment config. `profile_name` must match an entry in `cp_waf_agent_multi_services`.

```yaml
cp_waf_agent_multi_envs:
  - profile_name: profile1
    image_family: default
    yc_certificates_ids:        # Yandex CM certificate IDs for this profile
      - cert-xxxx-1
  - profile_name: profile2
    image_family: default
    yc_certificates_ids: []
```

#### `cp_waf_agent_multi_secrets`
Declares per-profile token files written to `secrets/<profile>/.CP_WAF_AGENT_TOKEN`. Each entry must include both the `profile_name` and the `secret` — the Check Point WAF agent registration token for that profile.

```yaml
cp_waf_agent_multi_secrets:
  - profile_name: profile1
    secret: "your-checkpoint-token-for-profile1"
  - profile_name: profile2
    secret: "your-checkpoint-token-for-profile2"
```

#### `cp_waf_agent_multi_resources`
Per-profile Docker resource limits. If omitted for a profile, compose defaults apply.

```yaml
cp_waf_agent_multi_resources:
  - profile_name: profile1
    cpu: "2.6"
    mem: "1GB"
  - profile_name: profile2
    cpu: "2.0"
    mem: "1GB"
```

#### `cp_waf_agent_multi_network`
Shared Docker bridge network for all profile containers.

```yaml
cp_waf_agent_multi_network:
  subnet: "172.20.0.0/16"
  gateway: "172.20.0.1"
```

### Example Play

```yaml
- hosts: waf_hosts
  vars:
    checkpoint_waf_multi_agent: true
    cp_waf_agent_multi_network:
      subnet: "172.20.0.0/16"
      gateway: "172.20.0.1"
    cp_waf_agent_multi_images:
      - family_name: default
    cp_waf_agent_multi_services:
      - profile_name: app_a
        https_port: 8443
        http_port: 8080
        health_port: 8117
      - profile_name: app_b
        https_port: 9443
        http_port: 9080
        health_port: 9117
    cp_waf_agent_multi_envs:
      - profile_name: app_a
        image_family: default
        yc_certificates_ids:
          - cert-xxxx-app-a
      - profile_name: app_b
        image_family: default
        yc_certificates_ids: []
    cp_waf_agent_multi_secrets:
      - profile_name: app_a
        secret: "your-checkpoint-token-for-app-a"
      - profile_name: app_b
        secret: "your-checkpoint-token-for-app-b"
    cp_waf_agent_multi_resources:
      - profile_name: app_a
        cpu: "2.6"
        mem: "1GB"
      - profile_name: app_b
        cpu: "2.0"
        mem: "1GB"
  roles:
    - checkpoint_waf_agent
```

### Molecule Test Scenario

A dedicated molecule scenario exists at `scenarios/multi/`. It deploys two profiles (`profile1` on ports 8443/8080/8117, `profile2` on ports 9443/9080/9117) and verifies that all six ports are listening and both containers are running.

```bash
# Run the multi-agent scenario
diffusion molecule --scenario multi

# Or step by step
diffusion molecule --scenario multi --converge
diffusion molecule --scenario multi --verify
diffusion molecule --scenario multi --idempotence
```
