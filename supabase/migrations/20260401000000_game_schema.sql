-- ============================================================
-- Game project schema for yfrfgnvamuyvwentgndq
-- ("stylish-engineering-apps" — shared across all apps)
--
-- Apply via the Supabase dashboard SQL editor.
-- This project uses email as the cross-app user identity.
-- ============================================================

-- Cross-app player identity keyed by email
CREATE TABLE IF NOT EXISTS game_players (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    email       text        NOT NULL UNIQUE,
    display_name text,
    avatar_url  text,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Scores per player per app (full history, not just personal bests)
CREATE TABLE IF NOT EXISTS game_flappy_scores (
    id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id    uuid        NOT NULL REFERENCES game_players(id) ON DELETE CASCADE,
    app_id       text        NOT NULL DEFAULT 'sevendo',
    higher_score integer     NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gfs_score_desc  ON game_flappy_scores (higher_score DESC);
CREATE INDEX IF NOT EXISTS idx_gfs_player_id   ON game_flappy_scores (player_id);
CREATE INDEX IF NOT EXISTS idx_gfs_app_id      ON game_flappy_scores (app_id);

-- RLS: open read + insert (anon key, cross-project auth not possible)
ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_flappy_scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read players"
    ON game_players FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert players"
    ON game_players FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Public update players"
    ON game_players FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Public read scores"
    ON game_flappy_scores FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Public insert scores"
    ON game_flappy_scores FOR INSERT TO anon, authenticated WITH CHECK (true);

-- Upsert player by email + insert score — single atomic RPC call
CREATE OR REPLACE FUNCTION submit_flappy_score(
    p_email       text,
    p_display_name text,
    p_avatar_url  text,
    p_score       integer,
    p_app_id      text DEFAULT 'sevendo'
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
    v_player_id uuid;
    new_id      uuid;
BEGIN
    INSERT INTO game_players (email, display_name, avatar_url)
    VALUES (p_email, p_display_name, p_avatar_url)
    ON CONFLICT (email) DO UPDATE
        SET display_name = EXCLUDED.display_name,
            avatar_url   = EXCLUDED.avatar_url,
            updated_at   = now()
    RETURNING id INTO v_player_id;

    INSERT INTO game_flappy_scores (player_id, app_id, higher_score)
    VALUES (v_player_id, p_app_id, p_score)
    RETURNING id INTO new_id;

    RETURN new_id;
END;
$$;

-- Top 10 leaderboard — pass p_app_id to filter by app, or NULL for global
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
    WITH best_scores AS (
        SELECT DISTINCT ON (s.player_id)
            s.player_id,
            p.display_name,
            p.avatar_url,
            s.higher_score AS best_score
        FROM game_flappy_scores s
        JOIN game_players p ON p.id = s.player_id
        WHERE p_app_id IS NULL OR s.app_id = p_app_id
        ORDER BY s.player_id, s.higher_score DESC
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY best_score DESC) AS rank,
        bs.player_id,
        bs.display_name,
        bs.avatar_url,
        bs.best_score
    FROM best_scores bs
    ORDER BY best_score DESC
    LIMIT 10;
$$;

-- User rank by email — O(index scan), not full-table rank
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
    WITH user_best AS (
        SELECT MAX(s.higher_score) AS best_score
        FROM game_flappy_scores s
        JOIN game_players p ON p.id = s.player_id
        WHERE p.email = p_email
          AND (p_app_id IS NULL OR s.app_id = p_app_id)
    )
    SELECT
        (SELECT COUNT(DISTINCT s2.player_id)
         FROM game_flappy_scores s2
         WHERE s2.higher_score > ub.best_score
           AND (p_app_id IS NULL OR s2.app_id = p_app_id)) + 1 AS rank,
        ub.best_score
    FROM user_best ub
    WHERE ub.best_score IS NOT NULL;
$$;
