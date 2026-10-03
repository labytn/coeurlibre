import { createRouter, createWebHistory, createWebHashHistory } from 'vue-router'
import { Capacitor } from '@capacitor/core'
import { session, complete, restricted, isAdmin } from './lib/session'

export const router = createRouter({
  history: Capacitor.isNativePlatform() ? createWebHashHistory() : createWebHistory(),
  routes: [
    { path: '/auth', name: 'auth', component: () => import('./pages/Auth.vue') },
    { path: '/cgu', name: 'cgu', component: () => import('./pages/Cgu.vue') },
    { path: '/privacy', name: 'privacy', component: () => import('./pages/Privacy.vue') },
    { path: '/suspended', name: 'suspended', component: () => import('./pages/Suspended.vue') },
    { path: '/profile', name: 'profile', component: () => import('./pages/Profile.vue') },
    { path: '/verify', name: 'verify', component: () => import('./pages/Verify.vue') },
    { path: '/admin', name: 'admin', component: () => import('./pages/Moderation.vue') },
    { path: '/', name: 'home', component: () => import('./pages/Discover.vue') },
    { path: '/search', name: 'search', component: () => import('./pages/Search.vue') },
    { path: '/matches', name: 'matches', component: () => import('./pages/Matches.vue') },
    { path: '/chat/:id', name: 'chat', component: () => import('./pages/Chat.vue') },
    { path: '/:p(.*)*', redirect: '/' }
  ]
})

router.beforeEach(to => {
  if (to.name === 'cgu' || to.name === 'privacy') return true
  if (!session.value) return to.name === 'auth' ? true : { name: 'auth' }
  if (restricted.value) return to.name === 'suspended' ? true : { name: 'suspended' }
  if (to.name === 'suspended') return { name: 'home' }
  if (!complete.value) return to.name === 'profile' ? true : { name: 'profile' }
  if (to.name === 'auth') return { name: 'home' }
  if (to.name === 'admin' && !isAdmin.value) return { name: 'home' }
  return true
})
