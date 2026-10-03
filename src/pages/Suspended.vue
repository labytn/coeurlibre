<script setup lang="ts">
import { supabase } from '../lib/supabase'
const mail = import.meta.env.VITE_CONTACT_EMAIL as string
</script>

<template>
  <div class="mt-12 space-y-4 text-center">
    <h1 class="text-lg font-bold">Compte restreint</h1>
    <p class="text-zinc-500">Votre compte a été suspendu ou banni par la modération, conformément aux <router-link to="/cgu" class="underline">CGU</router-link>. Pour contester, écrivez à {{ mail }}.</p>
    <button class="btn2" @click="supabase.auth.signOut()">Déconnexion</button>
  </div>
</template>
