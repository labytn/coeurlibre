import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

const REQUIRED = ['VITE_SUPABASE_URL', 'VITE_SUPABASE_ANON_KEY', 'VITE_EDITOR_NAME', 'VITE_CONTACT_EMAIL']

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_')
  if (mode === 'production') {
    for (const k of REQUIRED) if (!env[k]) throw new Error(`Variable d'environnement manquante : ${k}`)
  }
  return { plugins: [vue()], build: { chunkSizeWarningLimit: 2500 } }
})
