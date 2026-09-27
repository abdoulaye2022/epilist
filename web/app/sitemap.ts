import { MetadataRoute } from 'next'
import { routes, BASE_URL, type RouteKey } from '@/lib/routes'

// Sitemap bilingue : chaque page existe en français et en anglais,
// avec ses alternates hreflang.
export default function sitemap(): MetadataRoute.Sitemap {
  const priorities: Record<RouteKey, number> = {
    home: 1,
    download: 0.9,
    features: 0.8,
    contact: 0.7,
    help: 0.7,
    about: 0.6,
    comparison: 0.6,
    privacy: 0.3,
    terms: 0.3,
  }

  // (Next 13.5 ne supporte pas `alternates` dans le sitemap : les
  // hreflang sont déclarés dans les metadata de chaque page.)
  const entries: MetadataRoute.Sitemap = []
  for (const key of Object.keys(routes) as RouteKey[]) {
    for (const lang of ['fr', 'en'] as const) {
      entries.push({
        url: `${BASE_URL}${routes[key][lang]}`,
        lastModified: new Date(),
        changeFrequency: key === 'home' || key === 'download' ? 'weekly' : 'monthly',
        priority: priorities[key],
      })
    }
  }
  return entries
}
