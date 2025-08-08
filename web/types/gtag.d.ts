interface GtagEvent {
  action: string
  event_category: string
  event_label?: string
  value?: number
}

interface GtagConfig {
  page_location?: string
  page_title?: string
  send_page_view?: boolean
  app_name?: string
  app_version?: string
}

interface CustomGtagEvent {
  platform?: string
  source?: string
  app_name?: string
  [key: string]: any
}

declare global {
  interface Window {
    gtag: (
      command: 'config' | 'event' | 'js',
      targetId: string | Date,
      config?: GtagConfig | CustomGtagEvent
    ) => void
    dataLayer: unknown[]
  }
}

export {}