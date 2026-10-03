import { defineConfig, type Plugin } from 'vite'
import vue from '@vitejs/plugin-vue'

// Ajoute un identifiant de build à config.js pour éviter qu'un ancien fichier vide reste en cache.
const build = String(Date.now())
const stampConfig = (): Plugin => ({
  name: 'stamp-config',
  transformIndexHtml: html => html.replace('src="/config.js"', `src="/config.js?v=${build}"`)
})

export default defineConfig({ plugins: [vue(), stampConfig()], build: { chunkSizeWarningLimit: 2500 } })