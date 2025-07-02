// lib/constants.ts - CONSTANTES
export const APP_SCHEME = 'epilist'
export const DOMAIN = 'epilist.app'

export const STORE_URLS = {
  android: process.env.NEXT_PUBLIC_ANDROID_STORE_URL || 'https://play.google.com/store/apps/details?id=com.m2atech.epilist',
  ios: process.env.NEXT_PUBLIC_IOS_STORE_URL || 'https://apps.apple.com/app/epilist/id123456789'
}

export const API_ENDPOINTS = {
  invitation: (token: string) => `/api/invitation/${token}`,
  backend: {
    invitation: (token: string) => `/api/share/invitation/${token}`
  }
}