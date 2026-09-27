import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Les slugs anglais historiques à la racine redirigent vers leurs vraies
// pages anglaises sous /en/... ; les slugs français restent canoniques.
const redirectMap: Record<string, string> = {
  '/terms': '/en/terms-of-use',
  '/privacy': '/en/privacy-policy',
  '/download': '/en/download',
  '/features': '/en/features',
  '/help': '/en/help',
  '/about': '/en/about',
}

const validPaths = [
  '/',
  '/telecharger',
  '/fonctionnalites',
  '/aide',
  '/contact',
  '/a-propos',
  '/politique-confidentialite',
  '/conditions-utilisation',
  '/comparaison-applications-courses',
  '/en',
  '/en/download',
  '/en/features',
  '/en/help',
  '/en/contact',
  '/en/about',
  '/en/privacy-policy',
  '/en/terms-of-use',
  '/en/grocery-app-comparison',
]

export function middleware(request: NextRequest) {
  const { pathname, search } = request.nextUrl
  const url = request.nextUrl.clone()

  if (redirectMap[pathname]) {
    return NextResponse.redirect(
      new URL(redirectMap[pathname] + search, request.url),
      301
    )
  }

  // Trailing slash -> version canonique sans slash
  if (pathname.length > 1 && pathname.endsWith('/')) {
    const pathWithoutSlash = pathname.slice(0, -1)
    if (validPaths.includes(pathWithoutSlash)) {
      url.pathname = pathWithoutSlash
      return NextResponse.redirect(url, 301)
    }
  }

  return NextResponse.next()
}
