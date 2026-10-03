<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'
import { urls } from '../lib/photos'
interface M { match_id: string; other_id: string; display_name: string; photo_paths: string[]; url?: string }
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
      <img v-if="m.url" :src="m.url" class="h-14 w-14 rounded-full object-cover" alt="" />
      <b class="flex-1">{{ m.display_name }}</b>
      <span class="text-sm text-rose-600">Écrire →</span>
    </router-link>
  </div>
</template>
