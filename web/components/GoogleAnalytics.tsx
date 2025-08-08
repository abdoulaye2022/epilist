"use client";

import { useEffect } from "react";
import { usePathname, useSearchParams } from "next/navigation";
import Script from "next/script";
import * as gtag from "@/lib/gtag";

interface ScrollDepthTracked {
  [key: number]: boolean;
}

export default function GoogleAnalytics(): JSX.Element | null {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Track page views
  useEffect(() => {
    if (pathname) {
      const url =
        pathname +
        (searchParams?.toString() ? `?${searchParams.toString()}` : "");
      gtag.pageview(url);
    }
  }, [pathname, searchParams]);

  // Tracking du scroll depth
  useEffect(() => {
    let scrollDepthTracked: ScrollDepthTracked = {
      25: false,
      50: false,
      75: false,
      100: false,
    };

    const handleScroll = (): void => {
      const scrollTop = window.scrollY;
      const docHeight =
        document.documentElement.scrollHeight - window.innerHeight;
      const scrollPercent = Math.round((scrollTop / docHeight) * 100);

      // Track à 25%, 50%, 75%, 100%
      Object.keys(scrollDepthTracked).forEach((depth) => {
        const depthNumber = parseInt(depth);
        if (scrollPercent >= depthNumber && !scrollDepthTracked[depthNumber]) {
          gtag.trackScrollDepth(depthNumber);
          scrollDepthTracked[depthNumber] = true;
        }
      });
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Tracking des sections en intersection
  useEffect(() => {
    const observerOptions: IntersectionObserverInit = {
      threshold: 0.5,
      rootMargin: "0px 0px -20% 0px",
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const sectionId = entry.target.id;
          if (sectionId) {
            gtag.trackSectionView(sectionId);
          }
        }
      });
    }, observerOptions);

    // Observer les sections avec des IDs
    const sections = document.querySelectorAll(
      '[id^="fonctionnalites"], [id^="avantages"], [id^="temoignages"]'
    );
    sections.forEach((section) => observer.observe(section));

    return () => observer.disconnect();
  }, []);

  // Ne charger GA4 qu'en production
  if (process.env.NODE_ENV !== "production" || !gtag.GA_TRACKING_ID) {
    return null;
  }

  return (
    <>
      <Script
        strategy="afterInteractive"
        src={`https://www.googletagmanager.com/gtag/js?id=${gtag.GA_TRACKING_ID}`}
      />
      <Script
        id="gtag-init"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '${gtag.GA_TRACKING_ID}', {
              page_location: window.location.href,
              page_title: document.title,
              send_page_view: false,
              app_name: 'EpiList',
              app_version: '1.0.0'
            });
          `,
        }}
      />
    </>
  );
}
