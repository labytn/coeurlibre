import { ref } from 'vue'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './supabase'

export const session = ref<Session | null>(null)
export const complete = ref(false)
export const restricted = ref(false)
export const isAdmin = ref(false)

async function setSession(s: Session | null) {
  if (s) {
    const { data } = await supabase.from('profiles').select('is_complete,status').eq('id', s.user.id).maybeSingle()
    complete.value = !!data?.is_complete
    restricted.value = !!data && data.status !== 'active'
    const { data: adm } = await supabase.rpc('is_admin')
    isAdmin.value = adm === true
  } else {
    complete.value = false
    restricted.value = false
    isAdmin.value = false
  }
  session.value = s
}

export const refresh = () => setSession(session.value)

export async function init() {
  const { data } = await supabase.auth.getSession()
  await setSession(data.session)
  supabase.auth.onAuthStateChange((_e, s) => { setTimeout(() => setSession(s), 0) })
}
