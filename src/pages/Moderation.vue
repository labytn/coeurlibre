<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase'

interface R { id: number; reason: string; created_at: string; reporter_name: string; reported_id: string; reported_name: string; reported_status: string; reported_photo: string | null; report_count: number }
interface V { id: number; user_id: string; name: string; selfie_path: string; photo_path: string | null; distance: number; status: string; auto: boolean; created_at: string }
interface U { id: string; name: string; status: string }

const tab = ref<'r' | 'v' | 'u'>('r')
const reports = ref<R[]>([])
const verifs = ref<V[]>([])
const users = ref<U[]>([])
const urlMap = ref<Record<string, string>>({})
const selfieMap = ref<Record<string, string>>({})
const err = ref('')
const loading = ref(true)

async function sign(bucket: string, paths: (string | null)[]) {
  const all = paths.filter(Boolean) as string[]
  const m: Record<string, string> = {}
  const isDemo = (p: string) => bucket === 'photos' && p.startsWith('demo/')
  for (const p of all) if (isDemo(p)) m[p] = '/' + p
  const clean = all.filter(p => !isDemo(p))
  if (!clean.length) return m
  const { data } = await supabase.storage.from(bucket).createSignedUrls(clean, 3600)
  for (const d of data ?? []) if (d.path && d.signedUrl) m[d.path] = d.signedUrl
  return m
}

async function purge() {
  const { data } = await supabase.rpc('admin_old_selfies')
  const rows = (data ?? []) as { id: number; selfie_path: string }[]
  if (!rows.length) return
  await supabase.storage.from('selfies').remove(rows.map(r => r.selfie_path))
  await supabase.rpc('admin_clear_selfies', { p_ids: rows.map(r => r.id) })
}

async function load() {
  loading.value = true
  const [r, v, u] = await Promise.all([
    supabase.rpc('admin_open_reports'), supabase.rpc('admin_verifications'), supabase.rpc('admin_sanctioned')
  ])
  reports.value = (r.data ?? []) as R[]
  verifs.value = (v.data ?? []) as V[]
  users.value = (u.data ?? []) as U[]
  urlMap.value = await sign('photos', [...reports.value.map(x => x.reported_photo), ...verifs.value.map(x => x.photo_path)])
  selfieMap.value = await sign('selfies', verifs.value.map(x => x.selfie_path))
  loading.value = false
}
onMounted(async () => { await purge(); await load() })

const pending = computed(() => verifs.value.filter(v => v.status === 'pending').length)

async function resolve(r: R, action: 'dismiss' | 'suspend' | 'ban') {
  if (action === 'ban' && !confirm(`Bannir ${r.reported_name} ?`)) return
  const { error } = await supabase.rpc('admin_resolve_report', { p_id: r.id, p_action: action })
  if (error) err.value = error.message
  else await load()
}
async function review(v: V, ok: boolean) {
  const { error } = await supabase.rpc('admin_review_verification', { p_id: v.id, p_approve: ok })
  if (error) { err.value = error.message; return }
  await supabase.storage.from('selfies').remove([v.selfie_path])
  await load()
}
async function reinstate(u: U) {
  const { error } = await supabase.rpc('admin_set_status', { p_user: u.id, p_status: 'active' })
  if (error) err.value = error.message
  else await load()
}
const date = (s: string) => new Date(s).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' })
</script>

<template>
  <div class="space-y-3">
    <h1 class="text-lg font-bold">Modération</h1>
    <div class="flex gap-2 text-sm">
      <button :class="tab === 'r' ? 'btn' : 'btn2'" @click="tab = 'r'">Signalements ({{ reports.length }})</button>
      <button :class="tab === 'v' ? 'btn' : 'btn2'" @click="tab = 'v'">Vérifs ({{ pending }})</button>
      <button :class="tab === 'u' ? 'btn' : 'btn2'" @click="tab = 'u'">Sanctions ({{ users.length }})</button>
    </div>
    <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
    <p v-if="loading" class="text-zinc-500">Chargement…</p>

    <template v-else-if="tab === 'r'">
      <p v-if="!reports.length" class="text-zinc-500">Aucun signalement ouvert.</p>
      <div v-for="r in reports" :key="r.id" class="rounded-xl border border-zinc-200 p-3 dark:border-zinc-800">
        <div class="flex gap-3">
          <img v-if="r.reported_photo && urlMap[r.reported_photo]" :src="urlMap[r.reported_photo]" class="h-16 w-16 rounded-lg object-cover" alt="" />
          <div class="min-w-0 flex-1">
            <b>{{ r.reported_name }}</b> <span class="text-xs text-zinc-500">· {{ r.report_count }} signalement(s) · {{ r.reported_status }}</span>
            <p class="break-words text-sm">« {{ r.reason }} »</p>
            <p class="text-xs text-zinc-500">par {{ r.reporter_name }} · {{ date(r.created_at) }}</p>
          </div>
        </div>
        <div class="mt-2 flex gap-2 text-sm">
          <button class="btn2 flex-1" @click="resolve(r, 'dismiss')">Rejeter</button>
          <button class="btn2 flex-1" @click="resolve(r, 'suspend')">Suspendre</button>
          <button class="btn flex-1" @click="resolve(r, 'ban')">Bannir</button>
        </div>
      </div>
    </template>

    <template v-else-if="tab === 'v'">
      <p v-if="!verifs.length" class="text-zinc-500">Aucune vérification à examiner.</p>
      <div v-for="v in verifs" :key="v.id" class="rounded-xl border border-zinc-200 p-3 dark:border-zinc-800">
        <div class="mb-2 flex items-center justify-between text-sm">
          <b>{{ v.name }}</b>
          <span class="text-xs text-zinc-500">{{ v.status === 'pending' ? 'À examiner' : 'Auto-validé (contrôle)' }} · dist. {{ v.distance.toFixed(2) }} · {{ date(v.created_at) }}</span>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <img v-if="v.photo_path && urlMap[v.photo_path]" :src="urlMap[v.photo_path]" class="h-40 w-full rounded-lg object-cover" alt="Photo de profil" />
          <img v-if="selfieMap[v.selfie_path]" :src="selfieMap[v.selfie_path]" class="h-40 w-full rounded-lg object-cover" alt="Selfie" />
        </div>
        <div class="mt-2 flex gap-2 text-sm">
          <button class="btn flex-1" @click="review(v, true)">{{ v.status === 'pending' ? 'Approuver' : 'Confirmer' }}</button>
          <button class="btn2 flex-1" @click="review(v, false)">{{ v.status === 'pending' ? 'Refuser' : 'Révoquer' }}</button>
        </div>
      </div>
    </template>

    <template v-else>
      <p v-if="!users.length" class="text-zinc-500">Aucun compte sanctionné.</p>
      <div v-for="u in users" :key="u.id" class="flex items-center justify-between rounded-xl border border-zinc-200 p-3 dark:border-zinc-800">
        <span><b>{{ u.name }}</b> <span class="text-xs text-zinc-500">· {{ u.status === 'banned' ? 'banni' : 'suspendu' }}</span></span>
        <button class="btn2 text-sm" @click="reinstate(u)">Réactiver</button>
      </div>
    </template>
  </div>
</template>
