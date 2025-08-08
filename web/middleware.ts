import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Redirections SEO pour anciennes URLs
  const { pathname } = request.nextUrl
  
  // Redirection /terms → /conditions-utilisation
  if (pathname === '/terms') {
    return NextResponse.redirect(new URL('/conditions-utilisation', request.url), 301)
  }
  
  // Redirection /privacy → /politique-confidentialite
  if (pathname === '/privacy') {
    return NextResponse.redirect(new URL('/politique-confidentialite', request.url), 301)
  }
  
  // Redirection /download → /telecharger
  if (pathname === '/download') {
    return NextResponse.redirect(new URL('/telecharger', request.url), 301)
  }
  
  // Redirection /features → /fonctionnalites
  if (pathname === '/features') {
    return NextResponse.redirect(new URL('/fonctionnalites', request.url), 301)
  }
  
  // Redirection /help → /aide
  if (pathname === '/help') {
    return NextResponse.redirect(new URL('/aide', request.url), 301)
  }
  
  // Redirection /about → /a-propos
  if (pathname === '/about') {
    return NextResponse.redirect(new URL('/a-propos', request.url), 301)
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
}