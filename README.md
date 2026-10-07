# Stylish Engineering — apps

Public home of Stylish Engineering.

- **`docs/`** — the public pages served at https://stylish-engineering.github.io/apps/: the landing page, plus privacy-policy and support pages for each app. GitHub Pages publishes it on every push to `main`.
- **`src/`, `static/`** — the brand website (SvelteKit, Tailwind CSS). Not deployed yet.
- **`supabase/`** — schema and RPC reference for the game backend shared by the apps. See [`supabase/README.md`](supabase/README.md).

## Website development

```sh
npm install
npm run dev      # dev server
npm run check    # type check
npm run build    # production build
```

Copy `.env.example` to `.env.local` and fill in the values first.
