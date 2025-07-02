// app/layout.tsx
import "./globals.css";

export const metadata = {
  title: "EpiList - Vos listes de courses partagées",
  description:
    "Créez et partagez vos listes de courses facilement avec EpiList",
  keywords: ["liste de courses", "épicerie", "partage", "mobile", "app"],
  authors: [{ name: "EpiList" }],
  metadataBase: new URL("https://epilist.app"),
  openGraph: {
    title: "EpiList - Vos listes de courses partagées",
    description:
      "Créez et partagez vos listes de courses facilement avec EpiList",
    url: "https://epilist.app",
    siteName: "EpiList",
    type: "website",
    images: [
      {
        url: "/logo.png",
        width: 1200,
        height: 630,
        alt: "EpiList Logo",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "EpiList - Vos listes de courses partagées",
    description:
      "Créez et partagez vos listes de courses facilement avec EpiList",
    images: ["/logo.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
