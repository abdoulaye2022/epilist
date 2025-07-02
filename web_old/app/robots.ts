// app/robots.ts - ROBOTS.TXT AUTOMATIQUE
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/share/*'], // Ne pas indexer les pages de partage
      },
    ],
    sitemap: 'https://epilist.app/sitemap.xml',
  }
}