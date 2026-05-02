# Testing

When running or writing tests for this repository, always use the **Diffusion MCP tools** (e.g. `mcp_diffusion_*` tools such as `check_molecule_yml`, `check_verify_yml`, `docker_exec_in_molecule`, `troubleshoot_molecule_container`, etc.).

Do not use raw shell commands (`molecule test`, `molecule verify`, etc.) directly. Instead, rely on the Diffusion MCP server to execute, validate, and troubleshoot Molecule scenarios.

This ensures consistent test execution, better diagnostics, and proper integration with the Diffusion workflow.
