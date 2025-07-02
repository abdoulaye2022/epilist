// app/api/assetlinks/route.ts - ANDROID APP LINKS API
import { NextResponse } from 'next/server'

export async function GET() {
  const assetLinks = [
    {
      "relation": ["delegate_permission/common.handle_all_urls"],
      "target": {
        "namespace": "android_app",
        "package_name": process.env.NEXT_PUBLIC_ANDROID_PACKAGE || "com.m2atech.epilist",
        "sha256_cert_fingerprints": [
          // 🔄 Remplacez par vos vraies empreintes SHA256
          process.env.ANDROID_SHA256_RELEASE || "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX",
          // Empreinte de debug (optionnel)
          process.env.ANDROID_SHA256_DEBUG || "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
        ].filter(Boolean) // Filtrer les valeurs vides
      }
    }
  ]

  return NextResponse.json(assetLinks, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=86400', // Cache 24h
    },
  })
}