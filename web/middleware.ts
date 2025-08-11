import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname, search } = request.nextUrl
  const url = request.nextUrl.clone()

  // IMPORTANT: Éviter les boucles de redirection
  // Vérifier si on est déjà sur la bonne URL
  const redirectMap: Record<string, string> = {
    '/terms': '/conditions-utilisation',
    '/privacy': '/politique-confidentialite', 
    '/download': '/telecharger',
    '/features': '/fonctionnalites',
    '/help': '/aide',
    '/about': '/a-propos',
  }

  // Redirection SEULEMENT si nécessaire
  if (redirectMap[pathname]) {
    const destination = redirectMap[pathname]
    // Éviter la redirection si on est déjà sur la destination
    if (pathname !== destination) {
      return NextResponse.redirect(
        new URL(destination + search, request.url), 
        301
      )
    }
  }

  // Vérifier les trailing slashes SEULEMENT pour les pages qui existent
  const validPaths = [
    '/',
    '/telecharger',
    '/fonctionnalites', 
    '/aide',
    '/contact',
    '/a-propos',
    '/politique-confidentialite',
    '/conditions-utilisation',
    '/comparaison-applications-courses'
  ]

  if (pathname.length > 1 && pathname.endsWith('/')) {
    const pathWithoutSlash = pathname.slice(0, -1)
    // Rediriger SEULEMENT si le path sans slash est valide
    if (validPaths.includes(pathWithoutSlash)) {
      url.pathname = pathWithoutSlash
      return NextResponse.redirect(url, 301)
    }
  }

  return NextResponse.next()
}