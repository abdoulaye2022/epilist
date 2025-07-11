"use client";

import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

export default function SharePage() {
  const params = useParams();
  const token = params.token as string;
  const [status, setStatus] = useState<
    "checking" | "opening_app" | "redirecting_store" | "manual"
  >("checking");
  const [countdown, setCountdown] = useState(2);

  useEffect(() => {
    const isAndroid = /Android/i.test(navigator.userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isMobile = isAndroid || isIOS;

    const directAppUrl = `epilist://share/${token}`;
    const androidStoreUrl =
      "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
    const iosStoreUrl = "https://apps.apple.com/ca/app/epilist/id6748285596";

    let appOpened = false;
    let detectionTimeout: NodeJS.Timeout;

    function attemptAppOpen() {
      if (!isMobile) {
        setStatus("manual");
        return;
      }

      console.log("🔍 Tentative d'ouverture de l'app...");
      setStatus("opening_app");

      // Détection par événements de visibilité
      const handleVisibilityChange = () => {
        if (document.visibilityState === "hidden") {
          console.log("✅ App ouverte avec succès");
          appOpened = true;
          clearTimeout(detectionTimeout);
        }
      };

      const handleBlur = () => {
        console.log("✅ App ouverte (blur détecté)");
        appOpened = true;
        clearTimeout(detectionTimeout);
      };

      const handlePageHide = () => {
        console.log("✅ App ouverte (pagehide détecté)");
        appOpened = true;
        clearTimeout(detectionTimeout);
      };

      // Ajouter les listeners
      document.addEventListener("visibilitychange", handleVisibilityChange);
      window.addEventListener("blur", handleBlur);
      window.addEventListener("pagehide", handlePageHide);

      // Tentative d'ouverture de l'app de manière sécurisée
      try {
        if (isIOS) {
          // Sur iOS : créer un iframe caché pour éviter l'erreur Safari
          const iframe = document.createElement("iframe");
          iframe.style.display = "none";
          iframe.style.position = "absolute";
          iframe.style.top = "-1px";
          iframe.style.left = "-1px";
          iframe.style.width = "1px";
          iframe.style.height = "1px";
          iframe.src = directAppUrl;
          document.body.appendChild(iframe);

          // Nettoyer l'iframe après usage
          setTimeout(() => {
            if (iframe.parentNode) {
              iframe.parentNode.removeChild(iframe);
            }
          }, 2000);
        } else {
          // Sur Android : tentative directe
          window.location.href = directAppUrl;
        }
      } catch (error) {
        console.log("⚠️ Erreur lors de la tentative:", error);
        redirectToStore();
        return;
      }

      // Si l'app ne s'ouvre pas dans 1.5 seconde, rediriger vers le store
      detectionTimeout = setTimeout(() => {
        // Nettoyer les listeners
        document.removeEventListener(
          "visibilitychange",
          handleVisibilityChange
        );
        window.removeEventListener("blur", handleBlur);
        window.removeEventListener("pagehide", handlePageHide);

        if (!appOpened) {
          console.log("❌ App non installée, redirection vers le store");
          redirectToStore();
        }
      }, 1500);
    }

    function redirectToStore() {
      setStatus("redirecting_store");
      const storeUrl = isIOS ? iosStoreUrl : androidStoreUrl;

      // Démarrer le countdown
      let count = 2;
      setCountdown(count);

      const countdownInterval = setInterval(() => {
        count--;
        setCountdown(count);

        if (count <= 0) {
          clearInterval(countdownInterval);
          console.log("🏪 Redirection vers:", storeUrl);
          window.location.href = storeUrl;
        }
      }, 1000);
    }

    // Démarrer immédiatement
    const startTimer = setTimeout(attemptAppOpen, 100);

    return () => {
      clearTimeout(startTimer);
      clearTimeout(detectionTimeout);
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

  // Mode manuel (desktop ou webview)
  if (status === "manual") {
    return (
      <div
        style={{
          minHeight: "100vh",
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
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
            padding: "40px",
            borderRadius: "20px",
            boxShadow: "0 20px 40px rgba(0,0,0,0.1)",
            textAlign: "center",
            maxWidth: "400px",
            width: "100%",
          }}
        >
          <div
            style={{
              width: "80px",
              height: "80px",
              background: "linear-gradient(135deg, #4CAF50, #45a049)",
              borderRadius: "20px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 24px",
              fontSize: "40px",
              color: "white",
            }}
          >
            🛒
          </div>

          <h1
            style={{
              color: "#333",
              marginBottom: "16px",
              fontSize: "28px",
              fontWeight: "700",
            }}
          >
            Invitation EpiList
          </h1>

          <p
            style={{
              color: "#666",
              marginBottom: "32px",
              lineHeight: "1.6",
              fontSize: "16px",
            }}
          >
            Vous avez reçu une invitation pour rejoindre une liste de courses
            partagée !
          </p>

          <div
            style={{ display: "flex", flexDirection: "column", gap: "16px" }}
          >
            <a
              href={`epilist://share/${token}`}
              style={{
                background: "linear-gradient(135deg, #4CAF50, #45a049)",
                color: "white",
                padding: "16px 32px",
                borderRadius: "14px",
                textDecoration: "none",
                fontWeight: "600",
                fontSize: "16px",
                transition: "all 0.3s ease",
                boxShadow: "0 4px 15px rgba(76, 175, 80, 0.3)",
              }}
              onMouseOver={(e) => {
                e.currentTarget.style.transform = "translateY(-2px)";
                e.currentTarget.style.boxShadow =
                  "0 6px 20px rgba(76, 175, 80, 0.4)";
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow =
                  "0 4px 15px rgba(76, 175, 80, 0.3)";
              }}
            >
              📱 Ouvrir dans EpiList
            </a>

            <a
              href={isIOS ? iosStoreUrl : androidStoreUrl}
              style={{
                background: "linear-gradient(135deg, #007AFF, #0056CC)",
                color: "white",
                padding: "16px 32px",
                borderRadius: "14px",
                textDecoration: "none",
                fontWeight: "600",
                fontSize: "16px",
                transition: "all 0.3s ease",
                boxShadow: "0 4px 15px rgba(0, 122, 255, 0.3)",
              }}
              onMouseOver={(e) => {
                e.currentTarget.style.transform = "translateY(-2px)";
                e.currentTarget.style.boxShadow =
                  "0 6px 20px rgba(0, 122, 255, 0.4)";
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.transform = "translateY(0)";
                e.currentTarget.style.boxShadow =
                  "0 4px 15px rgba(0, 122, 255, 0.3)";
              }}
            >
              📥 Télécharger EpiList
            </a>
          </div>
        </div>
      </div>
    );
  }

  // Redirection vers le store
  if (status === "redirecting_store") {
    return (
      <div
        style={{
          minHeight: "100vh",
          background: "linear-gradient(135deg, #FF6B6B, #FF8E53)",
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
            padding: "40px",
            borderRadius: "20px",
            boxShadow: "0 20px 40px rgba(0,0,0,0.1)",
            textAlign: "center",
            maxWidth: "380px",
            width: "100%",
          }}
        >
          <div
            style={{
              width: "100px",
              height: "100px",
              background: "linear-gradient(135deg, #FF6B6B, #FF8E53)",
              borderRadius: "50%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 24px",
              fontSize: "50px",
              color: "white",
            }}
          >
            🏪
          </div>

          <h2
            style={{
              color: "#333",
              marginBottom: "16px",
              fontSize: "24px",
              fontWeight: "700",
            }}
          >
            App non installée
          </h2>

          <p
            style={{
              color: "#666",
              fontSize: "16px",
              marginBottom: "24px",
              lineHeight: "1.5",
            }}
          >
            EpiList n'est pas installé. Redirection automatique vers le store...
          </p>

          <div
            style={{
              background: "linear-gradient(135deg, #FFE082, #FFCC02)",
              borderRadius: "12px",
              padding: "20px",
              marginBottom: "24px",
            }}
          >
            <div
              style={{
                fontSize: "48px",
                fontWeight: "bold",
                color: "#FF6B6B",
                marginBottom: "8px",
              }}
            >
              {countdown}
            </div>
            <p
              style={{
                margin: 0,
                fontSize: "14px",
                color: "#B8860B",
                fontWeight: "600",
              }}
            >
              seconde{countdown > 1 ? "s" : ""}
            </p>
          </div>

          <a
            href={isIOS ? iosStoreUrl : androidStoreUrl}
            style={{
              background: isIOS
                ? "linear-gradient(135deg, #007AFF, #0056CC)"
                : "linear-gradient(135deg, #34A853, #2E7D32)",
              color: "white",
              padding: "16px 32px",
              borderRadius: "14px",
              textDecoration: "none",
              fontSize: "16px",
              fontWeight: "600",
              transition: "all 0.3s ease",
              display: "inline-block",
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = "translateY(-2px)";
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = "translateY(0)";
            }}
          >
            📥 {isIOS ? "App Store" : "Play Store"}
          </a>
        </div>
      </div>
    );
  }

  // États de chargement (checking et opening_app)
  return (
    <div
      style={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "system-ui, -apple-system, sans-serif",
      }}
    >
      <div style={{ textAlign: "center", color: "white" }}>
        <div
          style={{
            width: "60px",
            height: "60px",
            border: "4px solid rgba(255,255,255,0.3)",
            borderTop: "4px solid white",
            borderRadius: "50%",
            animation: "spin 1s linear infinite",
            margin: "0 auto 32px",
          }}
        ></div>

        <h2
          style={{
            fontSize: "24px",
            fontWeight: "600",
            marginBottom: "12px",
            color: "white",
          }}
        >
          {status === "checking" ? "Vérification..." : "Ouverture d'EpiList..."}
        </h2>

        <p
          style={{
            fontSize: "16px",
            margin: 0,
            opacity: 0.9,
            lineHeight: "1.5",
          }}
        >
          {status === "opening_app"
            ? "Tentative d'ouverture de l'application..."
            : "Détection de l'application EpiList..."}
        </p>

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
    </div>
  );
}
