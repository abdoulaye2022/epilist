export const HOTJAR_ID = process.env.NEXT_PUBLIC_HOTJAR_ID

// Types locaux pour Hotjar
type Platform = 'ios' | 'android'

// Vérifier si Hotjar est disponible
const isHjAvailable = (): boolean => {
  return typeof window !== 'undefined' && 
         typeof window.hj === 'function' && 
         HOTJAR_ID !== undefined
}

// Identifier un utilisateur (pour les sessions)
export const hjIdentify = (userId: string, attributes: Record<string, any> = {}): void => {
  if (isHjAvailable()) {
    window.hj('identify', userId, attributes)
    console.log('🔥 Hotjar user identified:', { userId, attributes })
  }
}

// Déclencher un événement Hotjar
export const hjEvent = (eventName: string): void => {
  if (isHjAvailable()) {
    window.hj('event', eventName)
    console.log('🔥 Hotjar event:', eventName)
  }
}

// Événements Hotjar spécifiques
export const hjTrackDownloadIntent = (platform: Platform): void => {
  hjEvent(`download_intent_${platform}`)
}

export const hjTrackHighEngagement = (): void => {
  hjEvent('high_engagement_user')
}