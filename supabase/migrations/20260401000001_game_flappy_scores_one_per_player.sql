-- ============================================================
-- Migrate game_flappy_scores to one record per player.
--
-- Previously: one row per game session (full history).
-- Now: one row per player storing their all-time best score.
--
-- Steps:
--   1. Collapse existing rows to one per player (keep highest score)
--   2. Add updated_at column
--   3. Add UNIQUE constraint on player_id
--   4. Drop the now-redundant player_id index
--   5. Add update RLS policy
--   6. Replace submit_flappy_score to upsert instead of insert
--   7. Simplify leaderboard and rank functions
-- ============================================================

-- 1. Delete all but the best score row per player
DELETE FROM game_flappy_scores
WHERE id NOT IN (
    SELECT DISTINCT ON (player_id) id
    FROM game_flappy_scores
    ORDER BY player_id, higher_score DESC
);

-- 2. Add updated_at
ALTER TABLE game_flappy_scores
    ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

-- 3. Enforce one record per player
ALTER TABLE game_flappy_scores
    ADD CONSTRAINT game_flappy_scores_player_id_key UNIQUE (player_id);

-- 4. Drop the index made redundant by the unique constraint
DROP INDEX IF EXISTS idx_gfs_player_id;

-- 5. Allow updates (needed for ON CONFLICT DO UPDATE)
CREATE POLICY "Public update scores"
    ON game_flappy_scores FOR UPDATE TO anon, authenticated USING (true);

-- 6. submit_flappy_score: upsert player + insert-or-update best score atomically
CREATE OR REPLACE FUNCTION submit_flappy_score(
    p_email        text,
    p_display_name text,
    p_avatar_url   text,
    p_score        integer,
    p_app_id       text DEFAULT 'sevendo'
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_player_id uuid;
    v_record_id uuid;
BEGIN
    -- Upsert player identity
    INSERT INTO game_players (email, display_name, avatar_url)
    VALUES (p_email, p_display_name, p_avatar_url)
    ON CONFLICT (email) DO UPDATE
        SET display_name = EXCLUDED.display_name,
            avatar_url   = EXCLUDED.avatar_url,
            updated_at   = now()
    RETURNING id INTO v_player_id;

    -- Insert first score, or update only if the new score is higher
    INSERT INTO game_flappy_scores (player_id, app_id, higher_score)
    VALUES (v_player_id, p_app_id, p_score)
    ON CONFLICT (player_id) DO UPDATE
        SET higher_score = GREATEST(game_flappy_scores.higher_score, EXCLUDED.higher_score),
            app_id       = CASE
                               WHEN EXCLUDED.higher_score > game_flappy_scores.higher_score
                               THEN EXCLUDED.app_id
                               ELSE game_flappy_scores.app_id
                           END,
            updated_at   = now()
    RETURNING id INTO v_record_id;

    RETURN v_record_id;
END;
$$;

-- 7a. Simplified leaderboard — one row per player, no DISTINCT ON needed
CREATE OR REPLACE FUNCTION get_flappy_leaderboard(p_app_id text DEFAULT NULL)
RETURNS TABLE (
    rank         bigint,
    player_id    uuid,
    display_name text,
    avatar_url   text,
    best_score   integer
)
LANGUAGE sql
AS $$
    SELECT
        ROW_NUMBER() OVER (ORDER BY s.higher_score DESC) AS rank,
        s.player_id,
        p.display_name,
        p.avatar_url,
        s.higher_score AS best_score
    FROM game_flappy_scores s
    JOIN game_players p ON p.id = s.player_id
    WHERE p_app_id IS NULL OR s.app_id = p_app_id
    ORDER BY s.higher_score DESC
    LIMIT 10;
$$;

-- 7b. Simplified rank — one row per player, no MAX() aggregation needed
CREATE OR REPLACE FUNCTION get_flappy_user_rank(
    p_email  text,
    p_app_id text DEFAULT NULL
)
RETURNS TABLE (
    rank       bigint,
    best_score integer
)
LANGUAGE sql
AS $$
    WITH user_score AS (
        SELECT s.higher_score AS best_score
        FROM game_flappy_scores s
        JOIN game_players p ON p.id = s.player_id
        WHERE p.email = p_email
          AND (p_app_id IS NULL OR s.app_id = p_app_id)
    )
    SELECT
        (SELECT COUNT(*)
         FROM game_flappy_scores s2
         WHERE s2.higher_score > us.best_score
           AND (p_app_id IS NULL OR s2.app_id = p_app_id)) + 1 AS rank,
        us.best_score
    FROM user_score us;
$$;
