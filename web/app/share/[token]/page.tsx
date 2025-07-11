"use client";

import { useParams } from "next/navigation";
import { useEffect } from "react";

export default function SharePage() {
  const params = useParams();
  const token = params.token as string;

  useEffect(() => {
    const isAndroid = /Android/i.test(navigator.userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isMobile = isAndroid || isIOS;

    if (token) {
      if (!isMobile) {
        window.location.href =
          "https://apps.apple.com/ca/app/epilist/id6748285596";
        return;
      }

      // Tentative d'ouverture de l'app
      const appUrl = `epilist://share/${token}`;
      window.location.href = appUrl;

      // Fallback vers le store après 3 secondes
      const fallbackTimeout = setTimeout(() => {
        window.location.href = isIOS
          ? "https://apps.apple.com/ca/app/epilist/id6748285596"
          : "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
      }, 3000);

      return () => clearTimeout(fallbackTimeout);
    }
  }, [token]);

  return null;
}
