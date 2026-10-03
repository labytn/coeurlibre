import { supabase } from './supabase'

export interface Card {
  id: string; display_name: string; age: number; city: string; bio: string
  interests: string[]; photo_paths: string[]; url?: string; liked?: boolean; verified?: boolean
}

export async function urls(paths: string[]): Promise<string[]> {
  if (!paths.length) return []
  const { data } = await supabase.storage.from('photos').createSignedUrls(paths, 3600)
  return (data ?? []).map(d => d.signedUrl ?? '')
}

export async function withUrl(list: Card[]): Promise<Card[]> {
  const u = await urls(list.map(p => p.photo_paths[0]).filter(Boolean))
  let i = 0
  return list.map(p => ({ ...p, url: p.photo_paths[0] ? u[i++] : '' }))
}
