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
