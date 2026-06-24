---
name: op-secrets
description: The 1Password (op CLI) workflow for handling secrets, API keys, tokens, and .env files. Use whenever creating/editing environment variables, .env files, CI secrets, or wiring an app to credentials. Always reference secrets as op:// and inject at runtime — never write plaintext secret values to disk.
---

# 1Password secrets workflow (op://)

This project manages secrets with the **1Password CLI (`op`)**. The rule is simple: **secret *references* live in files; secret *values* never do.** Real values stay in 1Password and are injected at runtime.

## Core rule

- ✅ Files (`.env`, configs, CI) contain `op://vault/item/field` references.
- ✅ The app runs with values injected: `op run --env-file=.env -- <command>`.
- ❌ Never write a real key/token/password into a file or a shell command.
- ❌ Never `echo`/`cat` a real secret, and never paste one into a commit.

The companion **secret-guard** hook enforces this by blocking writes/commands that contain high-confidence plaintext secrets.

## The `op://` reference format

```
op://<vault>/<item>/<field>
# examples
op://Dev/OpenAI/api_key
op://Dev/Postgres/connection_string
op://AI Automation/Notion/api_token
```

## Scaffolding a project's `.env`

Write `.env` (or `.env.example`, committed) with **references**, not values:

```dotenv
# .env  — references only; resolved at runtime by `op run`
OPENAI_API_KEY=op://Dev/OpenAI/api_key
DATABASE_URL=op://Dev/Postgres/connection_string
GITHUB_TOKEN=op://Dev/GitHub/token
```

Ensure `.env` is gitignored when it could ever hold real values:

```bash
grep -qxF '.env' .gitignore 2>/dev/null || echo '.env' >> .gitignore
```

## Running with secrets injected

```bash
# Inject all op:// refs from .env into the process environment, run the command:
op run --env-file=.env -- pnpm dev
op run --env-file=.env -- python main.py
op run --env-file=.env -- docker compose up

# Add this as a package.json script / Makefile target so it's the default path:
#   "dev": "op run --env-file=.env -- vite"
```

## One-off materialization (only when a tool truly needs a real file)

```bash
# .env.tpl holds op:// refs (safe to commit); .env gets real values (gitignored).
op inject -i .env.tpl -o .env
# ...use it, then remove it:
rm -f .env
```

## Reading a single secret

```bash
op read "op://Dev/OpenAI/api_key"                 # prints the value (use sparingly)
export STRIPE_KEY="$(op read 'op://Dev/Stripe/secret')"   # ephemeral, not written to disk
```

## When the user gives you a real secret

If the user pastes a real secret and asks you to "put it in the config":
1. **Do not** write the value. Instead, tell them to store it in 1Password (or store it via `op item create`/`op item edit` if they want you to), then
2. Write only the `op://` reference into the file, and
3. Show the `op run` command to use it.

## Notes

- First use in a session may prompt 1Password Touch ID / `op signin`.
- For service accounts / CI, use `OP_SERVICE_ACCOUNT_TOKEN` (itself provided via the platform's secret store, never committed).
- This skill pairs with **secret-guard** (the hook): this skill teaches the correct pattern; the hook blocks the wrong one.
