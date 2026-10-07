# CLAUDE.md — stylish-engineering/apps

Public repo for the Stylish Engineering brand. Three things live here:

| Path | What | Status |
|---|---|---|
| `docs/` | Public pages: landing page, plus privacy-policy and support pages for each app | **Live** on GitHub Pages at https://stylish-engineering.github.io/apps/. Every push to `main` publishes it |
| `src/`, `static/` | Brand website (SvelteKit) | Not deployed yet |
| `supabase/` | Game backend shared by the apps (leaderboards) | Live. Supabase project `yfrfgnvamuyvwentgndq` |

This repo is public. Never commit secrets or private details.

## docs/

- App Store and Google Play listings link to these URLs. Never rename, move or delete a published path (`docs/sevenDo/…`, `docs/giosPizzaChef/…`). Change content in place.
- The text of each app's privacy and support pages is owned by that app's repo and mirrored here. Change it there first.
- Plain static HTML, no build step.

## Website

- Svelte 5 only: runes (`$state`, `$derived`, `$effect`, `$props`, `$bindable`), `onclick` not `on:click`, `let { foo } = $props()` not `export let`, callback props not `createEventDispatcher`.
- TypeScript strict, no `any` unless unavoidable. Tailwind CSS v4.
- No authentication. Only the Supabase anon key, through `src/lib/supabase/game.ts`. Env vars `PUBLIC_GAME_SUPABASE_URL` and `PUBLIC_GAME_SUPABASE_ANON_KEY`, imported from `$env/static/public`.
- Commands (npm): `npm run dev`, `npm run check`, `npm run build`.
- Deployment is not set up. The code is ready for Cloudflare Pages (`adapter-cloudflare`, `wrangler.toml`, build command `npm run build`, output `.svelte-kit/cloudflare`). Still to do by hand: create the Pages project with the two `PUBLIC_GAME_SUPABASE_*` variables, choose the production branch, connect `stylishengineering.com`.
- Files: components `src/lib/components/Name.svelte`, utilities `src/lib/utils/name.ts`, types `src/lib/types/*.ts`, assets `static/`.

## Shared game backend

- `supabase/README.md` is the RPC reference client apps code against. Update it in the same change as any migration.
- Migrations: `supabase/migrations/YYYYMMDDHHMMSS_description.sql`. Never edit an applied one; add a new one.
- `npm run supabase-push` applies them to the production database. It needs `SUPABASE_ACCESS_TOKEN` exported in the shell (the CLI does not read `.env.local`), or `npx supabase login` once. Ask before running it.
- `app_id` is a lowercase string per client app, for example `'sevendo'`, `'doughit'`.
