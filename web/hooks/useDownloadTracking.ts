'use client'

import { useCallback } from 'react'
import { trackAppDownload, trackDemoView } from '@/lib/gtag'

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

interface UseDownloadTrackingReturn {
  trackDownload: (platform: Platform, source: DownloadSource, additionalData?: Record<string, any>) => void
  trackDemo: (source: DemoSource, additionalData?: Record<string, any>) => void
}

export const useDownloadTracking = (): UseDownloadTrackingReturn => {
  const trackDownload = useCallback((
    platform: Platform, 
    source: DownloadSource, 
    additionalData: Record<string, any> = {}
  ) => {
    trackAppDownload(platform, source)
    
    // Debug en développement
    if (process.env.NODE_ENV === 'development') {
      console.log('📱 Download tracked:', { platform, source, ...additionalData })
    }
  }, [])

  const trackDemo = useCallback((
    source: DemoSource, 
    additionalData: Record<string, any> = {}
  ) => {
    trackDemoView(source)
    
    if (process.env.NODE_ENV === 'development') {
      console.log('▶️ Demo tracked:', { source, ...additionalData })
    }
  }, [])

  return { trackDownload, trackDemo }
}