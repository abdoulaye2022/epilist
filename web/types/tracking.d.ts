interface FacebookPixelEvent {
  eventName: string
  parameters?: Record<string, any>
}

interface HotjarAPI {
  hj: (command: string, ...args: any[]) => void
}

declare global {
  interface Window {
    fbq: (command: string, ...args: any[]) => void
    _fbq: any
    hj: (command: string, ...args: any[]) => void
    _hjSettings: { hjid: number; hjsv: number }
  }
}

export {}