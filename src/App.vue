<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { session, complete, restricted, isAdmin } from './lib/session'
const router = useRouter()
const route = useRoute()
watch(session, s => {
  if (!s) { if (route.name !== 'cgu' && route.name !== 'privacy') router.replace('/auth') }
  else if (route.name === 'auth') router.replace('/')
})

const items = computed<[string, string][]>(() => {
  const pub: [string, string][] = [['/cgu', 'CGU'], ['/privacy', 'Confidentialité']]
  if (!session.value) return [['/auth', 'Connexion'], ...pub]
  if (restricted.value) return [['/suspended', 'Compte'], ...pub]
  if (!complete.value) return [['/profile', 'Profil'], ...pub]
  const m: [string, string][] = [['/', 'Découvrir'], ['/search', 'Recherche'], ['/matches', 'Matchs'], ['/profile', 'Profil'], ['/verify', 'Vérification']]
  if (isAdmin.value) m.push(['/admin', 'Modération'])
  return [...m, ...pub]
})
const isAuth = computed(() => route.name === 'auth')
const bgStyle = computed(() => isAuth.value
  ? { backgroundImage: 'var(--auth-bg)', backgroundPosition: 'center bottom' }
  : { backgroundImage: 'var(--bg-image)' })
const on = (p: string) =>
  p === '/' ? route.path === '/' : route.path.startsWith(p) || (p === '/matches' && route.path.startsWith('/chat'))
</script>

<template>
  <div class="fixed inset-0 -z-10 bg-rose-50 bg-cover bg-center dark:bg-zinc-900" :style="bgStyle"></div>
  <div class="mx-auto flex h-dvh max-w-xl flex-col pt-[env(safe-area-inset-top)]">
    <header class="z-20 border-b border-white/40 bg-white/70 shadow-sm backdrop-blur-md dark:border-white/10 dark:bg-zinc-900/70">
      <router-link to="/" class="block px-4 pt-3 text-xl font-bold text-rose-600">Cœur Libre</router-link>
      <nav class="flex gap-1 overflow-x-auto px-3 pb-2 pt-1 text-sm">
        <router-link v-for="t in items" :key="t[0]" :to="t[0]"
          class="whitespace-nowrap rounded-full px-3 py-1.5 font-semibold"
          :class="on(t[0]) ? 'bg-rose-600 text-white' : 'text-zinc-600 dark:text-zinc-300'">{{ t[1] }}</router-link>
      </nav>
    </header>
    <main class="flex-1 overflow-auto p-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
      <div :class="isAuth ? '' : 'min-h-full rounded-2xl border border-white/50 bg-white/75 p-4 shadow-sm backdrop-blur-md dark:border-white/10 dark:bg-zinc-900/65'"><router-view /></div>
    </main>
  </div>
</template>
