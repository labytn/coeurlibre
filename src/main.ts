import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router'
import { init } from './lib/session'
import { cfg, REQUIRED } from './lib/config'
import './style.css'

const missing = REQUIRED.filter(k => !cfg(k))
if (missing.length) {
  document.getElementById('app')!.innerHTML =
    '<p style="padding:24px;font-family:system-ui,sans-serif">Configuration manquante dans config.js : ' + missing.join(', ') + '</p>'
} else {
  init().then(() => createApp(App).use(router).mount('#app'))
}
