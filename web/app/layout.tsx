import "./globals.css";
import type { Metadata } from "next";
// Supprimez l'import Inter de Google Fonts
// import { Inter } from 'next/font/google';
import LanguageProvider from "@/components/LanguageProvider";

// Remplacez par une police système
const systemFont = {
  className: "font-system", // Vous pouvez utiliser une classe CSS personnalisée
};

// Configuration de l'URL de base selon l'environnement
const baseUrl =
  process.env.NODE_ENV === "production"
    ? "https://epilist.app"
    : "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(baseUrl),
  title: "EpiList - Simplifiez vos courses",
  description:
    "L'application mobile qui révolutionne votre façon de faire les courses. Créez, partagez et gérez vos listes en famille.",
  keywords:
    "courses, épicerie, liste, famille, mobile, app, partage, organisation",
  authors: [{ name: "EpiList Team" }],

  // Open Graph
  openGraph: {
    title: "EpiList - Simplifiez vos courses",
    description:
      "L'application mobile qui révolutionne votre façon de faire les courses.",
    type: "website",
    locale: "fr_FR",
    url: "/",
    siteName: "EpiList",
    images: [
      {
        url: "/images/og-image.jpg",
        width: 1200,
        height: 630,
        alt: "EpiList - Application de listes de courses",
      },
    ],
  },

  // Twitter
  twitter: {
    card: "summary_large_image",
    title: "EpiList - Simplifiez vos courses",
    description:
      "L'application mobile qui révolutionne votre façon de faire les courses.",
    images: ["/images/twitter-card.jpg"],
    creator: "@epilistapp",
  },

  // Robots
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

  // Informations supplémentaires
  applicationName: "EpiList",
  referrer: "origin-when-cross-origin",
  creator: "EpiList Team",
  publisher: "EpiList Inc.",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr">
      <body className="font-sans antialiased">
        <LanguageProvider>{children}</LanguageProvider>
      </body>
    </html>
  );
}
