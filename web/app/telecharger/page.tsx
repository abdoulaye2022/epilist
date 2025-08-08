import DownloadContent from "@/components/DownloadContent";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Télécharger EpiList Gratuit - App Liste Courses iOS & Android",
  description:
    "📱 Téléchargez EpiList GRATUITEMENT ! App #1 au Canada pour listes de courses familiales. iOS App Store & Google Play. Synchronisation temps réel, mode hors ligne.",
  keywords:
    "télécharger EpiList, app liste courses gratuite, télécharger application courses, EpiList iOS Android, app courses famille Canada",

  openGraph: {
    title: "📱 Télécharger EpiList - App Courses Familiale Gratuite",
    description:
      "App Store & Google Play • 4.9⭐ • 50k+ familles • Gratuit à vie • Sync temps réel",
    url: "https://epilist.app/telecharger",
    images: [
      {
        url: "/images/og-download.jpg",
        width: 1200,
        height: 630,
        alt: "Télécharger EpiList sur App Store et Google Play",
      },
    ],
  },

  alternates: {
    canonical: "https://epilist.app/telecharger",
  },
};

export default function TelechargerPage() {
  return <DownloadContent />;
}
