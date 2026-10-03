<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'

const mode = ref<'in' | 'up'>('in')
const step = ref<'form' | 'code' | 'forgot' | 'reset'>('form')
const email = ref('')
const pwd = ref('')
const newPwd = ref('')
const code = ref('')
const adult = ref(false)
const err = ref('')
const info = ref('')
const busy = ref(false)

async function run(fn: () => Promise<void>) {
  err.value = ''
  info.value = ''
  busy.value = true
  try { await fn() } catch (e: any) { err.value = e?.message ?? "Erreur inattendue." }
  busy.value = false
}

const mail = () => email.value.trim()

const submit = () => run(async () => {
  if (mode.value === 'up') {
    if (!adult.value) throw new Error("Confirmez avoir 18 ans minimum.")
    const { data, error } = await supabase.auth.signUp({ email: mail(), password: pwd.value })
    if (error) throw error
    if (!data.session) { step.value = 'code'; info.value = "Un code de confirmation vient d'être envoyé par e-mail." }
  } else {
    const { error } = await supabase.auth.signInWithPassword({ email: mail(), password: pwd.value })
    if (error) {
      if (/not confirmed/i.test(error.message)) {
        await supabase.auth.resend({ type: 'signup', email: mail() })
        step.value = 'code'
        info.value = "E-mail non confirmé : un nouveau code vient d'être envoyé."
      } else {
        throw new Error("Identifiants invalides.")
      }
    }
  }
})

const confirmCode = () => run(async () => {
  const { error } = await supabase.auth.verifyOtp({ email: mail(), token: code.value.trim(), type: 'signup' })
  if (error) throw new Error("Code invalide ou expiré.")
})

const resend = () => run(async () => {
  const { error } = await supabase.auth.resend({ type: 'signup', email: mail() })
  if (error) throw error
  info.value = "Code renvoyé."
})

const forgot = () => run(async () => {
  const { error } = await supabase.auth.resetPasswordForEmail(mail())
  if (error) throw error
  step.value = 'reset'
  info.value = "Si un compte existe pour cette adresse, un code vient d'être envoyé."
})

const reset = () => run(async () => {
  const { error } = await supabase.auth.verifyOtp({ email: mail(), token: code.value.trim(), type: 'recovery' })
  if (error) throw new Error("Code invalide ou expiré.")
  const { error: e2 } = await supabase.auth.updateUser({ password: newPwd.value })
  if (e2) throw e2
})

function back() { step.value = 'form'; code.value = ''; err.value = ''; info.value = '' }
</script>

<template>
  <div class="mx-auto max-w-sm space-y-4 pb-48 pt-4">
    <div class="px-1 text-center text-white [text-shadow:0_2px_14px_rgba(0,0,0,0.5)]">
      <h1 class="text-3xl font-bold">Rencontres entre adultes</h1>
      <p class="mt-2 text-sm">Inscription gratuite · Badge « Profil vérifié » par selfie · Signalement et blocage en un clic · 18+</p>
    </div>
    <div class="space-y-4 rounded-2xl bg-white/90 p-5 shadow-xl backdrop-blur-md dark:bg-zinc-900/85">
    <template v-if="step === 'form'">
      <div class="flex gap-2">
        <button class="flex-1" :class="mode === 'in' ? 'btn' : 'btn2'" @click="mode = 'in'">Connexion</button>
        <button class="flex-1" :class="mode === 'up' ? 'btn' : 'btn2'" @click="mode = 'up'">Inscription</button>
      </div>
      <form class="space-y-3" @submit.prevent="submit">
        <input v-model="email" type="email" required autocomplete="email" placeholder="E-mail" class="inp" />
        <input v-model="pwd" type="password" required minlength="8" :autocomplete="mode === 'up' ? 'new-password' : 'current-password'" placeholder="Mot de passe (8 caractères min.)" class="inp" />
        <label v-if="mode === 'up'" class="flex items-start gap-2 text-sm"><input v-model="adult" type="checkbox" class="mt-1" />
          <span>J'ai 18 ans ou plus et j'accepte les <router-link to="/cgu" class="underline">CGU</router-link> et la <router-link to="/privacy" class="underline">politique de confidentialité</router-link>.</span></label>
        <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
        <button class="btn w-full" :disabled="busy">{{ mode === 'up' ? 'Créer mon compte' : 'Se connecter' }}</button>
      </form>
      <button v-if="mode === 'in'" class="block w-full text-center text-sm text-zinc-500 underline" @click="step = 'forgot'; err = ''">Mot de passe oublié ?</button>
      <router-link to="/cgu" class="block text-center text-xs text-zinc-500 underline">CGU</router-link>
    </template>

    <form v-else-if="step === 'code'" class="space-y-3" @submit.prevent="confirmCode">
      <h1 class="text-lg font-bold">Confirmez votre e-mail</h1>
      <p v-if="info" class="text-sm text-zinc-500">{{ info }}</p>
      <input v-model="code" inputmode="numeric" autocomplete="one-time-code" required maxlength="10" placeholder="Code reçu par e-mail" class="inp tracking-widest" />
      <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
      <button class="btn w-full" :disabled="busy">Valider</button>
      <div class="flex justify-between text-sm"><button type="button" class="underline" @click="resend">Renvoyer le code</button><button type="button" class="underline" @click="back">Retour</button></div>
    </form>

    <form v-else-if="step === 'forgot'" class="space-y-3" @submit.prevent="forgot">
      <h1 class="text-lg font-bold">Mot de passe oublié</h1>
      <input v-model="email" type="email" required autocomplete="email" placeholder="E-mail du compte" class="inp" />
      <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
      <button class="btn w-full" :disabled="busy">Recevoir un code</button>
      <button type="button" class="block w-full text-center text-sm underline" @click="back">Retour</button>
    </form>

    <form v-else class="space-y-3" @submit.prevent="reset">
      <h1 class="text-lg font-bold">Nouveau mot de passe</h1>
      <p v-if="info" class="text-sm text-zinc-500">{{ info }}</p>
      <input v-model="code" inputmode="numeric" autocomplete="one-time-code" required maxlength="10" placeholder="Code reçu par e-mail" class="inp tracking-widest" />
      <input v-model="newPwd" type="password" required minlength="8" autocomplete="new-password" placeholder="Nouveau mot de passe (8 caractères min.)" class="inp" />
      <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
      <button class="btn w-full" :disabled="busy">Changer le mot de passe</button>
      <button type="button" class="block w-full text-center text-sm underline" @click="back">Retour</button>
    </form>
    </div>
  </div>
</template>
