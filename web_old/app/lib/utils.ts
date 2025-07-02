// lib/utils.ts - UTILITAIRES
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function detectDevice() {
  if (typeof window === 'undefined') {
    return {
      isAndroid: false,
      isIOS: false,
      isMobile: false,
      isDesktop: true
    }
  }
  
  const userAgent = navigator.userAgent
  const isAndroid = /Android/i.test(userAgent)
  const isIOS = /iPad|iPhone|iPod/.test(userAgent)
  const isMobile = isAndroid || isIOS || /Mobile/i.test(userAgent)
  const isDesktop = !isMobile
  
  return { isAndroid, isIOS, isMobile, isDesktop }
}

export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}