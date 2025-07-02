// lib/api.ts - CLIENT API
import type { InvitationData, ApiResponse } from '@/types'

export async function getInvitationData(token: string): Promise<InvitationData> {
  const backendUrl = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL
  
  if (!backendUrl) {
    throw new Error('URL du backend non configurée')
  }
  
  const response = await fetch(`${backendUrl}/api/share/invitation/${token}`, {
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'EpiList-Web/1.0',
    },
    next: { revalidate: 0 }, // Pas de cache pour les invitations
  })
  
  if (!response.ok) {
    throw new Error(`Invitation non trouvée: ${response.status}`)
  }
  
  const data: ApiResponse<InvitationData> = await response.json()
  
  if (!data.success || !data.data) {
    throw new Error(data.error || 'Erreur lors de la récupération des données')
  }
  
  return data.data
}