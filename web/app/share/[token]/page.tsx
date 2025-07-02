"use client";

// app/share/[token]/page.tsx - VERSION REDIRECTION INVISIBLE ET INSTANTANÉE
import { useParams } from "next/navigation";
import { useEffect } from "react";

export default function SharePage() {
  const params = useParams();
  const token = params.token as string;

  useEffect(() => {
    const isAndroid = /Android/i.test(navigator.userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isMobile = isAndroid || isIOS;

    const appUrl = `epilist://share/${token}`;
    const androidStoreUrl =
      "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
    const iosStoreUrl = "https://apps.apple.com/app/epilist/id123456789";

    function instantRedirect() {
      if (isMobile) {
        // Tentative d'ouverture de l'app
        window.location.href = appUrl;

        // Fallback immédiat vers le store (si l'app ne s'ouvre pas)
        setTimeout(() => {
          const storeUrl = isIOS ? iosStoreUrl : androidStoreUrl;
          window.location.href = storeUrl;
        }, 1500); // Délai très court
      } else {
        // Sur desktop, rediriger vers Play Store par défaut
        window.location.href = androidStoreUrl;
      }
    }

    // Redirection immédiate dès que le composant est monté
    const timer = setTimeout(instantRedirect, 50);

    return () => clearTimeout(timer);
  }, [token]);

  // Interface ultra-minimale (à peine visible)
  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#ffffff",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      {/* Spinner très discret */}
      <div
        style={{
          width: "24px",
          height: "24px",
          border: "2px solid #f3f3f3",
          borderTop: "2px solid #28a745",
          borderRadius: "50%",
          animation: "spin 0.8s linear infinite",
        }}
      ></div>

      <style jsx>{`
        @keyframes spin {
          0% {
            transform: rotate(0deg);
          }
          100% {
            transform: rotate(360deg);
          }
        }
      `}</style>
    </div>
  );
}
