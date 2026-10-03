<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { session, refresh } from '../lib/session'
import { urls } from '../lib/photos'
import { shareSite } from '../lib/share'
const router = useRouter()
const uid = session.value!.user.id
const f = ref({ display_name: '', birthdate: '', gender: '', looking_for: '', city: '', bio: '', interests: '' })
const paths = ref<string[]>([])
const thumbs = ref<string[]>([])
const err = ref('')
const busy = ref(false)
const verified = ref(false)
const note = ref('')
async function invite() { note.value = (await shareSite()) === 'copied' ? 'Lien copié : collez-le dans un message.' : '' }

async function loadThumbs() { thumbs.value = await urls(paths.value) }

onMounted(async () => {
  const { data } = await supabase.from('profiles').select('*').eq('id', uid).maybeSingle()
  if (data) {
    f.value = {
      display_name: data.display_name, birthdate: data.birthdate ?? '', gender: data.gender ?? '',
      looking_for: data.looking_for ?? '', city: data.city ?? '', bio: data.bio, interests: data.interests.join(', ')
    }
    paths.value = data.photo_paths
    verified.value = data.verified
    await loadThumbs()
  }
})

async function add(e: Event) {
  const input = e.target as HTMLInputElement
  for (const file of Array.from(input.files ?? [])) {
    if (paths.value.length >= 6) break
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 5 * 1024 * 1024) {
      err.value = 'Photos JPEG, PNG ou WebP de 5 Mo maximum.'
      continue
    }
    const p = `${uid}/${crypto.randomUUID()}`
    const { error } = await supabase.storage.from('photos').upload(p, file, { contentType: file.type })
    if (error) err.value = error.message
    else paths.value.push(p)
  }
  input.value = ''
  await loadThumbs()
}

async function rm(i: number) {
  const [p] = paths.value.splice(i, 1)
  await supabase.storage.from('photos').remove([p])
  await loadThumbs()
}

async function save() {
  err.value = ''
  busy.value = true
  const interests = f.value.interests.split(',').map(s => s.trim()).filter(Boolean).slice(0, 10)
  const { error } = await supabase.from('profiles').upsert({
    id: uid, display_name: f.value.display_name.trim(), birthdate: f.value.birthdate || null,
    gender: f.value.gender || null, looking_for: f.value.looking_for || null,
    city: f.value.city.trim(), bio: f.value.bio.trim(), interests, photo_paths: paths.value
  })
  busy.value = false
  if (error) { err.value = error.message; return }
  await refresh()
  router.replace('/')
}

async function logout() { await supabase.auth.signOut() }

async function del() {
  if (!confirm('Supprimer définitivement votre compte et toutes vos données ?')) return
  if (paths.value.length) await supabase.storage.from('photos').remove(paths.value)
  const { error } = await supabase.rpc('delete_my_account')
  if (error) { err.value = error.message; return }
  await supabase.auth.signOut()
}
</script>

<template>
  <form class="space-y-3" @submit.prevent="save">
    <h1 class="text-lg font-bold">Mon profil</h1>
    <router-link to="/verify" class="block rounded-lg border border-zinc-300 p-3 text-sm dark:border-zinc-700">{{ verified ? '✔ Profil vérifié' : 'Vérifier mon profil (badge de confiance) →' }}</router-link>
    <label class="lbl">Prénom<input v-model="f.display_name" required maxlength="40" class="inp" /></label>
    <label class="lbl">Date de naissance (18 ans min.)<input v-model="f.birthdate" type="date" required class="inp" /></label>
    <div class="grid grid-cols-2 gap-3">
      <label class="lbl">Je suis
        <select v-model="f.gender" required class="inp"><option value="" disabled>Choisir</option><option value="homme">Un homme</option><option value="femme">Une femme</option><option value="autre">Autre</option></select>
      </label>
      <label class="lbl">Je cherche
        <select v-model="f.looking_for" required class="inp"><option value="" disabled>Choisir</option><option value="homme">Des hommes</option><option value="femme">Des femmes</option><option value="tous">Tout le monde</option></select>
      </label>
    </div>
    <label class="lbl">Ville<input v-model="f.city" required maxlength="80" class="inp" /></label>
    <label class="lbl">Présentation (500 max.)<textarea v-model="f.bio" maxlength="500" rows="4" class="inp"></textarea></label>
    <label class="lbl">Centres d'intérêt (séparés par des virgules, 10 max.)<input v-model="f.interests" class="inp" /></label>
    <div>
      <span class="lbl">Photos ({{ paths.length }}/6, au moins 1)</span>
      <div class="mt-1 flex flex-wrap gap-2">
        <div v-for="(t, i) in thumbs" :key="paths[i]" class="relative h-24 w-24">
          <img :src="t" class="h-full w-full rounded-lg object-cover" alt="" />
          <button type="button" class="absolute right-1 top-1 rounded-full bg-black/70 px-2 text-white" @click="rm(i)">×</button>
        </div>
      </div>
      <input v-if="paths.length < 6" type="file" accept="image/jpeg,image/png,image/webp" multiple class="mt-2 text-sm" @change="add" />
    </div>
    <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
    <button class="btn w-full" :disabled="busy">Enregistrer</button>
    <button type="button" class="btn2 w-full" @click="invite">Inviter des amis</button>
    <p v-if="note" class="text-center text-sm text-zinc-500">{{ note }}</p>
    <div class="flex gap-2 pt-4">
      <button type="button" class="btn2 flex-1" @click="logout">Déconnexion</button>
      <button type="button" class="btn2 flex-1 !text-red-600" @click="del">Supprimer mon compte</button>
    </div>
    <div class="flex justify-center gap-4 text-xs text-zinc-500 underline"><router-link to="/cgu">CGU</router-link><router-link to="/privacy">Confidentialité</router-link></div>
  </form>
</template>
