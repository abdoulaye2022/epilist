import "./globals.css";
import type { Metadata } from "next";
import { Suspense } from "react";
import LanguageProvider from "@/components/LanguageProvider";
import GoogleAnalytics from "@/components/GoogleAnalytics";
import FacebookPixel from "@/components/FacebookPixel";
import Hotjar from "@/components/Hotjar";
import {
  epilistAppSchema,
  epilistFAQSchema,
  epilistBusinessSchema,
} from "@/lib/schema";
import { Viewport } from "next/dist/lib/metadata/types/extra-types";

// Configuration de l'URL de base selon l'environnement
const baseUrl =
  process.env.NODE_ENV === "production"
    ? "https://epilist.app"
    : "http://localhost:3000";

// Viewport configuration (sans themeColor)
export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  // themeColor se gère dans le head avec des balises meta
};

// Metadata principal optimisé
export const metadata: Metadata = {
  metadataBase: new URL(baseUrl),

  // Titre et description optimisés SEO
  title: {
    default:
      "EpiList - Application de Liste de Courses Familiale | Synchronisation Temps Réel",
    template: "%s | EpiList",
  },
  description:
    "EpiList révolutionne vos courses avec des listes partagées en famille, synchronisation temps réel, mode hors ligne et suggestions intelligentes. 100% gratuit, sans publicité. Téléchargez maintenant !",

  keywords: [
    "liste de courses",
    "application courses",
    "courses famille",
    "liste partagée",
    "application liste courses gratuite",
    "synchronisation courses famille",
    "courses hors ligne mobile",
    "organisateur courses intelligent",
    "application courses Canada",
    "liste courses Québec",
    "courses Nouveau-Brunswick",
    "alternative AnyList",
    "meilleure app courses",
    "courses collaboratives",
  ].join(", "),

  authors: [{ name: "EpiList Team", url: "https://epilist.app" }],
  creator: "EpiList Inc.",
  publisher: "EpiList Inc.",

  robots: {
    index: true,
    follow: true,
    nocache: false,
    googleBot: {
      index: true,
      follow: true,
      noimageindex: false,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },

  openGraph: {
    type: "website",
    locale: "fr_CA",
    alternateLocale: "en_CA",
    url: baseUrl,
    siteName: "EpiList",
    title: "EpiList - L'App de Courses Familiale #1 au Canada",
    description:
      "🛒 Simplifiez vos courses ! Listes partagées, sync temps réel, mode hors ligne. 50k+ familles nous font confiance. Gratuit à vie !",
    images: [
      {
        url: "/images/og-image-main.jpg",
        width: 1200,
        height: 630,
        alt: "EpiList - Application de courses familiale avec synchronisation temps réel",
        type: "image/jpeg",
      },
      {
        url: "/images/og-image-app.jpg",
        width: 1200,
        height: 630,
        alt: "Interface EpiList - Créez et partagez vos listes de courses",
        type: "image/jpeg",
      },
    ],
  },

  twitter: {
    card: "summary_large_image",
    site: "@epilistapp",
    creator: "@epilistapp",
    title: "EpiList - App Courses Familiale 🛒",
    description:
      "Synchronisation temps réel • Mode hors ligne • 100% gratuit • 4.9⭐ sur les stores",
    images: ["/images/twitter-card-main.jpg"],
  },

  appLinks: {
    ios: {
      app_store_id: "6748285596",
      url: "https://apps.apple.com/ca/app/epilist/id6748285596?l=fr-CA",
    },
    android: {
      package: "com.m2atech.epilist",
      url: "https://play.google.com/store/apps/details?id=com.m2atech.epilist",
    },
  },

  applicationName: "EpiList",
  referrer: "origin-when-cross-origin",
  category: "lifestyle",
  classification: "Shopping & Lifestyle App",

  verification: {
    google: "VOTRE_CODE_GOOGLE_SEARCH_CONSOLE", // À remplacer
  },

  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },

  alternates: {
    canonical: baseUrl,
    languages: {
      "fr-CA": `${baseUrl}`,
      "en-CA": `${baseUrl}/en`,
    },
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr-CA">
      <head>
        {/* Theme Color pour mobile - géré manuellement */}
        <meta name="theme-color" content="#10b981" />
        <meta
          name="theme-color"
          media="(prefers-color-scheme: dark)"
          content="#064e3b"
        />

        {/* Schema.org JSON-LD */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(epilistAppSchema),
          }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(epilistFAQSchema),
          }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(epilistBusinessSchema),
          }}
        />

        {/* Preconnect pour performance */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://www.googletagmanager.com" />
        <link rel="preconnect" href="https://connect.facebook.net" />

        {/* DNS Prefetch */}
        <link rel="dns-prefetch" href="//apps.apple.com" />
        <link rel="dns-prefetch" href="//play.google.com" />

        {/* Apple Touch Icons */}
        <link
          rel="apple-touch-icon"
          sizes="180x180"
          href="/apple-touch-icon.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="32x32"
          href="/favicon-32x32.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="16x16"
          href="/favicon-16x16.png"
        />
        <link rel="manifest" href="/site.webmanifest" />

        {/* Microsoft */}
        <meta name="msapplication-TileColor" content="#10b981" />
        <meta name="msapplication-config" content="/browserconfig.xml" />
      </head>
      <body className="font-sans antialiased">
        {/* Tracking Scripts */}
        <Suspense fallback={null}>
          <GoogleAnalytics />
          <FacebookPixel />
          <Hotjar />
        </Suspense>

        {/* Application */}
        <LanguageProvider>{children}</LanguageProvider>

        {/* Skip Link pour accessibilité */}

        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-green-600 text-white px-4 py-2 rounded z-50"
        >
          Aller au contenu principal
        </a>
      </body>
    </html>
  );
}
