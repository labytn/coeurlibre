<script setup lang="ts">
import { nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { session } from '../lib/session'
interface Msg { id: number; sender_id: string; body: string; created_at: string }
const route = useRoute()
const router = useRouter()
const id = route.params.id as string
const me = session.value!.user.id
const msgs = ref<Msg[]>([])
const name = ref('')
const otherId = ref('')
const text = ref('')
const err = ref('')
const box = ref<HTMLElement | null>(null)
let ch: ReturnType<typeof supabase.channel> | null = null

async function scroll() { await nextTick(); if (box.value) box.value.scrollTop = box.value.scrollHeight }
function push(m: Msg) { if (!msgs.value.some(x => x.id === m.id)) { msgs.value.push(m); scroll() } }

onMounted(async () => {
  const { data: ms } = await supabase.rpc('my_matches')
  const m = ((ms ?? []) as { match_id: string; other_id: string; display_name: string }[]).find(x => x.match_id === id)
  if (!m) { router.replace('/matches'); return }
  name.value = m.display_name
  otherId.value = m.other_id
  const { data } = await supabase.from('messages').select('id,sender_id,body,created_at').eq('match_id', id).order('created_at')
  msgs.value = (data ?? []) as Msg[]
  scroll()
  ch = supabase.channel('chat-' + id)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `match_id=eq.${id}` }, p => push(p.new as Msg))
    .subscribe()
})
onUnmounted(() => { if (ch) supabase.removeChannel(ch) })

async function send() {
  const body = text.value.trim()
  if (!body) return
  text.value = ''
  const { data, error } = await supabase.from('messages').insert({ match_id: id, sender_id: me, body }).select('id,sender_id,body,created_at').single()
  if (error) err.value = error.message
  else push(data as Msg)
}

async function flag() {
  const reason = prompt('Motif du signalement ?')
  if (!reason || reason.trim().length < 3) return
  await supabase.from('reports').insert({ reporter_id: me, reported_id: otherId.value, reason: reason.trim() })
  await supabase.from('blocks').insert({ blocker_id: me, blocked_id: otherId.value })
  router.replace('/matches')
}
</script>

<template>
  <div class="flex h-full flex-col">
    <div class="mb-2 flex items-center justify-between">
      <router-link to="/matches" class="text-sm text-rose-600">← Matchs</router-link>
      <b>{{ name }}</b>
      <button class="text-xs text-zinc-500 underline" @click="flag">Signaler</button>
    </div>
    <div ref="box" class="flex-1 space-y-2 overflow-auto">
      <div v-for="m in msgs" :key="m.id" class="flex" :class="m.sender_id === me ? 'justify-end' : 'justify-start'">
        <span class="max-w-[80%] whitespace-pre-wrap break-words rounded-2xl px-3 py-2"
          :class="m.sender_id === me ? 'bg-rose-600 text-white' : 'bg-zinc-200 dark:bg-zinc-800'">{{ m.body }}</span>
      </div>
    </div>
    <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
    <form class="mt-2 flex gap-2" @submit.prevent="send">
      <input v-model="text" maxlength="2000" placeholder="Votre message" class="inp" />
      <button class="btn">Envoyer</button>
    </form>
  </div>
</template>
