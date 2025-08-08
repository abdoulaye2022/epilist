export const GA_TRACKING_ID = process.env.NEXT_PUBLIC_GA_ID

// Fonction helper pour vérifier si gtag est disponible
const isGtagAvailable = (): boolean => {
  return typeof window !== 'undefined' && 
         typeof (window as any).gtag === 'function' && 
         GA_TRACKING_ID !== undefined
}

// Page view tracking
export const pageview = (url: string): void => {
  if (isGtagAvailable()) {
    (window as any).gtag('config', GA_TRACKING_ID, {
      page_location: url,
    })
  }
}

// Base event function
interface EventParams {
  action: string
  category: string
  label?: string
  value?: number
}

export const event = ({ action, category, label, value }: EventParams): void => {
  if (isGtagAvailable()) {
    (window as any).gtag('event', action, {
      event_category: category,
      event_label: label,
      value: value,
    })
  }
}

// ==========================================
// ÉVÉNEMENTS SPÉCIFIQUES POUR EPILIST
// ==========================================

type Platform = 'ios' | 'android'
type DownloadSource = 
  | 'header' 
  | 'hero_main_cta' 
  | 'hero_main_cta_desktop'
  | 'cta_section'
  | 'footer'

type DemoSource = 
  | 'hero_demo_button'
  | 'features_section'
  | 'cta_section'

type FeatureName = 
  | 'sync_family'
  | 'offline_mode'
  | 'smart_suggestions'
  | 'voice_input'
  | 'shopping_history'

// Tracking des téléchargements par plateforme
export const trackAppDownload = (platform: Platform, source: DownloadSource): void => {
  event({
    action: 'app_download_click',
    category: 'app_engagement', 
    label: `${platform}_from_${source}`,
  })
  
  // Événement spécial pour les conversions GA4
  if (isGtagAvailable()) {
    (window as any).gtag('event', 'app_download', {
      platform: platform,
      source: source,
      app_name: 'EpiList'
    })
  }
  
  // Debug en développement
  if (process.env.NODE_ENV === 'development') {
    console.log('📱 Download tracked:', { platform, source })
  }
}

// Tracking pour les clics sur "Regarder la démo"
export const trackDemoView = (source: DemoSource): void => {
  event({
    action: 'demo_click',
    category: 'app_engagement',
    label: `demo_from_${source}`,
  })
  
  if (process.env.NODE_ENV === 'development') {
    console.log('▶️ Demo tracked:', { source })
  }
}

// Tracking des interactions avec les fonctionnalités
export const trackFeatureInteraction = (
  featureName: FeatureName, 
  interactionType: 'view' | 'hover' | 'click' = 'view'
): void => {
  event({
    action: 'feature_interaction',
    category: 'app_engagement',
    label: `${featureName}_${interactionType}`,
  })
  
  if (process.env.NODE_ENV === 'development') {
    console.log('🎯 Feature interaction:', { featureName, interactionType })
  }
}

// Tracking scroll depth pour mesurer l'engagement
export const trackScrollDepth = (percentage: number): void => {
  event({
    action: 'scroll_depth',
    category: 'engagement',
    label: `${percentage}%`,
    value: percentage
  })
}

// Tracking des sections visitées
export const trackSectionView = (sectionName: string): void => {
  event({
    action: 'section_view',
    category: 'engagement',
    label: sectionName,
  })
}