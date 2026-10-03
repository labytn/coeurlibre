<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { session, complete, restricted, isAdmin } from './lib/session'
const router = useRouter()
const route = useRoute()
watch(session, s => {
  if (!s) { if (route.name !== 'cgu') router.replace('/auth') }
  else if (route.name === 'auth') router.replace('/')
})
const tabs = computed(() => {
  const t = [['/', 'Découvrir'], ['/search', 'Recherche'], ['/matches', 'Matchs'], ['/profile', 'Profil']]
  if (isAdmin.value) t.push(['/admin', 'Modération'])
  return t
})
</script>

<template>
  <div class="mx-auto flex h-dvh max-w-lg flex-col pt-[env(safe-area-inset-top)]">
    <header class="border-b border-zinc-200 px-4 py-3 text-xl font-bold text-rose-600 dark:border-zinc-800">Cœur Libre</header>
    <main class="flex-1 overflow-auto p-4"><router-view /></main>
    <nav v-if="session && complete && !restricted" class="flex border-t border-zinc-200 pb-[env(safe-area-inset-bottom)] dark:border-zinc-800">
      <router-link v-for="t in tabs" :key="t[0]" :to="t[0]" exact-active-class="!text-rose-600"
        class="flex-1 py-3 text-center text-sm font-semibold text-zinc-500">{{ t[1] }}</router-link>
    </nav>
  </div>
</template>
