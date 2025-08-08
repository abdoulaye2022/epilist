"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import Script from "next/script";
import * as fbPixel from "@/lib/facebook-pixel";

export default function FacebookPixel(): JSX.Element | null {
  const pathname = usePathname();

  // Track page views lors des changements de route
  useEffect(() => {
    fbPixel.fbPageView();
  }, [pathname]);

  // Ne charger qu'en production ou en debug
  const shouldLoadFB =
    fbPixel.FACEBOOK_PIXEL_ID &&
    (process.env.NODE_ENV === "production" ||
      process.env.NEXT_PUBLIC_DEBUG_GA4 === "true");

  if (!shouldLoadFB) {
    console.log("🚫 Facebook Pixel not loaded:", {
      hasId: !!fbPixel.FACEBOOK_PIXEL_ID,
      env: process.env.NODE_ENV,
    });
    return null;
  }

  console.log("📘 Loading Facebook Pixel...", fbPixel.FACEBOOK_PIXEL_ID);

  return (
    <>
      <Script
        id="facebook-pixel"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `
            !function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
            if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
            n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];
            s.parentNode.insertBefore(t,s)}(window, document,'script',
            'https://connect.facebook.net/en_US/fbevents.js');
            fbq('init', '${fbPixel.FACEBOOK_PIXEL_ID}');
            fbq('track', 'PageView');
            console.log('✅ Facebook Pixel initialized');
          `,
        }}
      />
      <noscript>
        <img
          height="1"
          width="1"
          style={{ display: "none" }}
          src={`https://www.facebook.com/tr?id=${fbPixel.FACEBOOK_PIXEL_ID}&ev=PageView&noscript=1`}
        />
      </noscript>
    </>
  );
}
