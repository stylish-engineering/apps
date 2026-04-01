# Stylish Engineering — Company Website

The official website for **Stylish Engineering**, a software development and design company focused on delivering apps and products that combine functionality with style. We believe a good solution isn't just functional — it should be elegant, enjoyable, and worth using.

> Inspired by the values of companies like Teenage Engineering.

Live at: [stylishengineering.com](https://stylishengineering.com)

---

## What this repo contains

### 1. Company Website
A public-facing site presenting Stylish Engineering and its products — no authentication required.

**Apps showcased:**
- **SevenDo** — A weekly planner TO DO app *(website coming soon)*
- **Saber Investir** — Personal finance app with an investment simulator using real stock data *(website coming soon)*
- **DoughIt** — Pizza dough recipe calculator and step-by-step guide *(website coming soon)*

### 2. Shared Game Backend
A shared Supabase backend for cross-app game features (easter egg mini-games like Flappy Bird). Scores and player identities are stored independently of any single app, so the same leaderboard is shared across all apps hosting the game.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | SvelteKit + Svelte 5 |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Backend | Supabase (game project) |
| Hosting | Cloudflare Pages |
| Domain | stylishengineering.com |

---

## Local Development

### Prerequisites
- Node.js 20+
- pnpm (or npm)

### Setup

```bash
# Install dependencies
pnpm install

# Create your local environment file
cp .env.example .env.local
# Fill in the Supabase env vars (see Environment Variables below)

# Start the dev server
pnpm dev
```

### Environment Variables

```env
PUBLIC_GAME_SUPABASE_URL=https://yfrfgnvamuyvwentgndq.supabase.co
PUBLIC_GAME_SUPABASE_ANON_KEY=<anon_key>
```

---

## Database Setup

The Supabase schema for the shared game backend is versioned in `supabase/migrations/`. To apply it manually, run the migration SQL via the [Supabase dashboard SQL editor](https://supabase.com/dashboard/project/yfrfgnvamuyvwentgndq/sql).

The schema creates:
- `game_players` — cross-app player identity keyed by email
- `game_flappy_scores` — per-session scores with `app_id` to distinguish which app submitted them
- RPC functions: `submit_flappy_score`, `get_flappy_leaderboard`, `get_flappy_user_rank`

---

## Deployment

Deployments are triggered automatically by Cloudflare Pages.

To deploy a new version of the website, push or merge to the **`release-website`** branch:

```bash
git push origin release-website
```

Cloudflare Pages will detect the push and build + deploy the site automatically.

---

## Project Structure

```
apps/
├── src/
│   ├── lib/           # Shared components, utilities, Supabase client
│   └── routes/        # SvelteKit routes
├── static/            # Static assets (logo, images)
├── supabase/
│   └── migrations/    # SQL migration files
└── docs/              # Design docs and feature specs
```
