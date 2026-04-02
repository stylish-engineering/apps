-- ============================================================
-- Drop old RPC overloads that lack the p_month parameter.
--
-- When p_month was added with a DEFAULT, PostgreSQL retained the
-- old signatures, causing PostgREST PGRST203 ambiguity errors
-- when clients omit p_month. Dropping the old overloads leaves
-- only the new signatures, which handle the default correctly.
-- ============================================================

DROP FUNCTION IF EXISTS get_flappy_leaderboard(text);
DROP FUNCTION IF EXISTS get_flappy_user_rank(text, text);
