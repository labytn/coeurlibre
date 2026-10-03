import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'fr.coeurlibre.app',
  appName: 'Cœur Libre',
  webDir: 'dist',
  server: { androidScheme: 'https' }
}

export default config
