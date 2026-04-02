-- ============================================================
-- Migrate game_flappy_scores to one record per player per month.
--
-- Previously: one row per player storing their all-time best score.
-- Now: one row per player per month storing their monthly best score.
--
-- Steps:
--   1. Add score_month column (server-computed, never caller-supplied)
--   2. Drop old UNIQUE(player_id) constraint
--   3. Add UNIQUE(player_id, score_month) constraint
--   4. Add index for efficient monthly leaderboard queries
--   5. Replace submit_flappy_score — same signature, new conflict target
--   6. Update get_flappy_leaderboard — add optional p_month param
--   7. Update get_flappy_user_rank — add optional p_month param
--   8. Add get_flappy_user_monthly_history — new RPC
-- ============================================================

-- 1. Add score_month — defaults to first day of current month
--    Existing rows get the current month, which is correct.
ALTER TABLE game_flappy_scores
    ADD COLUMN score_month date NOT NULL DEFAULT date_trunc('month', now())::date;

-- 2. Drop the all-time unique constraint
ALTER TABLE game_flappy_scores
    DROP CONSTRAINT game_flappy_scores_player_id_key;

-- 3. One best score per player per month
ALTER TABLE game_flappy_scores
    ADD CONSTRAINT game_flappy_scores_player_id_month_key
    UNIQUE (player_id, score_month);

-- 4. Index for efficient monthly leaderboard and rank queries
CREATE INDEX idx_gfs_month_score ON game_flappy_scores (score_month, higher_score DESC);

-- 5. submit_flappy_score — identical signature.
--    score_month is computed server-side via now(); callers cannot influence it.
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
    v_player_id  uuid;
    v_record_id  uuid;
    v_month      date := date_trunc('month', now())::date;
BEGIN
    -- Upsert player identity
    INSERT INTO game_players (email, display_name, avatar_url)
    VALUES (p_email, p_display_name, p_avatar_url)
    ON CONFLICT (email) DO UPDATE
        SET display_name = EXCLUDED.display_name,
            avatar_url   = EXCLUDED.avatar_url,
            updated_at   = now()
    RETURNING id INTO v_player_id;

    -- Insert first score for the month, or update only if the new score is higher.
    -- score_month is always the server's current month — callers cannot set it.
    INSERT INTO game_flappy_scores (player_id, app_id, higher_score, score_month)
    VALUES (v_player_id, p_app_id, p_score, v_month)
    ON CONFLICT (player_id, score_month) DO UPDATE
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

-- 6. get_flappy_leaderboard — p_month defaults to current month.
--    Pass a specific date (first of the month) to query a completed month.
CREATE OR REPLACE FUNCTION get_flappy_leaderboard(
    p_app_id text DEFAULT NULL,
    p_month  date DEFAULT date_trunc('month', now())::date
)
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
    WHERE s.score_month = p_month
      AND (p_app_id IS NULL OR s.app_id = p_app_id)
    ORDER BY s.higher_score DESC
    LIMIT 10;
$$;

-- 7. get_flappy_user_rank — p_month defaults to current month.
CREATE OR REPLACE FUNCTION get_flappy_user_rank(
    p_email  text,
    p_app_id text DEFAULT NULL,
    p_month  date DEFAULT date_trunc('month', now())::date
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
          AND s.score_month = p_month
          AND (p_app_id IS NULL OR s.app_id = p_app_id)
    )
    SELECT
        (SELECT COUNT(*) + 1
         FROM game_flappy_scores s2
         WHERE s2.score_month = p_month
           AND s2.higher_score > us.best_score
           AND (p_app_id IS NULL OR s2.app_id = p_app_id)) AS rank,
        us.best_score
    FROM user_score us;
$$;

-- 8. get_flappy_user_monthly_history — all months a user participated in,
--    with their best score and rank for each month.
--    Past months are frozen; clients should cache them in local storage.
CREATE OR REPLACE FUNCTION get_flappy_user_monthly_history(
    p_email  text,
    p_app_id text DEFAULT NULL
)
RETURNS TABLE (
    score_month date,
    best_score  integer,
    rank        bigint
)
LANGUAGE sql
AS $$
    WITH player AS (
        SELECT id FROM game_players WHERE email = p_email
    ),
    user_scores AS (
        SELECT s.score_month, s.higher_score AS best_score
        FROM game_flappy_scores s
        JOIN player ON s.player_id = player.id
        WHERE p_app_id IS NULL OR s.app_id = p_app_id
    )
    SELECT
        us.score_month,
        us.best_score,
        (SELECT COUNT(*) + 1
         FROM game_flappy_scores s2
         WHERE s2.score_month = us.score_month
           AND s2.higher_score > us.best_score
           AND (p_app_id IS NULL OR s2.app_id = p_app_id)
        ) AS rank
    FROM user_scores us
    ORDER BY us.score_month DESC;
$$;
