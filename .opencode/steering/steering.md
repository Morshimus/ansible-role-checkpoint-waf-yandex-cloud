# Project Steering — ansible-role-checkpoint-waf-yandex-cloud

## Overview

This is an Ansible role (`checkpoint_waf_agent`) that installs and registers Check Point CloudGuard AppSec (WAF) as a rootless Docker Compose service on Ubuntu/Debian hosts. It integrates with Yandex Cloud services (Container Registry, Certificate Manager) and supports both single-agent and multi-agent deployment modes.

**Author:** Daniel Dalavurak — Polar Team  
**License:** MIT  
**Namespace:** Morshimus

---

## Project Structure

```
├── defaults/                  # Default variables (split by concern)
│   ├── checkpoint_waf_agent_defaults.yml   # WAF agent configuration
│   └── docker_defaults.yml                 # Docker installation settings
├── tasks/
│   ├── main.yml                            # Entry point — routes to sub-tasks
│   ├── docker_install.yml                  # Docker rootless setup
│   ├── checkpoint_waf_agent_install.yml    # Single-agent deployment
│   └── checkpoint_waf_multi_agent.yml      # Multi-agent deployment
├── templates/                 # Jinja2 templates for configs and systemd units
├── files/                     # Static files (docker-compose, scripts)
├── handlers/main.yml          # Service restart handlers
├── vars/main.yml              # Variable overrides / examples (secrets go here)
├── meta/main.yml              # Galaxy metadata and dependencies
├── scenarios/                 # Molecule test scenarios
│   ├── default/               # Single-agent scenario
│   └── multi/                 # Multi-agent scenario
├── diffusion.toml             # Diffusion tool configuration
└── diffusion.lock             # Pinned dependency versions (auto-generated)
```

---

## Coding Rules

### Ansible Style

- Use fully qualified collection names (`ansible.builtin.*`, `community.docker.*`).
- All tasks must have a descriptive `name:` field.
- Use `block:` for logically grouped tasks with shared conditions.
- Variables in `defaults/` use the `#-|`, `#-?`, `#-&`, `#-!` annotation format for type, description, optional, and required markers.
- Conditional logic uses `when:` with `molecule_yml is defined` / `molecule_yml is not defined` to distinguish test vs production paths.
- Use `become: true` / `become_user:` for privilege escalation, never run as root directly.
- Templates use `.j2` extension and live in `templates/`.
- Static files live in `files/`.
- Handlers use `notify:` to trigger restarts — never restart services inline.

### Variable Naming

- All role-specific variables are prefixed with descriptive names: `cp_waf_agent_*`, `docker_*`, `path_*`, `nginx_*`, `yandex_*`.
- Multi-agent variables use `cp_waf_agent_multi_*` prefix.
- Secrets must be marked with `#-!` (required) and stored in Ansible Vault.
- Jinja2 shorthand compositions are documented with `#-?` comments explaining resolution.

### Docker

- Docker is installed in **rootless** mode by default via the `docker_rootless` dependency role.
- All Docker operations run as `docker_user` (default: `docker-adm`) with proper `XDG_RUNTIME_DIR` and `DOCKER_HOST` environment.
- Docker Compose v2 is used via `community.docker.docker_compose_v2_pull`.
- Images are pulled with retries (3 attempts, 10s delay).

### Security

- Tokens and secrets are never hardcoded — use Ansible Vault or external secret managers.
- Default values for secrets are dummy/fake placeholders for testing only.
- File permissions follow least-privilege: secrets at `0754`, configs at `0755`, `.env` at `0600`.
- Docker rootful mode is disabled by default (`docker_rootful: false`).

### Testing

- Testing uses **Diffusion** — a Polar Team CLI tool wrapping Molecule.
- Scenarios live in `scenarios/` (not `molecule/`), the `molecule/` directory is intentionally empty.
- Test type is `diffusion` (port checks + container verification).
- Run tests with: `diffusion molecule --converge`, `--verify`, `--idempotence`.
- Multi-agent tests use `--scenario multi`.
- CI runs on Ubuntu 24.04 with systemd inside the Diffusion molecule container.

### Linting

- yamllint and ansible-lint rules are defined in `diffusion.toml`.
- Key lint skips: `meta-incorrect`, `role-name[path]`, `var-naming[no-role-prefix]`, `schema[meta]`.
- yamllint ignores: `.git/*`, `molecule/**`, `vars/*`, `files/*`, `defaults/*`.
- Comments indentation rule is disabled.

### Git & CI/CD

- Branch from `main` for features.
- PRs trigger the full test suite via `.github/workflows/tests.yml`.
- Weekly dependency updates via `.github/workflows/update.yml`.
- Releases are created by pushing `v*` tags → GitHub Release + Ansible Galaxy publish.
- Lock file (`diffusion.lock`) is auto-generated — never edit manually.

---

## Key Dependencies

| Dependency | Purpose |
|---|---|
| `konstruktoid.docker_rootless` | Installs rootless Docker for the service user |
| `community.general` | General Ansible modules |
| `community.docker` | Docker Compose and login modules |
| `ansible.posix` | POSIX utilities |

---

## Important Conventions

1. **Two deployment modes** are mutually exclusive: single-agent (`checkpoint_waf_multi_agent: false`) and multi-agent (`checkpoint_waf_multi_agent: true`). The `tasks/main.yml` routes accordingly.
2. **Yandex Cloud integration** is optional — controlled by `use_yandex_container_registry` and `yc_certificates_ids`.
3. **Certificate management** has two mutually exclusive approaches: `nginx_certs` (inline content) or `yc_certificates_ids` (Yandex Certificate Manager crawler).
4. **Tags** allow selective execution: `docker`, `checkpoint_waf_agent`, `checkpoint_waf_multi_agent`.
5. **README variable table** is auto-generated between `<!-- begin role_variables -->` and `<!-- end role_variables -->` markers — update via the GitHub Actions script at `.github/scripts/update-readme-versions.sh`.
