# Spec: Flappy Do — Supabase RPC Reference

**Supabase project:** `yfrfgnvamuyvwentgndq`  
**Base URL:** `https://yfrfgnvamuyvwentgndq.supabase.co`  
**Auth:** anon key only — no user authentication required  
**Last updated:** 2026-04-02

This file is the authoritative reference for all RPCs exposed by the shared Flappy Do game backend. Feed this file to any AI assistant working on a client app that calls these RPCs to determine if the client integration is up to date.

---

## How to call from a client app

```typescript
import { createClient } from '@supabase/supabase-js';

const gameSupabase = createClient(
  'https://yfrfgnvamuyvwentgndq.supabase.co',
  '<ANON_KEY>'
);

const { data, error } = await gameSupabase.rpc('rpc_name', { param: value });
```

---

## `app_id` convention

Each client app identifies itself with a lowercase string `app_id`:

| App | `app_id` |
|-----|----------|
| SevenDo | `'sevendo'` |
| DoughIt | `'doughit'` |
| Saber Investir | `'saberinvestir'` |

---

## Score month convention

Scores are grouped by month. `score_month` values are always the **first day of the month** as a `date` (e.g. `2026-04-01` for April 2026). The server computes this automatically — clients never supply it.

Past months are frozen. Clients should cache completed months in local storage and only fetch live data for the current month.

---

## RPCs

### `submit_flappy_score`

Call this when a game session ends to record the player's score.

**When to call:** Once per game session, on game over.

**Input parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `p_email` | `text` | yes | — | Player's email address (cross-app identity key) |
| `p_display_name` | `text` | yes | — | Display name shown on leaderboard |
| `p_avatar_url` | `text` | yes | — | Avatar image URL (pass `null` if none) |
| `p_score` | `integer` | yes | — | Score achieved in this session |
| `p_app_id` | `text` | no | `'sevendo'` | Identifying string for the calling app |

**Returns:** `uuid` — the `game_flappy_scores` record id

**Behaviour:**
- Upserts the player by email (creates if new, updates `display_name` and `avatar_url` if changed)
- Records the score for the current month only — `score_month` is computed server-side and cannot be influenced by the caller
- Only updates the stored monthly best if `p_score` exceeds it; lower scores are silently ignored
- One atomic operation — safe to call without transactions

**Example:**
```typescript
const { data, error } = await gameSupabase.rpc('submit_flappy_score', {
  p_email: 'player@example.com',
  p_display_name: 'Josh',
  p_avatar_url: null,
  p_score: 42,
  p_app_id: 'doughit'
});
// data: "3f7a1b2c-..."  (uuid)
```

---

### `get_flappy_leaderboard`

Top 10 players for a given month.

**When to call:**
- Current month: call as needed (live data)
- Past months: call once and cache in local storage (data never changes)

**Input parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `p_app_id` | `text` | no | `null` | Filter by app. Pass `null` or omit for cross-app global leaderboard |
| `p_month` | `date` | no | first day of current month | Month to query. Format: `'YYYY-MM-01'` |

**Returns:** array of rows

| Column | Type | Description |
|--------|------|-------------|
| `rank` | `bigint` | Position (1 = highest score) |
| `player_id` | `uuid` | Player's internal id |
| `display_name` | `text` | Player's display name |
| `avatar_url` | `text` | Player's avatar URL (may be null) |
| `best_score` | `integer` | Player's best score for the month |

**Example:**
```typescript
// Current month, current app
const { data } = await gameSupabase.rpc('get_flappy_leaderboard', {
  p_app_id: 'doughit'
});

// Specific past month, global
const { data } = await gameSupabase.rpc('get_flappy_leaderboard', {
  p_month: '2026-03-01'
});

// data: [
//   { rank: 1, player_id: "...", display_name: "Josh", avatar_url: null, best_score: 98 },
//   { rank: 2, player_id: "...", display_name: "Ana",  avatar_url: "...", best_score: 76 },
//   ...
// ]
```

---

### `get_flappy_user_rank`

A single player's rank and best score for a given month.

**When to call:**
- Current month: call as needed (live data)
- Past months: prefer `get_flappy_user_monthly_history` and cache locally

**Input parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `p_email` | `text` | yes | — | Player's email address |
| `p_app_id` | `text` | no | `null` | Filter by app. Pass `null` or omit for global rank |
| `p_month` | `date` | no | first day of current month | Month to query. Format: `'YYYY-MM-01'` |

**Returns:** single row, or empty if the player has no score for that month

| Column | Type | Description |
|--------|------|-------------|
| `rank` | `bigint` | Player's position for the month |
| `best_score` | `integer` | Player's best score for the month |

**Example:**
```typescript
// Current month rank
const { data } = await gameSupabase.rpc('get_flappy_user_rank', {
  p_email: 'player@example.com',
  p_app_id: 'doughit'
});

// data: [{ rank: 3, best_score: 88 }]
// empty array if player hasn't played this month
```

---

### `get_flappy_user_monthly_history`

All months a player has participated in, with their best score and rank per month.

**When to call:** Once when the month rolls over. Cache the full response in local storage — completed months never change. Only the current month's entry (if present) can still update.

**Input parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `p_email` | `text` | yes | — | Player's email address |
| `p_app_id` | `text` | no | `null` | Filter by app. Pass `null` or omit for global history |

**Returns:** array of rows, ordered by `score_month DESC` (most recent first)

| Column | Type | Description |
|--------|------|-------------|
| `score_month` | `date` | First day of the month (e.g. `2026-04-01`) |
| `best_score` | `integer` | Player's best score for that month |
| `rank` | `bigint` | Player's rank for that month |

**Example:**
```typescript
const { data } = await gameSupabase.rpc('get_flappy_user_monthly_history', {
  p_email: 'player@example.com',
  p_app_id: 'doughit'
});

// data: [
//   { score_month: "2026-04-01", best_score: 98, rank: 1 },
//   { score_month: "2026-03-01", best_score: 71, rank: 4 },
//   { score_month: "2026-02-01", best_score: 55, rank: 7 },
// ]
// empty array if player has never played
```
