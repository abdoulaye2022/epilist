"use client";

import { useEffect, useState } from "react";
import {
  trackHighEngagementUnified,
  trackAppStoreReturnUnified,
} from "@/lib/unified-tracking";
import * as fbPixel from "@/lib/facebook-pixel";

export default function AdvancedTracking(): null {
  const [highEngagementTracked, setHighEngagementTracked] = useState(false);

  useEffect(() => {
    // Détecter retour depuis app stores
    const referrer = document.referrer;
    if (
      referrer.includes("apps.apple.com") ||
      referrer.includes("play.google.com")
    ) {
      trackAppStoreReturnUnified();
    }

    // Tracking engagement élevé (temps sur site + scroll)
    const trackEngagement = () => {
      const scrollPercent = Math.round(
        (window.scrollY /
          (document.documentElement.scrollHeight - window.innerHeight)) *
          100
      );

      const timeOnSite = Date.now() - performance.timing.navigationStart;

      // Engagement élevé : >75% scroll + >30 secondes sur site
      if (scrollPercent > 75 && timeOnSite > 30000 && !highEngagementTracked) {
        trackHighEngagementUnified();
        setHighEngagementTracked(true);
      }
    };

    // Tracking des intentions (survol boutons)
    const trackIntentions = () => {
      const downloadButtons = document.querySelectorAll(
        "[data-download-tracking]"
      );
      downloadButtons.forEach((button) => {
        button.addEventListener("mouseenter", () => {
          fbPixel.fbEvent("AddToCart", {
            content_type: "app_download_intent",
            content_name: "EpiList App",
          });
        });
      });
    };

    // Événements
    window.addEventListener("scroll", trackEngagement);
    const timer = setTimeout(trackIntentions, 2000);

    return () => {
      window.removeEventListener("scroll", trackEngagement);
      clearTimeout(timer);
    };
  }, [highEngagementTracked]);

  return null;
}
