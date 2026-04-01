## Project Configuration

- **Language**: TypeScript
- **Package Manager**: npm
- **Add-ons**: none

---

# CLAUDE.md — Stylish Engineering Website

## Project Overview

SvelteKit + Svelte 5 company website for Stylish Engineering, deployed to Cloudflare Pages. It serves two purposes:
1. Public company website showcasing products (no auth)
2. Shared Supabase backend for cross-app game features (leaderboards, easter eggs)

---

## Tech Stack

- **Framework:** SvelteKit with Svelte 5
- **Language:** TypeScript (strict)
- **Styling:** Tailwind CSS
- **Backend:** Supabase (game project: `yfrfgnvamuyvwentgndq`)
- **Deployment:** Cloudflare Pages — auto-deploys on push to `release-website` branch
- **Domain:** stylishengineering.com

---

## Critical Rules

- **Always use Svelte 5 syntax.** Never use Svelte 4 patterns.
  - Use runes: `$state`, `$derived`, `$effect`, `$props`, `$bindable`
  - Use `{#each}`, `{#if}`, `{#await}` blocks as normal but with Svelte 5 event syntax (`onclick` not `on:click`)
  - Component props use `let { foo } = $props()` — never `export let`
  - Avoid `createEventDispatcher` — use callback props instead
- **TypeScript everywhere.** No `any` unless truly unavoidable.
- **No authentication on this site.** The Supabase project uses only the anon key. Do not add user auth flows.

---

## Architecture

### Supabase Client

There is one Supabase client for the game backend. Initialize it with the public env vars:

```typescript
// src/lib/supabase/game.ts
import { createClient } from '@supabase/supabase-js';
import { PUBLIC_GAME_SUPABASE_URL, PUBLIC_GAME_SUPABASE_ANON_KEY } from '$env/static/public';

export const gameSupabase = createClient(PUBLIC_GAME_SUPABASE_URL, PUBLIC_GAME_SUPABASE_ANON_KEY);
```

### Environment Variables

All public — prefix with `PUBLIC_` so SvelteKit exposes them to the client:

```
PUBLIC_GAME_SUPABASE_URL
PUBLIC_GAME_SUPABASE_ANON_KEY
```

Import with `$env/static/public`, never from `$env/dynamic/public` unless SSR-dynamic values are needed.

### Routes

```
src/routes/
├── +layout.svelte       # Root layout
├── +page.svelte         # Homepage (company intro + app showcase)
└── api/                 # SvelteKit server routes if needed
```

### Shared Game Backend

Tables and RPCs live in the Supabase project `yfrfgnvamuyvwentgndq`. Key objects:

| Object | Type | Purpose |
|---|---|---|
| `game_players` | Table | Cross-app player identity (keyed by email) |
| `game_flappy_scores` | Table | Per-session scores; `app_id` distinguishes which app submitted |
| `submit_flappy_score` | RPC | Upsert player + insert score atomically |
| `get_flappy_leaderboard` | RPC | Top 10 by personal best; pass `p_app_id` or omit for global |
| `get_flappy_user_rank` | RPC | Player's rank + best score by email |

Migration files are in `supabase/migrations/`. Apply via Supabase dashboard SQL editor.

**`app_id` convention:** lowercase string identifying the submitting app, e.g. `'sevendo'`, `'doughit'`.

---

## Database Migrations

- Store all migrations in `supabase/migrations/` with the naming convention `YYYYMMDDHHMMSS_description.sql`
- The initial schema is in the first migration file (ported from `temp-supabase-migration.txt`)
- Apply manually via the Supabase dashboard — there is no local Supabase CLI setup required

---

## Deployment

Cloudflare Pages is configured to watch the `release-website` branch. Merging or pushing to it triggers an automatic build and deploy to stylishengineering.com.

Build command: `pnpm build`  
Output directory: `.svelte-kit/cloudflare` (adapter-cloudflare)

---

## Apps Showcased

These are external products — only present them on the website, do not implement their logic here.

| App | Description | Website |
|---|---|---|
| SevenDo | Weekly planner TO DO app | Coming soon |
| Saber Investir | Personal finance + investment simulator with real stock data | Coming soon |
| DoughIt | Pizza dough recipe calculator and step-by-step guide | Coming soon |

---

## File Conventions

- Components: `src/lib/components/ComponentName.svelte` (PascalCase)
- Utilities: `src/lib/utils/descriptiveName.ts` (camelCase)
- Supabase clients: `src/lib/supabase/*.ts`
- Types: `src/lib/types/*.ts`
- Static assets: `static/` (logo is at `static/stylish-engineering-logo.png`)
