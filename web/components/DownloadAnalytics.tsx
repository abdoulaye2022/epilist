"use client";

import { useEffect } from "react";
import { trackFeatureInteraction } from "@/lib/gtag";

export default function DownloadAnalytics(): null {
  useEffect(() => {
    // Détecter si l'utilisateur vient d'un app store
    const referrer = document.referrer;

    // Si l'utilisateur revient des stores
    if (
      referrer.includes("apps.apple.com") ||
      referrer.includes("play.google.com")
    ) {
      trackFeatureInteraction("sync_family", "view"); // ou une autre action appropriée
    }

    // Tracking des intentions de téléchargement au survol
    const trackDownloadIntent = (): void => {
      const downloadButtons = document.querySelectorAll(
        "[data-download-tracking]"
      );
      downloadButtons.forEach((button) => {
        button.addEventListener("mouseenter", () => {
          trackFeatureInteraction("sync_family", "hover");
        });
      });
    };

    // Attendre que le DOM soit prêt
    const timer = setTimeout(trackDownloadIntent, 1000);
    return () => clearTimeout(timer);
  }, []);

  return null; // Ce composant ne rend rien visuellement
}
