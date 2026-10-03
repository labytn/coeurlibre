<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'
import { withUrl, type Card } from '../lib/photos'
const f = ref({ min: 18, max: 99, city: '', interest: '', verified: false })
const res = ref<Card[]>([])
const loading = ref(false)
const msg = ref('')

async function run() {
  loading.value = true
  const { data } = await supabase.rpc('search_profiles', {
    p_min: f.value.min || 18, p_max: f.value.max || 99, p_city: f.value.city.trim(), p_interest: f.value.interest.trim(), p_verified: f.value.verified
  })
  res.value = await withUrl((data ?? []) as Card[])
  loading.value = false
}
onMounted(run)

async function like(p: Card) {
  const { data, error } = await supabase.rpc('swipe', { p_target: p.id, p_liked: true })
  if (error) { msg.value = error.message; return }
  p.liked = true
  if (data) msg.value = `C'est un match avec ${p.display_name} !`
  setTimeout(() => { msg.value = '' }, 3000)
}
</script>

<template>
  <div>
    <div class="mb-3 grid grid-cols-2 gap-3">
      <label class="lbl">Âge min<input v-model.number="f.min" type="number" min="18" max="99" class="inp" /></label>
      <label class="lbl">Âge max<input v-model.number="f.max" type="number" min="18" max="99" class="inp" /></label>
      <label class="lbl">Ville<input v-model="f.city" class="inp" /></label>
      <label class="lbl">Centre d'intérêt<input v-model="f.interest" class="inp" /></label>
    </div>
    <label class="mb-3 flex items-center gap-2 text-sm"><input v-model="f.verified" type="checkbox" /> Profils vérifiés uniquement</label>
    <button class="btn w-full" :disabled="loading" @click="run">Rechercher</button>
    <p v-if="msg" class="mt-3 rounded-lg bg-rose-100 p-2 text-center font-semibold text-rose-700">{{ msg }}</p>
    <p v-if="!loading" class="mt-4 text-sm text-zinc-500">{{ res.length }} profil(s)</p>
    <div v-for="p in res" :key="p.id" class="mt-2 flex items-center gap-3 rounded-xl border border-zinc-200 p-2 dark:border-zinc-800">
      <div class="relative h-14 w-14 shrink-0 overflow-hidden rounded-full bg-zinc-300 dark:bg-zinc-700"><img v-if="p.url" :src="p.url" class="h-full w-full object-cover" alt="" /><span v-if="p.is_demo" class="absolute inset-x-0 bottom-0 bg-black/70 text-center text-[9px] font-bold leading-4 text-white">DÉMO</span></div>
      <div class="min-w-0 flex-1">
        <b>{{ p.display_name }}, {{ p.age }}</b> <span v-if="p.verified" title="Profil vérifié" class="text-sky-500">✔</span>
        <div class="truncate text-xs text-zinc-500">{{ p.city }} · {{ p.interests.join(', ') }}</div>
      </div>
      <button class="btn2 text-lg !text-rose-600" :disabled="p.liked" @click="like(p)">{{ p.liked ? '♥ envoyé' : '♡' }}</button>
    </div>
  </div>
</template>
