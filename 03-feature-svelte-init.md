# Feature: SvelteKit Init + Cloudflare Deployment

Scaffold the SvelteKit 5 project, build a basic landing page, and configure Cloudflare Pages to auto-deploy to `stylishengineering.com` on every push to `release-website`.

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

## Part 1 — SvelteKit Project Setup

### 1. ✅ Scaffold SvelteKit with Svelte 5

Run inside the repo root (the `.` targets the current directory):

```bash
pnpm create svelte@latest . \
  --template skeleton \
  --types typescript \
  --no-prettier \
  --no-eslint
```

Accept overwrite prompts. This creates `package.json`, `svelte.config.js`, `vite.config.ts`, `src/`, and `src/routes/`.

---

### 2. ✅ Install dependencies

```bash
pnpm install
```

---

### 3. ✅ Install Tailwind CSS

```bash
pnpm add -D tailwindcss @tailwindcss/vite
```

---

### 4. ✅ Configure Tailwind in `vite.config.ts`

Update `vite.config.ts`:

```typescript
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()]
});
```

---

### 5. ✅ Create global CSS with Tailwind import

Create `src/app.css`:

```css
@import "tailwindcss";
```

---

### 6. ✅ Create root layout importing global CSS

Create `src/routes/+layout.svelte`:

```svelte
<script>
  import '../app.css';
  let { children } = $props();
</script>

{@render children()}
```

---

### 7. ✅ Build the landing page

Create `src/routes/+page.svelte` with the following sections:

- **Hero** — company name, logo (`static/stylish-engineering-logo.png`), tagline
- **About** — brief company description (functionality + style, inspired by Teenage Engineering values)
- **Apps** — showcase cards for SevenDo, Saber Investir, DoughIt (each with name, description, "Coming Soon" badge since URLs aren't available yet)
- **Footer** — company name + copyright

Use Svelte 5 syntax throughout (`$props()`, `$state()` if needed). No Svelte 4 patterns.

---

### 8. ✅ Install Supabase JS client

```bash
pnpm add @supabase/supabase-js
```

---

### 9. ✅ Create the Supabase game client

Create `src/lib/supabase/game.ts`:

```typescript
import { createClient } from '@supabase/supabase-js';
import {
  PUBLIC_GAME_SUPABASE_URL,
  PUBLIC_GAME_SUPABASE_ANON_KEY
} from '$env/static/public';

export const gameSupabase = createClient(
  PUBLIC_GAME_SUPABASE_URL,
  PUBLIC_GAME_SUPABASE_ANON_KEY
);
```

---

### 10. ⬜ Verify dev server runs

```bash
pnpm dev
```

Visit `http://localhost:5173` and confirm the landing page renders correctly.

---

## Part 2 — Cloudflare Pages Configuration

### 11. ✅ Install the Cloudflare adapter

```bash
pnpm add -D @sveltejs/adapter-cloudflare
```

---

### 12. ✅ Update `svelte.config.js` to use the Cloudflare adapter

```javascript
import adapter from '@sveltejs/adapter-cloudflare';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter()
  }
};

export default config;
```

---

### 13. ✅ Add `package.json` build script sanity check

Confirm the `build` script in `package.json` is:

```json
"build": "vite build"
```

Cloudflare Pages will call this to produce the `.svelte-kit/cloudflare` output directory.

---

### 14. ✅ Create `wrangler.toml`

Create `wrangler.toml` at the repo root to declare the Pages project name:

```toml
name = "stylish-engineering"
compatibility_date = "2024-01-01"
pages_build_output_dir = ".svelte-kit/cloudflare"
```

---

### 15. ✋ ⬜ Create a Cloudflare Pages project

In the **Cloudflare Dashboard**:

1. Go to **Workers & Pages → Create → Pages → Connect to Git**
2. Select the GitHub repo for this project
3. Set these build settings:
   - **Framework preset:** SvelteKit
   - **Build command:** `pnpm build`
   - **Build output directory:** `.svelte-kit/cloudflare`
   - **Root directory:** `/` (repo root)
4. Add environment variables (under **Settings → Environment variables**):
   ```
   PUBLIC_GAME_SUPABASE_URL = https://yfrfgnvamuyvwentgndq.supabase.co
   PUBLIC_GAME_SUPABASE_ANON_KEY = <anon_key>
   ```
   Add these for both **Production** and **Preview** environments.
5. Click **Save and Deploy**

---

### 16. ✋ ⬜ Configure `release-website` as the production branch

By default Cloudflare Pages deploys from `main`. Change this:

1. In the Cloudflare Pages project → **Settings → Builds & deployments**
2. Under **Production branch**, change it to: `release-website`
3. Optionally disable or ignore the `main` branch under **Preview branches** if you don't want preview deployments from it

> From this point on, every `git push origin release-website` triggers an automatic production deployment.

---

### 17. ✋ ⬜ Connect custom domain `stylishengineering.com`

1. In Cloudflare Pages project → **Custom domains → Set up a custom domain**
2. Enter `stylishengineering.com`
3. If the domain's DNS is already managed by Cloudflare, the DNS record will be added automatically
4. If not, add a `CNAME` record at your DNS registrar:
   ```
   CNAME  @  <your-pages-project>.pages.dev
   ```
5. Wait for SSL to provision (usually < 5 minutes when DNS is on Cloudflare)
6. Repeat for `www.stylishengineering.com` if you want the `www` subdomain to redirect

---

### 18. ✅ Create the `release-website` branch

```bash
git checkout -b release-website
git push origin release-website
```

This creates the branch Cloudflare will watch. Future deployments are triggered by pushing to it.

---

### 19. ✋ ⬜ Verify end-to-end deployment

1. Make a trivial change (e.g. update the tagline in `+page.svelte`)
2. Commit and push to `release-website`:
   ```bash
   git add .
   git commit -m "chore: verify deployment pipeline"
   git push origin release-website
   ```
3. In Cloudflare Dashboard → **Workers & Pages → your project → Deployments**, confirm a new deployment starts automatically
4. Once complete, visit `https://stylishengineering.com` and confirm the live site is updated

---

## Deployment Workflow Summary

```
local changes
     │
     ▼
git push origin release-website
     │
     ▼
Cloudflare Pages detects push
     │
     ▼
runs: pnpm build
     │
     ▼
deploys .svelte-kit/cloudflare → stylishengineering.com
```

---

## Notes

- **`main` branch** is for development. Never deploy from it directly.
- **`release-website` branch** is the production gate. Merge or cherry-pick into it when ready to ship.
- Cloudflare Pages injects environment variables at build time — no `.env.local` is needed in CI.
- The Cloudflare adapter automatically handles SSR via Cloudflare Workers under the hood. No extra Worker configuration is needed.
- If you later add a `www` redirect, do it via a Cloudflare **Redirect Rule** (Dashboard → Rules → Redirect Rules), not in SvelteKit.
