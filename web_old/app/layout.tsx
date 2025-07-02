import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "EpiList - Vos listes de courses partagées",
    template: "%s | EpiList",
  },
  description:
    "Créez et partagez vos listes de courses en famille ou entre amis avec EpiList",
  keywords: [
    "liste de courses",
    "partage",
    "famille",
    "épicerie",
    "collaboration",
  ],
  authors: [{ name: "EpiList Team" }],
  creator: "EpiList",
  publisher: "EpiList",
  metadataBase: new URL("https://epilist.app"),
  alternates: {
    canonical: "/",
  },
  openGraph: {
    type: "website",
    locale: "fr_FR",
    url: "https://epilist.app",
    title: "EpiList - Vos listes de courses partagées",
    description:
      "Créez et partagez vos listes de courses en famille ou entre amis",
    siteName: "EpiList",
    images: [
      {
        url: "/logo.png",
        width: 1200,
        height: 630,
        alt: "EpiList - Listes de courses partagées",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "EpiList - Vos listes de courses partagées",
    description:
      "Créez et partagez vos listes de courses en famille ou entre amis",
    images: ["/logo.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  icons: {
    icon: "/favicon.ico",
    shortcut: "/favicon.ico",
    apple: "/apple-touch-icon.png",
  },
  manifest: "/manifest.json",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr" className={inter.className}>
      <head>
        {/* Preconnect pour optimiser les performances */}
        <link rel="preconnect" href="https://play.google.com" />
        <link rel="preconnect" href="https://apps.apple.com" />

        {/* Viewport optimisé pour mobile */}
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1, viewport-fit=cover"
        />

        {/* Theme color pour PWA */}
        <meta name="theme-color" content="#4CAF50" />
        <meta name="msapplication-TileColor" content="#4CAF50" />

        {/* Apple Web App */}
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
        <meta name="apple-mobile-web-app-title" content="EpiList" />
      </head>
      <body className="min-h-screen bg-gradient-to-br from-blue-500 via-purple-500 to-purple-600 antialiased">
        {children}
      </body>
    </html>
  );
}
