import * as gtag from './gtag'
import * as fbPixel from './facebook-pixel'
import * as hotjar from './hotjar'

type Platform = 'ios' | 'android'
type DownloadSource = 'header' | 'hero_main_cta' | 'hero_main_cta_desktop' | 'cta_section' | 'footer'

// Tracking téléchargement sur toutes les plateformes
export const trackAppDownloadUnified = (platform: Platform, source: DownloadSource): void => {
  console.log('🎯 UNIFIED TRACKING - App Download:', { platform, source })
  
  // Google Analytics 4
  gtag.trackAppDownload(platform, source)
  
  // Facebook Pixel
  fbPixel.fbTrackAppDownload(platform, source)
  
  // Hotjar
  hotjar.hjTrackDownloadIntent(platform)
}

// Tracking engagement élevé
export const trackHighEngagementUnified = (): void => {
  console.log('🎯 UNIFIED TRACKING - High Engagement')
  
  // Google Analytics 4
  gtag.trackScrollDepth(75)
  
  // Facebook Pixel
  fbPixel.fbTrackHighEngagement()
  
  // Hotjar
  hotjar.hjTrackHighEngagement()
}

// Tracking retour app store
export const trackAppStoreReturnUnified = (): void => {
  console.log('🎯 UNIFIED TRACKING - App Store Return')
  
  // Google Analytics 4
  gtag.trackFeatureInteraction('sync_family', 'view')
  
  // Facebook Pixel (événement de haute valeur)
  fbPixel.fbTrackAppStoreReturn()
  
  // Hotjar
  hotjar.hjEvent('app_store_return')
}