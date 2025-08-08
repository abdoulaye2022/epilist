export const FACEBOOK_PIXEL_ID = process.env.NEXT_PUBLIC_FACEBOOK_PIXEL_ID

// Vérifier si Facebook Pixel est disponible
const isFbqAvailable = (): boolean => {
  return typeof window !== 'undefined' && 
         typeof window.fbq === 'function' && 
         FACEBOOK_PIXEL_ID !== undefined
}

// Page view tracking pour Facebook
export const fbPageView = (): void => {
  if (isFbqAvailable()) {
    window.fbq('track', 'PageView')
    console.log('📘 Facebook PageView tracked')
  }
}

// Événement personnalisé Facebook
export const fbEvent = (eventName: string, parameters: Record<string, any> = {}): void => {
  if (isFbqAvailable()) {
    window.fbq('track', eventName, parameters)
    console.log('📘 Facebook Event:', { eventName, parameters })
  }
}

// ==========================================
// ÉVÉNEMENTS SPÉCIFIQUES EPILIST POUR FACEBOOK
// ==========================================

type Platform = 'ios' | 'android'
type DownloadSource = 'header' | 'hero_main_cta' | 'hero_main_cta_desktop' | 'cta_section' | 'footer'

// Tracking téléchargement app pour Facebook (événement de conversion)
export const fbTrackAppDownload = (platform: Platform, source: DownloadSource): void => {
  // Événement standard Facebook pour conversions app
  fbEvent('InitiateCheckout', {
    content_category: 'app_download',
    content_name: 'EpiList App',
    platform: platform,
    source: source,
    value: 0, // Gratuit mais important pour le tracking
    currency: 'CAD'
  })
  
  // Événement personnalisé pour audiences granulaires
  fbEvent('AppDownloadClick', {
    platform: platform,
    source: source,
    app_name: 'EpiList'
  })
  
  console.log('📘 Facebook App Download tracked:', { platform, source })
}

// Tracking engagement fort (scroll 75%+)
export const fbTrackHighEngagement = (): void => {
  fbEvent('ViewContent', {
    content_type: 'website',
    content_category: 'high_engagement',
    engagement_level: 'high'
  })
}

// Tracking intérêt pour les fonctionnalités
export const fbTrackFeatureInterest = (featureName: string): void => {
  fbEvent('ViewContent', {
    content_type: 'feature',
    content_name: featureName,
    interest_level: 'viewing_features'
  })
}

// Tracking retour depuis app store (conversion importante)
export const fbTrackAppStoreReturn = (): void => {
  fbEvent('Purchase', {
    content_type: 'app_install_intent',
    value: 0,
    currency: 'CAD'
  })
}