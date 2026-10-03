<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'
import { session } from '../lib/session'
import { withUrl, type Card } from '../lib/photos'
import { shareSite } from '../lib/share'
const list = ref<Card[]>([])
const loading = ref(true)
const msg = ref('')
const dx = ref(0)
const drag = ref(false)
let x0 = 0
const top = computed(() => list.value[0])

async function load() {
  loading.value = true
  const { data } = await supabase.rpc('discover_profiles', { p_limit: 20 })
  list.value = await withUrl((data ?? []) as Card[])
  loading.value = false
}
const who = ref("quelqu'un")
const waitMsg = computed(() => `Votre inscription est bien enregistrée. Veuillez patienter et revenir consulter le site en attendant que ${who.value} vous choisisse.`)
onMounted(async () => {
  const { data } = await supabase.from('profiles').select('looking_for').eq('id', session.value!.user.id).maybeSingle()
  who.value = data?.looking_for === 'femme' ? 'une femme' : data?.looking_for === 'homme' ? 'un homme' : "quelqu'un"
  load()
})

function toast(t: string) { msg.value = t; setTimeout(() => { msg.value = '' }, 3000) }
async function invite() { if ((await shareSite()) === 'copied') toast('Lien copié : collez-le dans un message.') }

async function decide(like: boolean) {
  const p = top.value
  if (!p) return
  list.value.shift()
  dx.value = 0
  const { data, error } = await supabase.rpc('swipe', { p_target: p.id, p_liked: like })
  if (error) toast(error.message)
  else if (data) toast(`C'est un match avec ${p.display_name} !`)
  if (!list.value.length) await load()
}

async function flag() {
  const p = top.value
  if (!p) return
  const reason = prompt('Motif du signalement ?')
  if (!reason || reason.trim().length < 3) return
  const me = session.value!.user.id
  await supabase.from('reports').insert({ reporter_id: me, reported_id: p.id, reason: reason.trim() })
  await supabase.from('blocks').insert({ blocker_id: me, blocked_id: p.id })
  list.value.shift()
  if (!list.value.length) await load()
}

function down(e: PointerEvent) { x0 = e.clientX; drag.value = true; (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId) }
function move(e: PointerEvent) { if (drag.value) dx.value = e.clientX - x0 }
function up() {
  if (!drag.value) return
  drag.value = false
  if (Math.abs(dx.value) > 90) decide(dx.value > 0)
  else dx.value = 0
}
</script>

<template>
  <div>
    <p v-if="msg" class="fixed left-1/2 top-16 z-10 -translate-x-1/2 rounded-full bg-rose-600 px-4 py-2 font-semibold text-white">{{ msg }}</p>
    <p v-if="loading" class="p-8 text-center text-zinc-500">Chargement…</p>
    <div v-else-if="!top" class="p-8 text-center">
      <p class="mb-4 text-zinc-500">{{ waitMsg }}</p>
      <button class="btn" @click="load">Actualiser</button>
      <p class="mt-6 text-sm text-zinc-500">Plus il y a de monde, plus vous aurez de choix.</p>
      <button class="btn2 mt-2" @click="invite">Inviter des amis</button>
    </div>
    <div v-else>
      <div class="relative h-[58vh] touch-pan-y select-none overflow-hidden rounded-2xl bg-zinc-300 dark:bg-zinc-700"
        :style="{ transform: `translateX(${dx}px) rotate(${dx / 20}deg)`, transition: drag ? 'none' : 'transform .2s' }"
        @pointerdown="down" @pointermove="move" @pointerup="up" @pointercancel="up">
        <img v-if="top.url" :src="top.url" draggable="false" class="absolute inset-0 h-full w-full object-cover" alt="" />
        <span v-if="top.is_demo" class="absolute left-3 top-3 rounded bg-black/70 px-2 py-1 text-xs font-bold tracking-widest text-white">DÉMO</span>
        <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/80 to-transparent p-4 text-white">
          <h2 class="text-2xl font-bold">{{ top.display_name }}, {{ top.age }} <span v-if="top.verified" title="Profil vérifié" class="text-sky-300">✔</span></h2>
          <p class="text-sm opacity-90">{{ top.city }}</p>
          <p class="mt-1 text-sm">{{ top.bio }}</p>
          <div class="mt-2 flex flex-wrap gap-1"><span v-for="i in top.interests" :key="i" class="rounded-full border border-white/50 px-2 py-0.5 text-xs">{{ i }}</span></div>
        </div>
      </div>
      <div class="mt-4 flex items-center justify-center gap-6">
        <button class="h-16 w-16 rounded-full border border-zinc-300 text-2xl text-red-500 dark:border-zinc-700" aria-label="Passer" @click="decide(false)">✕</button>
        <button class="h-16 w-16 rounded-full border border-zinc-300 text-2xl text-rose-600 dark:border-zinc-700" aria-label="Liker" @click="decide(true)">♥</button>
      </div>
      <button class="mx-auto mt-3 block text-xs text-zinc-500 underline" @click="flag">Signaler et bloquer</button>
    </div>
  </div>
</template>
