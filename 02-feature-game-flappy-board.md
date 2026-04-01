# Flappy Bird Scores & Leaderboard — Database Spec

**Supabase project:** `yfrfgnvamuyvwentgndq` (stylish-engineering-apps)
**Purpose:** Shared game data across multiple apps. Scores and player identities are stored here, independent of any single app's auth system.

---

## Tables

### `game_players`

Cross-app player identity keyed by **email address**.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | Auto-generated |
| `email` | `text` UNIQUE NOT NULL | Cross-app identity key |
| `display_name` | `text` | Player's display name (from OAuth metadata) |
| `avatar_url` | `text` | Avatar URL |
| `created_at` | `timestamptz` | Auto |
| `updated_at` | `timestamptz` | Updated on each upsert |

**RLS:** Open read, open insert, open update (no user-level auth across projects).

---

### `game_flappy_scores`

One row per player — stores the all-time highest score. Updated in place when a new score exceeds the stored one.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | Auto-generated |
| `player_id` | `uuid` FK → `game_players.id` UNIQUE | Cascade delete. One record per player. |
| `app_id` | `text` NOT NULL | App where the best score was achieved (e.g. `'sevendo'`) |
| `higher_score` | `integer` NOT NULL | Player's all-time best score |
| `created_at` | `timestamptz` | Auto |
| `updated_at` | `timestamptz` | Updated whenever a new best score is set |

**Indexes:** `higher_score DESC`, `app_id`
**RLS:** Open read, open insert, open update.

---

## RPC Functions

### `submit_flappy_score`

Upserts the player by email (updating display name and avatar if changed), then inserts or updates the score record. Score is only updated when `p_score` exceeds the stored `higher_score`. Atomic — single call from the client.

**Parameters:**

| Name | Type | Required | Notes |
|---|---|---|---|
| `p_email` | `text` | Yes | Player's email — used as identity key |
| `p_display_name` | `text` | Yes (nullable) | From OAuth `user_metadata.full_name` |
| `p_avatar_url` | `text` | Yes (nullable) | From OAuth `user_metadata.avatar_url` |
| `p_score` | `integer` | Yes | Score for this game session |
| `p_app_id` | `text` | No | Defaults to `'sevendo'` |

**Returns:** `uuid` — the `game_flappy_scores.id` (existing row on update, new row on first insert)

**Example call (Supabase JS):**
```typescript
await supabase.rpc('submit_flappy_score', {
  p_email: 'user@example.com',
  p_display_name: 'Jane Doe',
  p_avatar_url: 'https://...',
  p_score: 42,
  p_app_id: 'my-app-name'
});
```

---

### `get_flappy_leaderboard`

Returns the top 10 players ordered by `higher_score`. Pass `p_app_id` to filter to players whose best score was achieved on that app, or omit for a global cross-app leaderboard.

**Parameters:**

| Name | Type | Required | Notes |
|---|---|---|---|
| `p_app_id` | `text` | No | Filter by app. `NULL` = global leaderboard |

**Returns:**

| Column | Type | Notes |
|---|---|---|
| `rank` | `bigint` | 1–10 |
| `player_id` | `uuid` | Internal player UUID |
| `display_name` | `text` | Player's name |
| `avatar_url` | `text` | Player's avatar |
| `best_score` | `integer` | Player's highest score ever (within app scope) |

**Example call:**
```typescript
// App-scoped leaderboard
const { data } = await supabase.rpc('get_flappy_leaderboard', {
  p_app_id: 'my-app-name'
});

// Global leaderboard (all apps)
const { data } = await supabase.rpc('get_flappy_leaderboard');
```

---

### `get_flappy_user_rank`

Returns the current player's rank and personal best. Uses an efficient index-scan approach (counts players with a higher score) rather than ranking the full table.

**Parameters:**

| Name | Type | Required | Notes |
|---|---|---|---|
| `p_email` | `text` | Yes | Player's email |
| `p_app_id` | `text` | No | Filter by app. `NULL` = global rank |

**Returns:**

| Column | Type | Notes |
|---|---|---|
| `rank` | `bigint` | Player's rank (1 = best) |
| `best_score` | `integer` | Player's personal best |

Returns **no rows** (empty result) if the player has not submitted any scores yet.

**Example call:**
```typescript
const { data } = await supabase.rpc('get_flappy_user_rank', {
  p_email: 'user@example.com',
  p_app_id: 'my-app-name'
});
// data[0]?.rank, data[0]?.best_score
```

---

## Integration Notes

- **Authentication:** This project uses the **anon key only**. There is no user-level auth — callers are trusted at the app level. RLS policies are open for read/insert/update.
- **Identity:** The player's email is the cross-app identity. The same email from Google login will resolve to the same `game_players` row regardless of which app submits the score.
- **Apple Sign-In edge case:** Users who chose "hide my email" on Apple get a per-app relay address (e.g. `xyz@privaterelay.appleid.com`). Their identity will be separate per app on this leaderboard.
- **Score storage:** One record per player. `higher_score` is only updated when the new score exceeds it. `app_id` is updated to reflect the app where the best score was achieved.
- **`app_id` values:** Use a consistent lowercase string per app (e.g. `'sevendo'`, `'my-other-app'`). The leaderboard can be scoped by this value.
