---
name: tester
description: Testing, dependency management, and Diffusion workflow guidelines for this Ansible role
---

# Testing

When running or writing tests for this repository, always use the **Diffusion MCP tools** (e.g. `mcp_diffusion_*` tools such as `check_molecule_yml`, `check_verify_yml`, `docker_exec_in_molecule`, `troubleshoot_molecule_container`, etc.).

Do not use raw shell commands (`molecule test`, `molecule verify`, etc.) directly. Instead, rely on the Diffusion MCP server to execute, validate, and troubleshoot Molecule scenarios.

This ensures consistent test execution, better diagnostics, and proper integration with the Diffusion workflow.

# Dependency Management

When adding or removing collections and roles, always use the **Diffusion CLI** commands:

- `diffusion role add-collection <name> --namespace <ns>` — add a collection
- `diffusion role remove-collection <name> --namespace <ns>` — remove a collection
- `diffusion role add-role <name>` — add a role
- `diffusion role remove-role <name>` — remove a role

After adding or removing, run `diffusion deps sync` to propagate changes, then `diffusion deps check` to verify consistency.

**Do NOT manually edit** the following files for dependency changes:
- `scenarios/*/requirements.yml`
- `meta/main.yml`

These files are managed by Diffusion and will be overwritten on sync. All dependency modifications must go through the Diffusion CLI to keep `diffusion.toml`, `diffusion.lock`, `requirements.yml`, and `meta/main.yml` in sync.

# Diffusion MCP Safe-List

The Diffusion MCP server (`mcp_diffusion_run_diffusion_command`) only allows a limited set of read-only commands: `--version`, `artifact list`, `cache list`, `cache status`, `deps check`, `deps resolve`, `show`.

If a required Diffusion command is **not in the safe-list**:

1. Use `mcp_diffusion_get_diffusion_cli_reference` to look up the correct command syntax and flags.
2. Run the command locally via `executePwsh` (shell) instead of the MCP tool.
3. After execution, use MCP tools (`deps check`, `deps resolve`, etc.) to verify the result.

# Local-Only Commands

The following Diffusion CLI commands must **only be run on the local system** via `executePwsh` (terminal). **Never** run them inside a Molecule container (`mcp_diffusion_docker_exec_in_molecule`):

- `diffusion cache *` (e.g. `cache clean`, `cache list`, `cache status`)
- `diffusion artifact *` (e.g. `artifact list`, `artifact add`, `artifact remove`)

These commands manage local host resources (disk cache, artifact registries) and have no meaning inside a container context.

# Workflow for Updating Diffusion dependencies

If it were asked by prompt to update Diffusion dependencies, the following workflow should be followed:

1. Run command diffusion deps lock - locally
2. Run command diffusion dpes check - locally - if it said that required updating go to 3, if not exit - no actions required.
3. Run command diffusion deps sync - locally.
4. Run command docker ps - if existing molecule-checkpoint_waf_agent container run 5, if not run 6
5. Run command diffusion molecule --destroy
6. Run command diffusion molecule --force  - locally to start converge with new env
7. Run command diffusion molecule --verify - locally
8. Run command diffusion molecule --idempotence - locally
9. Run command diffusion molecule --lint -locally
10. If all succeeded run diffusion molecule --destroy and show output of command diffusion deps resolve

Create commit description of new versions and tests summary, check if current branch not main\master, if so create another branch names chore/diffusion-update-< date > and push to remote.

# Workflow for creating diffusion variables

If you have task to create diffusion compatible variables follow the following workflow:

1. Check MCP update_diffusion_docs tool - If there is untyped variables not in default folder files, create it in main.yml or fitting to meaning file - to make correct variables declaration use MCP. If variable omitted and have declarion in jinja2 format it's optional, if declarion omitted fully in default it's probably required depending on context (name password, token etc.).
Emtpy strings and empty lists\dicts is always be optional and declared as #-& <var name>. Is not mandatory to put all in main.yml file - it could be seperate files.
2. Check MCP udpate_diffusion_docs tool again - and if popup not declared at default level variables go to 1.
3. When all variables mentioned at default as primary source with type annotation, description, and required\optional flag - Run command diffusion docs - Check that README.md file was updated accordingly.
