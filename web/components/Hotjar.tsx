"use client";

import { useEffect } from "react";
import Script from "next/script";
import * as hotjar from "@/lib/hotjar";

export default function Hotjar(): JSX.Element | null {
  // Configuration d'attributs utilisateur basés sur le comportement
  useEffect(() => {
    const setupUserAttributes = () => {
      // Détecter le type d'appareil
      const isMobile =
        /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
          navigator.userAgent
        );
      const platform = /iPad|iPhone|iPod/.test(navigator.userAgent)
        ? "ios"
        : /Android/.test(navigator.userAgent)
        ? "android"
        : "desktop";

      // Détecter la langue
      const language = navigator.language || "en";

      // Identifier l'utilisateur avec des attributs
      const userId = `epilist_${Date.now()}_${Math.random().toString(36)}`;
      hotjar.hjIdentify(userId, {
        device_type: isMobile ? "mobile" : "desktop",
        platform: platform,
        language: language,
        referrer: document.referrer || "direct",
        page_url: window.location.href,
      });
    };

    // Attendre que Hotjar soit chargé
    const timer = setTimeout(setupUserAttributes, 3000);
    return () => clearTimeout(timer);
  }, []);

  // Ne charger qu'en production ou en debug
  const shouldLoadHJ =
    hotjar.HOTJAR_ID &&
    (process.env.NODE_ENV === "production" ||
      process.env.NEXT_PUBLIC_DEBUG_GA4 === "true");

  if (!shouldLoadHJ) {
    console.log("🚫 Hotjar not loaded:", {
      hasId: !!hotjar.HOTJAR_ID,
      env: process.env.NODE_ENV,
    });
    return null;
  }

  console.log("🔥 Loading Hotjar...", hotjar.HOTJAR_ID);

  return (
    <Script
      id="hotjar"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `
          (function(h,o,t,j,a,r){
            h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
            h._hjSettings={hjid:${hotjar.HOTJAR_ID},hjsv:6};
            a=o.getElementsByTagName('head')[0];
            r=o.createElement('script');r.async=1;
            r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
            a.appendChild(r);
          })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
          console.log('✅ Hotjar initialized');
        `,
      }}
    />
  );
}
