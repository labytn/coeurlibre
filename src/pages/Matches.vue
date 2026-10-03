<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'
import { urls } from '../lib/photos'
interface M { match_id: string; other_id: string; display_name: string; photo_paths: string[]; url?: string; is_demo: boolean }
const list = ref<M[]>([])
const loading = ref(true)
onMounted(async () => {
  const { data } = await supabase.rpc('my_matches')
  const rows = (data ?? []) as M[]
  const u = await urls(rows.map(r => r.photo_paths[0]).filter(Boolean))
  let i = 0
  list.value = rows.map(r => ({ ...r, url: r.photo_paths[0] ? u[i++] : '' }))
  loading.value = false
})
</script>

<template>
  <div>
    <h1 class="mb-3 text-lg font-bold">Mes matchs</h1>
    <p v-if="!loading && !list.length" class="text-zinc-500">Aucun match pour le moment. Likez des profils !</p>
    <router-link v-for="m in list" :key="m.match_id" :to="`/chat/${m.match_id}`"
      class="mb-2 flex items-center gap-3 rounded-xl border border-zinc-200 p-2 dark:border-zinc-800">
      <div class="relative h-14 w-14 shrink-0 overflow-hidden rounded-full bg-zinc-300 dark:bg-zinc-700"><img v-if="m.url" :src="m.url" class="h-full w-full object-cover" alt="" /><span v-if="m.is_demo" class="absolute inset-x-0 bottom-0 bg-black/70 text-center text-[9px] font-bold leading-4 text-white">DÉMO</span></div>
      <b class="flex-1">{{ m.display_name }}</b>
      <span class="text-sm text-rose-600">Écrire →</span>
    </router-link>
  </div>
</template>
