<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
const mode = ref<'in' | 'up'>('in')
const email = ref('')
const pwd = ref('')
const adult = ref(false)
const ok = ref(false)
const err = ref('')
const busy = ref(false)
async function submit() {
  err.value = ''
  busy.value = true
  if (mode.value === 'up') {
    if (!adult.value) { err.value = 'Confirmez avoir 18 ans minimum.'; busy.value = false; return }
    const { error } = await supabase.auth.signUp({ email: email.value, password: pwd.value, options: { emailRedirectTo: location.origin } })
    if (error) err.value = error.message
    else ok.value = true
  } else {
    const { error } = await supabase.auth.signInWithPassword({ email: email.value, password: pwd.value })
    if (error) err.value = 'Identifiants invalides.'
  }
  busy.value = false
}
</script>

<template>
  <div class="mx-auto mt-8 max-w-sm space-y-4">
    <div class="flex gap-2">
      <button class="flex-1" :class="mode === 'in' ? 'btn' : 'btn2'" @click="mode = 'in'">Connexion</button>
      <button class="flex-1" :class="mode === 'up' ? 'btn' : 'btn2'" @click="mode = 'up'">Inscription</button>
    </div>
    <p v-if="ok" class="rounded-lg bg-green-100 p-3 text-green-900">Compte créé. Vérifiez votre e-mail pour confirmer, puis connectez-vous.</p>
    <form v-else class="space-y-3" @submit.prevent="submit">
      <input v-model="email" type="email" required autocomplete="email" placeholder="E-mail" class="inp" />
      <input v-model="pwd" type="password" required minlength="8" :autocomplete="mode === 'up' ? 'new-password' : 'current-password'" placeholder="Mot de passe (8 caractères min.)" class="inp" />
      <label v-if="mode === 'up'" class="flex items-start gap-2 text-sm"><input v-model="adult" type="checkbox" /> <span>J'ai 18 ans ou plus et j'accepte les <router-link to="/cgu" class="underline">CGU</router-link>.</span></label>
      <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
      <button class="btn w-full" :disabled="busy">{{ mode === 'up' ? 'Créer mon compte' : 'Se connecter' }}</button>
    </form>
  </div>
</template>
