import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router'
import { init } from './lib/session'
import './style.css'
init().then(() => createApp(App).use(router).mount('#app'))
