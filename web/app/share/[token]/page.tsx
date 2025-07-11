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

    // Si pas mobile, rediriger vers store par défaut
    if (!isMobile) {
      window.location.href =
        "https://apps.apple.com/ca/app/epilist/id6748285596";
      return;
    }

    const directAppUrl = `epilist://share/${token}`;
    const storeUrl = isIOS
      ? "https://apps.apple.com/ca/app/epilist/id6748285596"
      : "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

    let appOpened = false;

    // Détecter si l'app s'ouvre
    const handleVisibilityChange = () => {
      if (document.visibilityState === "hidden") {
        appOpened = true;
      }
    };

    const handleBlur = () => {
      appOpened = true;
    };

    // Ajouter les listeners
    document.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("blur", handleBlur);

    // Tentative d'ouverture immédiate
    if (isIOS) {
      // iOS : iframe caché pour éviter l'erreur Safari
      const iframe = document.createElement("iframe");
      iframe.style.display = "none";
      iframe.style.position = "absolute";
      iframe.style.top = "-1px";
      iframe.style.left = "-1px";
      iframe.style.width = "1px";
      iframe.style.height = "1px";
      iframe.src = directAppUrl;
      document.body.appendChild(iframe);

      // Nettoyer après 1 seconde
      setTimeout(() => {
        if (iframe.parentNode) {
          iframe.parentNode.removeChild(iframe);
        }
      }, 1000);
    } else {
      // Android : redirection directe
      window.location.href = directAppUrl;
    }

    // Si l'app ne s'ouvre pas dans 800ms, rediriger vers store
    const fallbackTimer = setTimeout(() => {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      window.removeEventListener("blur", handleBlur);

      if (!appOpened) {
        window.location.href = storeUrl;
      }
    }, 800);

    // Cleanup
    return () => {
      clearTimeout(fallbackTimer);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      window.removeEventListener("blur", handleBlur);
    };
  }, [token]);

  // Page vide pendant la redirection
  return null;
}
