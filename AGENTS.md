# ansible-role-checkpoint-waf-yandex-cloud

This is an Ansible role (`checkpoint_waf_agent`) that installs and registers Check Point
CloudGuard AppSec (WAF) as a rootless Docker Compose service on Ubuntu/Debian hosts, with
Yandex Cloud integration (Container Registry, Certificate Manager). It supports single-agent
and multi-agent deployment modes.

## Project rules and context

Detailed project standards and product context live in these files. Treat them as mandatory
project instructions (they are also loaded automatically via the `instructions` field in
`opencode.json`):

- `.opencode/steering/steering.md` — coding rules, structure, variable naming, Docker,
  security, testing, linting, git/CI conventions.
- `.opencode/steering/product.md` — product description, use cases, architecture, security
  model, supported platforms, integration points.

## Agents

Custom agents are defined in `.opencode/agents/`:

- **devops-team-lead** (primary) — product expert and orchestrator for Check Point CloudGuard
  WAF. Owns architecture decisions and delegates work to the sub-agents. Read-only on files.
- **ansible-specialist** (subagent) — writes, reviews, and refactors role code (tasks,
  handlers, templates, defaults, vars, meta, files). Delegates testing to `diffusion_tester`.
- **diffusion_tester** (subagent) — runs and troubleshoots Molecule/Diffusion test scenarios
  using the `diffusion` MCP server. Read-only on role source except `defaults/*`, `vars/*`,
  and `diffusion.toml`.

## Skills

- **tester** (`.opencode/skills/tester/SKILL.md`) — testing, dependency management, and
  Diffusion workflow guidelines. Load it via the skill tool when running tests, managing
  dependencies, or updating Diffusion variables.

## MCP servers

- **diffusion** — defined in `opencode.json` under `mcp`. Provides Diffusion/Molecule test
  execution and diagnostics tools. Disabled globally and enabled only for the
  `diffusion_tester` agent to keep it scoped.

## Automated workflow (was a Kiro hook)

Kiro previously ran a "Diffusion Lock Change Pipeline" hook that fired whenever `diffusion.lock`
was saved. OpenCode does not have an equivalent file-save agent hook, so it is exposed as the
`/lock-change-pipeline` command (`.opencode/command/lock-change-pipeline.md`, runs on the
`diffusion_tester` agent). Run it manually (or wire the steps into CI / a git hook) after
`diffusion.lock` changes:

1. Run `diffusion deps check`.
2. If the lock file is out of date / a sync is required, run `diffusion deps sync`, then
   re-run `diffusion deps check` to confirm it is in sync.
3. Once in sync, run the full Molecule test pipeline in order, stopping and reporting on any
   failure:
   1. `diffusion molecule --force` (force reinstall deps + converge)
   2. `diffusion molecule --lint` (yamllint + ansible-lint)
   3. `diffusion molecule --verify` (verification tests)
   4. `diffusion molecule --idempotence` (idempotence check)
4. Report the result of each step clearly.

## Key commands

- Tests: `diffusion molecule --converge`, `--verify`, `--idempotence`, `--lint`. Multi-agent
  scenario: add `--scenario multi`.
- Dependencies: manage collections/roles via the Diffusion CLI (`diffusion role add-collection`,
  etc.), then `diffusion deps sync` and `diffusion deps check`. Never hand-edit
  `scenarios/*/requirements.yml`, `meta/main.yml`, or `diffusion.lock`.
