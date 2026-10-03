import { supabase } from './supabase'

export interface Card {
  id: string; display_name: string; age: number; city: string; bio: string
  interests: string[]; photo_paths: string[]; url?: string; liked?: boolean; verified?: boolean; is_demo?: boolean
}

// Photos de démo : fichiers statiques /demo/*.jpg ; vraies photos : bucket privé (URLs signées).
export async function urls(paths: string[]): Promise<string[]> {
  const real = paths.filter(p => p && !p.startsWith('demo/'))
  const map: Record<string, string> = {}
  if (real.length) {
    const { data } = await supabase.storage.from('photos').createSignedUrls(real, 3600)
    for (const d of data ?? []) if (d.path && d.signedUrl) map[d.path] = d.signedUrl
  }
  return paths.map(p => (p.startsWith('demo/') ? '/' + p : map[p] ?? ''))
}

export async function withUrl(list: Card[]): Promise<Card[]> {
  const u = await urls(list.map(p => p.photo_paths[0] ?? ''))
  return list.map((p, i) => ({ ...p, url: u[i] }))
}
