import { createClient } from '@supabase/supabase-js';
import { PUBLIC_GAME_SUPABASE_URL, PUBLIC_GAME_SUPABASE_ANON_KEY } from '$env/static/public';

export const gameSupabase = createClient(PUBLIC_GAME_SUPABASE_URL, PUBLIC_GAME_SUPABASE_ANON_KEY);
