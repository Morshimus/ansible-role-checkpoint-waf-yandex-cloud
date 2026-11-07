---
description: Diffusion lock change pipeline — deps check/sync, then the full Molecule test pipeline (force, lint, verify, idempotence).
agent: diffusion_tester
---

`diffusion.lock` has changed (or you were asked to validate dependencies). Follow this workflow strictly.

Extra context from the caller (may be empty): $ARGUMENTS

1. Run `diffusion deps check` using the Diffusion MCP tool (`run_diffusion_command` with subcommand `deps check`).
2. Inspect the output:
   - If the check indicates the lock file is OUT OF DATE or a sync is required, run `diffusion deps sync` via the bash tool (it is not in the MCP safe-list), then re-run `diffusion deps check` via MCP to confirm it is in sync.
   - If the check indicates everything is IN SYNC (lock is up-to-date), proceed to step 3.
3. Run the full Molecule test pipeline sequentially via the bash tool. Stop and report immediately if any step fails:
   1. `diffusion molecule --force` (force reinstall deps + converge)
   2. `diffusion molecule --lint` (yamllint + ansible-lint)
   3. `diffusion molecule --verify` (verification tests)
   4. `diffusion molecule --idempotence` (idempotence check)
4. Report the result of each step clearly, including root-cause analysis for any failure.
