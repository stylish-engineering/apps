# Feature: Supabase Init

Configure the Supabase CLI and environment in this repo so migrations can be pushed to the `yfrfgnvamuyvwentgndq` project with a single npm script.

---

## Legend

| Symbol | Status |
|--------|--------|
| ⬜ | Not Started |
| 🔄 | In Progress |
| ✅ | Completed |
| ✋ ⬜ | **Manual Task — To Do** — Requires human intervention |
| ✋ ✅ | **Manual Task — Done** — Human step completed |

---

## Steps

### 1. ⬜ SvelteKit scaffold
Bootstrap the SvelteKit project in the repo root so `package.json` exists before adding scripts.

```bash
pnpm create svelte@latest . --template skeleton --types typescript --no-prettier --no-eslint
pnpm install
```

---

### 2. ⬜ Install Supabase CLI as a dev dependency

Add the Supabase CLI so it is reproducible across machines without a global install.

```bash
pnpm add -D supabase
```

---

### 3. ⬜ Add `db:push` script to `package.json`

Add the following to the `scripts` section of `package.json`:

```json
"db:push": "supabase db push --project-ref yfrfgnvamuyvwentgndq"
```

Usage after setup:
```bash
pnpm db:push
```

---

### 4. ⬜ Create `.env.local` with Supabase credentials

Create `.env.local` in the repo root (never committed):

```env
PUBLIC_GAME_SUPABASE_URL=https://yfrfgnvamuyvwentgndq.supabase.co
PUBLIC_GAME_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmcmZnbnZhbXV5dndlbnRnbmRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwNDk1MTMsImV4cCI6MjA5MDYyNTUxM30.gmjdis7znUUday_rku_Hf7aGRCi9fjTWipMWfjp6tz4
SUPABASE_ACCESS_TOKEN=<your_supabase_personal_access_token>
```

> `SUPABASE_ACCESS_TOKEN` is required by the CLI to authenticate `db:push`. Get it from: **Supabase Dashboard → Account → Access Tokens**.

---

### 5. ⬜ Create `.env.example` as a committed reference

Create `.env.example` in the repo root with placeholder values (safe to commit):

```env
PUBLIC_GAME_SUPABASE_URL=https://<project-ref>.supabase.co
PUBLIC_GAME_SUPABASE_ANON_KEY=<anon_key>
SUPABASE_ACCESS_TOKEN=<supabase_personal_access_token>
```

---

### 6. ⬜ Create `.gitignore` and add `.env.local`

Create `.gitignore` at the repo root. At minimum:

```
# Environment — never commit real credentials
.env.local
.env.*.local

# SvelteKit
.svelte-kit/
build/

# Dependencies
node_modules/

# Cloudflare
.wrangler/
```

---

### 7. ✋ ⬜ Authenticate the Supabase CLI locally

The CLI needs a personal access token to push migrations. Run once per machine:

```bash
# Option A — set via env var (picked up automatically from .env.local if using dotenv)
export SUPABASE_ACCESS_TOKEN=<your_token>

# Option B — interactive login
pnpm supabase login
```

> Get your token at: **supabase.com → Dashboard → Account → Access Tokens → Generate new token**

---

### 8. ✋ ⬜ Apply the initial migration to the Supabase project

Push the migration in `supabase/migrations/` to the hosted project:

```bash
pnpm db:push
```

Verify in the **Supabase Dashboard → Table Editor** that `game_players` and `game_flappy_scores` tables exist, and in **Database → Functions** that the three RPC functions are present.

---

## Notes

- `supabase/migrations/` already contains the initial schema: `20260401000000_game_schema.sql`
- `SUPABASE_ACCESS_TOKEN` must be set in the shell environment (or `.env.local` loaded before running `db:push`) — the CLI does not read `.env.local` automatically. Use `dotenv-cli` if you want automatic loading:
  ```bash
  pnpm add -D dotenv-cli
  # then update the script:
  "db:push": "dotenv -e .env.local -- supabase db push --project-ref yfrfgnvamuyvwentgndq"
  ```
