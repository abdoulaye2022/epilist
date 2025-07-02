// types/index.ts - TYPES TYPESCRIPT
export interface InvitationData {
  token: string
  listName: string
  ownerName: string
  ownerEmail: string
  permission: string
  permissionDisplayName: string
  expiresAt: string
  isExpired: boolean
  createdAt: string
  shoppingList?: {
    id: number
    name: string
    itemsCount: number
    purchasedItemsCount: number
    totalPrice: number
    createdAt: string
  } | null
  shareUrls: {
    app: string
    android_store: string
    ios_store: string
  }
}

export interface DeviceInfo {
  isAndroid: boolean
  isIOS: boolean
  isMobile: boolean
  isDesktop: boolean
}

export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
}