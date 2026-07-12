# Product Description — Check Point WAF Agent for Yandex Cloud

## Purpose

This Ansible role automates the deployment of **Check Point CloudGuard AppSec** (WAF — Web Application Firewall) on Yandex Cloud virtual machines. It provides a production-ready, security-hardened setup using rootless Docker with full integration into the Yandex Cloud ecosystem.

The role solves the problem of manually configuring and maintaining WAF infrastructure on Yandex Cloud by providing:

- Automated Docker rootless installation and configuration
- Check Point WAF agent container deployment and registration
- TLS certificate management via Yandex Certificate Manager
- Nginx reverse proxy configuration with rate limiting and SSL hardening
- Systemd service management for reliability and auto-restart
- Multi-agent mode for hosting multiple WAF profiles on a single VM

---

## Target Users

- **DevOps / Platform Engineers** managing web application security on Yandex Cloud
- **Security Teams** deploying WAF protection for HTTP/HTTPS services
- **SREs** automating infrastructure provisioning with Ansible

---

## Use Cases

### 1. Single WAF Agent — Protect One Application

Deploy a single Check Point WAF agent that inspects and filters traffic for one or more backend services behind a shared nginx configuration.

**When to use:** One application (or a group of closely related services) needs WAF protection on a dedicated VM.

**Key variables:**
- `cp_waf_agent_authorization_token` — registration with Check Point portal
- `nginx_servers` — define virtual hosts, SSL, and proxy rules
- `nginx_certs` or `yc_certificates_ids` — TLS certificates

---

### 2. Multi-Agent Mode — Multiple WAF Profiles on One Host

Deploy multiple independent WAF agent containers on the same host, each with its own:
- Check Point profile and token
- Port mappings (HTTPS, HTTP, health)
- Nginx configuration
- Certificate set
- Resource limits

**When to use:** Cost optimization — run several isolated WAF profiles on a single VM instead of provisioning separate instances per application.

**Key variables:**
- `checkpoint_waf_multi_agent: true`
- `cp_waf_agent_multi_services` — profiles with port mappings
- `cp_waf_agent_multi_secrets` — per-profile tokens
- `cp_waf_agent_multi_envs` — per-profile environment and certs
- `cp_waf_agent_multi_resources` — per-profile CPU/memory limits

---

### 3. Yandex Container Registry Integration

Pull the WAF agent Docker image from Yandex Container Registry using IAM tokens obtained from the VM instance metadata service (magic link).

**When to use:** The WAF image is stored in a private Yandex Container Registry and the VM has an attached service account.

**Key variables:**
- `use_yandex_container_registry: true`
- `docker_registry_url: "cr.yandex"`
- `docker_registry_folder` — registry path

---

### 4. Yandex Certificate Manager — Automatic TLS Renewal

A systemd timer periodically fetches TLS certificates from Yandex Certificate Manager and writes them to the WAF agent's certificate directory. This eliminates manual certificate rotation.

**When to use:** Certificates are managed centrally in Yandex Certificate Manager and need to be delivered to the WAF agent without manual intervention.

**Key variables:**
- `yc_certificates_ids` — list of certificate IDs to fetch
- `yandex_certificate_crawler_schedule` — timer interval (default: daily at 19:00)

---

### 5. Inline Certificate Deployment

Copy TLS certificate and key content directly from Ansible Vault into the WAF agent's certs directory.

**When to use:** Certificates are managed outside Yandex Certificate Manager (e.g., purchased from a CA, generated via Let's Encrypt externally).

**Key variables:**
- `nginx_certs` — list of `[filename, content]` pairs

---

### 6. Custom Nginx Rate Limiting and Connection Control

Configure `limit_req_zone` and `limit_conn_zone` directives to protect backends from abuse.

**When to use:** Backends require protection against brute-force, DDoS, or excessive request rates.

**Key variables:**
- `nginx_limits` — zone definitions
- `nginx_servers[].limits` — per-server limit application with burst settings

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 Yandex Cloud VM                  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │         Rootless Docker (docker-adm)       │  │
│  │                                            │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │   CloudGuard AppSec Container        │  │  │
│  │  │   (WAF Agent + Nginx reverse proxy)  │  │  │
│  │  │                                      │  │  │
│  │  │   :443 ← HTTPS traffic              │  │  │
│  │  │   :80  ← HTTP traffic               │  │  │
│  │  │   :8117 ← Health check              │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  Systemd Services                          │  │
│  │  • checkpoint_waf_agent_docker.service     │  │
│  │  • yandex_certificate_crawler.timer        │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  /opt/CloudGuard/WAF/                            │
│  ├── docker-compose.yml                          │
│  ├── .env                                        │
│  ├── AgentConfiguration/                         │
│  ├── NginxConfiguration/ (upstreams, limits)     │
│  ├── Certs/ (TLS certificates)                   │
│  ├── Data/ (agent operational data)              │
│  ├── Logs/                                       │
│  ├── secrets/.CP_WAF_AGENT_TOKEN                 │
│  └── yc_cert_crawler/ (crawler scripts)          │
└─────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  ┌─────────────┐        ┌───────────────────┐
  │  Backends   │        │  Yandex Cloud     │
  │  (upstream) │        │  • Cert Manager   │
  │             │        │  • Container Reg  │
  └─────────────┘        │  • IAM metadata   │
                          └───────────────────┘
```

---

## Security Model

- **Rootless Docker** — the container runtime runs without root privileges, reducing attack surface.
- **Secrets isolation** — WAF tokens stored in dedicated `secrets/` directory with restricted permissions.
- **No default credentials** — all sensitive values require explicit override via Vault.
- **TLS enforcement** — nginx listens on 443 with modern cipher suites and protocol versions.
- **Network isolation** — Docker bridge networks with configurable subnets (multi-agent mode).
- **Resource limits** — CPU and memory constraints prevent container resource exhaustion.

---

## Supported Platforms

- Ubuntu 24.04 (Noble) — primary
- Ubuntu 22.04 (Jammy) — supported
- Debian — compatible

---

## Integration Points

| System | Integration |
|---|---|
| Check Point Infinity Portal | Agent registration via token |
| Yandex Container Registry | Private image pull via IAM |
| Yandex Certificate Manager | Automatic TLS cert delivery |
| Yandex Cloud Metadata Service | IAM token acquisition (magic link) |
| Ansible Galaxy | Role distribution |
| GitHub Actions | CI/CD (tests, updates, releases) |
