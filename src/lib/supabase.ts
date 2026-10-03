import { createClient } from '@supabase/supabase-js'
import { cfg } from './config'

export const supabase = createClient(
  cfg('SUPABASE_URL') || 'https://config-manquante.invalid',
  cfg('SUPABASE_ANON_KEY') || 'config-manquante'
)
