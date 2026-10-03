const DEFAULT_URL = 'https://app.coeurlibre.workers.dev/'

// Adresse publique à partager (dans l'app mobile l'adresse locale n'est pas partageable).
function siteUrl(): string {
  const h = location.hostname
  return h === 'localhost' || h === '127.0.0.1' || !location.protocol.startsWith('http') ? DEFAULT_URL : location.origin + '/'
}

// Partage natif si disponible (mobile), sinon copie dans le presse-papiers.
export async function shareSite(): Promise<'shared' | 'copied' | 'failed'> {
  const url = siteUrl()
  const text = "Je te conseille Cœur Libre : rencontres entre adultes, inscription gratuite, profils vérifiables par selfie."
  try {
    if (navigator.share) { await navigator.share({ title: 'Cœur Libre', text, url }); return 'shared' }
    await navigator.clipboard.writeText(text + ' ' + url)
    return 'copied'
  } catch {
    return 'failed'
  }
}
