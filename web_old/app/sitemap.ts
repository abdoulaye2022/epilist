// app/sitemap.ts - SITEMAP AUTOMATIQUE
import { MetadataRoute } from 'next'

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://epilist.app'
  
  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 1,
    },
    // Note: Les pages de partage ne sont pas incluses dans le sitemap
    // car elles sont privées et temporaires
  ]
}