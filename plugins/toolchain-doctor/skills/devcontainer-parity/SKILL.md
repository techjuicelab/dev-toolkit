---
name: devcontainer-parity
description: Checks that a project's .devcontainer matches the host dev environment — compares container runtime versions, package manager, forwarded ports, and postCreate setup against the host's .tool-versions and actual usage. Use when a repo has a .devcontainer and you want to catch "works on host but breaks in container" drift.
---

# Devcontainer ↔ host parity check

Catch the drift devcontainers are supposed to prevent: the container pinning different runtime versions, missing port forwards, or a setup step that doesn't match how the project actually builds on the host.

Only run when a `.devcontainer/` (or root `.devcontainer.json`) exists. If there is none, say so and stop.

## Gather

**Container side** — read whichever exist:
- `.devcontainer/devcontainer.json` (or `.devcontainer.json`): `image`/`build.dockerfile`, `features` (esp. `ghcr.io/devcontainers/features/node`, `python`, etc. and their `version`), `forwardPorts`, `postCreateCommand`/`postStartCommand`, `remoteUser`, `containerEnv`.
- `.devcontainer/Dockerfile`: `FROM` base (e.g. `node:22`), any runtime installs.
- `.devcontainer/docker-compose.yml` (if referenced): service ports, volumes, env.

**Host side** — read:
- `./.tool-versions` (asdf pins: node/python/etc.).
- `package.json` `packageManager` field + lockfile (pnpm/yarn/npm/bun).
- App's actual listening port(s): grep for `listen(`, `PORT`, `--port`, framework configs (vite `server.port`, next default 3000, etc.).
- Host setup command(s): the `scripts` in package.json (`dev`/`build`/`start`), Makefile targets.

## Compare and report (OK / DRIFT / MISSING)

1. **Runtime version**: host `.tool-versions` node/python/etc. vs the container's base image tag or devcontainer feature `version`. Flag major-version mismatches (e.g. host `nodejs 24.17.0` ↔ container `node:20` or feature `node:{version:20}`).
2. **Package manager**: host lockfile/`packageManager` vs the container's `postCreateCommand`/Dockerfile install step (e.g. host uses `pnpm install` but container runs `npm install`, or pnpm/bun not installed in the image).
3. **Ports**: app's listening port(s) vs `forwardPorts` — flag any used-but-not-forwarded port.
4. **Setup parity**: does `postCreateCommand` actually install deps the way the host does? Missing `postCreateCommand` when deps are required is a DRIFT.
5. **User/permissions**: `remoteUser` present and matching expectations (e.g. `node`), workspace mount sane.

## Output

```
devcontainer-parity — <project>

✅ OK        node       host 24.17.0  ↔ container node:22  (both Node 22-compatible? NO → see below)
⚠️ DRIFT     node       host nodejs 24.17.0  ↔  container FROM node:20  → bump container to node:22+
⚠️ DRIFT     pkg mgr    host pnpm-lock.yaml  ↔  postCreateCommand "npm install"  → use pnpm in container
❌ MISSING   port       app listens on 5173 (vite) but forwardPorts = [3000]  → add 5173

Suggested edits:
  - .devcontainer/Dockerfile: FROM node:20 → FROM node:22
  - devcontainer.json forwardPorts: add 5173
  - postCreateCommand: "corepack enable && pnpm install"
```

Rules:
- Propose concrete edits; do not apply them unless the user asks.
- A version match is only "OK" if the **major** lines up (node 24 host vs node 22 container is a DRIFT worth flagging unless the project explicitly targets 22).
- If host and container agree on everything, say so in one line.
