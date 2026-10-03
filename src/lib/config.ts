declare global { interface Window { __CONFIG__?: Record<string, string> } }

export const REQUIRED = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'EDITOR_NAME', 'CONTACT_EMAIL']

// Dernier recours si config.js est vide ou périmé (cache) et si aucune variable VITE_* n'est définie.
// Valeurs publiques : la clé « publishable » Supabase est publique par conception.
const DEFAULTS: Record<string, string> = {
  SUPABASE_URL: 'https://rdmlqsmjpvjcuaixprek.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_rinW8TNzeLI3LQ3UdzZLWQ_qJt3IbF6',
  EDITOR_NAME: 'Nicolas Labyt',
  CONTACT_EMAIL: 'labyt.nicolas@gmail.com'
}

// Ordre : public/config.js (modifiable sans recompiler) > variables VITE_* (build) > valeurs ci-dessus.
export const cfg = (k: string): string =>
  String(window.__CONFIG__?.[k] || (import.meta.env as Record<string, string>)['VITE_' + k] || DEFAULTS[k] || '').trim()
