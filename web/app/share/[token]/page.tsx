"use client";

// app/share/[token]/page.tsx - VERSION AMÉLIORÉE AVEC DÉTECTION D'OUVERTURE
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

export default function SharePage() {
  const params = useParams();
  const token = params.token as string;
  const [status, setStatus] = useState<"redirecting" | "fallback" | "manual">(
    "redirecting"
  );

  useEffect(() => {
    const isAndroid = /Android/i.test(navigator.userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isMobile = isAndroid || isIOS;

    const appUrl = `epilist://share/${token}`;
    const androidStoreUrl =
      "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
    const iosStoreUrl = "https://apps.apple.com/ca/app/epilist/id6748285596";

    let appOpened = false;
    let fallbackTimer: NodeJS.Timeout;

    function attemptAppOpen() {
      if (!isMobile) {
        setStatus("manual");
        return;
      }

      // Écouter les événements de visibilité pour détecter si l'app s'ouvre
      const handleVisibilityChange = () => {
        if (document.visibilityState === "hidden") {
          appOpened = true;
          clearTimeout(fallbackTimer);
        }
      };

      const handleBeforeUnload = () => {
        appOpened = true;
        clearTimeout(fallbackTimer);
      };

      // Ajouter les listeners
      document.addEventListener("visibilitychange", handleVisibilityChange);
      window.addEventListener("beforeunload", handleBeforeUnload);
      window.addEventListener("blur", handleBeforeUnload);

      // Tentative d'ouverture de l'app
      try {
        window.location.href = appUrl;
      } catch (error) {
        console.log("Erreur ouverture app:", error);
      }

      // Fallback avec délai plus long pour permettre à l'app de s'ouvrir
      fallbackTimer = setTimeout(() => {
        if (!appOpened) {
          setStatus("fallback");
          const storeUrl = isIOS ? iosStoreUrl : androidStoreUrl;
          window.location.href = storeUrl;
        }
      }, 3000); // Délai augmenté à 3 secondes

      // Nettoyage après 10 secondes
      setTimeout(() => {
        document.removeEventListener(
          "visibilitychange",
          handleVisibilityChange
        );
        window.removeEventListener("beforeunload", handleBeforeUnload);
        window.removeEventListener("blur", handleBeforeUnload);
      }, 10000);
    }

    // Délai initial très court
    const initialTimer = setTimeout(attemptAppOpen, 100);

    return () => {
      clearTimeout(initialTimer);
      clearTimeout(fallbackTimer);
    };
  }, [token]);

  const isAndroid =
    typeof navigator !== "undefined" && /Android/i.test(navigator.userAgent);
  const isIOS =
    typeof navigator !== "undefined" &&
    /iPad|iPhone|iPod/.test(navigator.userAgent);
  const androidStoreUrl =
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
  const iosStoreUrl = "https://apps.apple.com/ca/app/epilist/id6748285596";

  if (status === "manual") {
    return (
      <div
        style={{
          minHeight: "100vh",
          backgroundColor: "#f8f9fa",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: "20px",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        <div
          style={{
            backgroundColor: "white",
            padding: "40px",
            borderRadius: "16px",
            boxShadow: "0 4px 20px rgba(0,0,0,0.1)",
            textAlign: "center",
            maxWidth: "400px",
          }}
        >
          <div
            style={{
              width: "80px",
              height: "80px",
              backgroundColor: "#28a745",
              borderRadius: "50%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 20px",
              fontSize: "40px",
            }}
          >
            🛒
          </div>

          <h1
            style={{
              color: "#333",
              marginBottom: "16px",
              fontSize: "24px",
              fontWeight: "600",
            }}
          >
            Invitation EpiList
          </h1>

          <p
            style={{
              color: "#666",
              marginBottom: "30px",
              lineHeight: "1.5",
            }}
          >
            Vous avez reçu une invitation pour rejoindre une liste de courses
            partagée !
          </p>

          <a
            href={androidStoreUrl}
            style={{
              backgroundColor: "#28a745",
              color: "white",
              padding: "12px 30px",
              borderRadius: "8px",
              textDecoration: "none",
              fontWeight: "600",
              display: "inline-block",
              transition: "background-color 0.2s",
            }}
            onMouseOver={(e) =>
              (e.currentTarget.style.backgroundColor = "#218838")
            }
            onMouseOut={(e) =>
              (e.currentTarget.style.backgroundColor = "#28a745")
            }
          >
            Télécharger EpiList
          </a>
        </div>
      </div>
    );
  }

  if (status === "fallback") {
    return (
      <div
        style={{
          minHeight: "100vh",
          backgroundColor: "#f8f9fa",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: "20px",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        <div
          style={{
            backgroundColor: "white",
            padding: "30px",
            borderRadius: "12px",
            boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
            textAlign: "center",
            maxWidth: "350px",
          }}
        >
          <div
            style={{
              fontSize: "48px",
              marginBottom: "16px",
            }}
          >
            📱
          </div>

          <h2
            style={{
              color: "#333",
              marginBottom: "12px",
              fontSize: "20px",
            }}
          >
            Redirection vers le store...
          </h2>

          <p
            style={{
              color: "#666",
              fontSize: "14px",
              marginBottom: "20px",
            }}
          >
            Téléchargez EpiList pour ouvrir votre invitation
          </p>

          {/* Boutons manuels au cas où */}
          <div
            style={{ display: "flex", gap: "10px", justifyContent: "center" }}
          >
            {isIOS && (
              <a
                href={iosStoreUrl}
                style={{
                  backgroundColor: "#007AFF",
                  color: "white",
                  padding: "8px 16px",
                  borderRadius: "6px",
                  textDecoration: "none",
                  fontSize: "14px",
                }}
              >
                App Store
              </a>
            )}
            {isAndroid && (
              <a
                href={androidStoreUrl}
                style={{
                  backgroundColor: "#34A853",
                  color: "white",
                  padding: "8px 16px",
                  borderRadius: "6px",
                  textDecoration: "none",
                  fontSize: "14px",
                }}
              >
                Play Store
              </a>
            )}
          </div>
        </div>
      </div>
    );
  }

  // État de redirection (loading)
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
      <div style={{ textAlign: "center" }}>
        <div
          style={{
            width: "40px",
            height: "40px",
            border: "3px solid #f3f3f3",
            borderTop: "3px solid #28a745",
            borderRadius: "50%",
            animation: "spin 1s linear infinite",
            margin: "0 auto 16px",
          }}
        ></div>

        <p
          style={{
            color: "#666",
            fontSize: "16px",
            margin: "0",
          }}
        >
          Ouverture d'EpiList...
        </p>
      </div>

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
