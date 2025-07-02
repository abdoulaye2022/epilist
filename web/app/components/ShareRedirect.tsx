// components/ShareRedirect.tsx - COMPOSANT CLIENT APP ROUTER
"use client";

import { useEffect, useState } from "react";
import type { InvitationData, DeviceInfo } from "@/types";
import { Card } from "./ui/Card";
import { Button } from "./ui/Button";
import { Spinner } from "./ui/Spinner";
import { APP_SCHEME, STORE_URLS } from "../lib/constants";

interface ShareRedirectProps {
  token: string;
  invitationData: InvitationData | null;
}

export default function ShareRedirect({
  token,
  invitationData,
}: ShareRedirectProps) {
  const [deviceInfo, setDeviceInfo] = useState<DeviceInfo>({
    isAndroid: false,
    isIOS: false,
    isMobile: false,
    isDesktop: false,
  });

  const [autoRedirectAttempted, setAutoRedirectAttempted] = useState(false);
  const [showFallback, setShowFallback] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // URLs générées
  const appUrl = `${APP_SCHEME}://share/${token}`;
  const webUrl = `https://epilist.app/share/${token}`;

  useEffect(() => {
    // Détecter la plateforme
    const userAgent = navigator.userAgent;
    const isAndroid = /Android/i.test(userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(userAgent);
    const isMobile = isAndroid || isIOS || /Mobile/i.test(userAgent);
    const isDesktop = !isMobile;

    setDeviceInfo({ isAndroid, isIOS, isMobile, isDesktop });

    // Si pas de données d'invitation, essayer de les récupérer côté client
    if (!invitationData && !error) {
      fetchInvitationData();
    } else {
      setIsLoading(false);
    }

    // Auto-redirection sur mobile
    if (isMobile && invitationData && !autoRedirectAttempted) {
      setTimeout(() => {
        tryOpenApp();
        setAutoRedirectAttempted(true);
        setTimeout(() => setShowFallback(true), 3000);
      }, 1000);
    } else if (!isMobile || error) {
      setShowFallback(true);
    }
  }, [invitationData, autoRedirectAttempted, error]);

  const fetchInvitationData = async () => {
    try {
      const response = await fetch(`/api/invitation/${token}`);
      if (!response.ok) {
        throw new Error("Invitation non trouvée");
      }
      const data = await response.json();
      // Mettre à jour avec les données reçues
      setIsLoading(false);
    } catch (err) {
      setError("Invitation invalide ou expirée");
      setIsLoading(false);
      setShowFallback(true);
    }
  };

  const tryOpenApp = () => {
    // Méthode 1: Iframe invisible
    const iframe = document.createElement("iframe");
    iframe.style.display = "none";
    iframe.src = appUrl;
    document.body.appendChild(iframe);

    setTimeout(() => {
      if (document.body.contains(iframe)) {
        document.body.removeChild(iframe);
      }
    }, 2000);

    // Méthode 2: Fallback window.location
    setTimeout(() => {
      try {
        window.location.href = appUrl;
      } catch (e) {
        console.log("Redirection vers stores");
      }
    }, 500);
  };

  const openApp = () => {
    tryOpenApp();
  };

  const openStore = () => {
    const storeUrl = deviceInfo.isIOS ? STORE_URLS.ios : STORE_URLS.android;
    window.open(storeUrl, "_blank");
  };

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(webUrl);
      // Vous pouvez ajouter un toast de notification ici
      alert("Lien copié dans le presse-papiers !");
    } catch (err) {
      // Fallback pour navigateurs plus anciens
      const textArea = document.createElement("textarea");
      textArea.value = webUrl;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      alert("Lien copié !");
    }
  };

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md w-full text-center">
          <div className="text-6xl mb-4">❌</div>
          <h1 className="text-2xl font-bold text-gray-800 mb-2">
            Invitation invalide
          </h1>
          <p className="text-gray-600 mb-6">{error}</p>
          <Button onClick={() => (window.location.href = "/")}>
            Aller à EpiList
          </Button>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-md w-full">
        {/* Logo et branding */}
        <div className="text-center mb-6">
          <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-green-600 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-4 shadow-lg">
            📱
          </div>
          <h1 className="text-2xl font-bold text-gray-800">
            Invitation EpiList
          </h1>
        </div>

        {/* Information sur l'invitation */}
        <div className="text-center mb-8">
          {isLoading ? (
            <div className="flex items-center justify-center mb-4">
              <Spinner className="mr-2" />
              <span>Chargement de l'invitation...</span>
            </div>
          ) : invitationData ? (
            <>
              <p className="text-gray-600 mb-2">
                <strong>{invitationData.ownerName}</strong> vous invite à
                collaborer sur la liste
              </p>
              <p className="text-xl font-semibold text-gray-800 mb-4">
                "{invitationData.listName}"
              </p>

              {invitationData.shoppingList && (
                <div className="flex justify-center gap-4 text-sm text-gray-500 mb-4">
                  <span>
                    📝 {invitationData.shoppingList.itemsCount || 0} articles
                  </span>
                  {invitationData.shoppingList.purchasedItemsCount > 0 && (
                    <span>
                      ✅ {invitationData.shoppingList.purchasedItemsCount}{" "}
                      achetés
                    </span>
                  )}
                </div>
              )}
            </>
          ) : (
            <p className="text-gray-600">
              Invitation à collaborer sur une liste de courses
            </p>
          )}
        </div>

        {/* Statut de redirection mobile */}
        {deviceInfo.isMobile && !showFallback && !error && (
          <div className="text-center mb-6">
            <Spinner className="mx-auto mb-4" />
            <p className="text-gray-600 mb-4">Ouverture de l'application...</p>
            <Button
              variant="outline"
              onClick={() => setShowFallback(true)}
              className="w-full"
            >
              Afficher les options
            </Button>
          </div>
        )}

        {/* Boutons d'action */}
        {showFallback && (
          <div className="space-y-4">
            <Button
              onClick={openApp}
              className="w-full bg-green-600 hover:bg-green-700"
            >
              📱 Ouvrir EpiList
            </Button>

            <div className="text-center text-sm text-gray-500 my-4">
              ou télécharger l'application
            </div>

            <div className="grid grid-cols-1 gap-2">
              {!deviceInfo.isIOS && (
                <Button
                  variant="outline"
                  onClick={() => window.open(STORE_URLS.android, "_blank")}
                  className="w-full"
                >
                  📲 Play Store
                </Button>
              )}

              {!deviceInfo.isAndroid && (
                <Button
                  variant="outline"
                  onClick={() => window.open(STORE_URLS.ios, "_blank")}
                  className="w-full"
                >
                  🍎 App Store
                </Button>
              )}
            </div>

            {deviceInfo.isDesktop && (
              <div className="border-t pt-4 mt-6">
                <div className="text-center text-sm text-gray-500 mb-4">
                  ou partager le lien
                </div>
                <Button variant="outline" onClick={copyLink} className="w-full">
                  📋 Copier le lien
                </Button>
                <p className="text-xs text-gray-500 mt-2 text-center">
                  Envoyez ce lien à vos contacts sur mobile
                </p>
              </div>
            )}
          </div>
        )}

        {/* Informations supplémentaires */}
        <div className="border-t pt-4 mt-6">
          {invitationData?.permissionDisplayName && (
            <div className="bg-gray-50 rounded-lg p-3 mb-4">
              <span className="text-sm font-medium text-gray-700">
                Permissions : {invitationData.permissionDisplayName}
              </span>
            </div>
          )}

          {deviceInfo.isMobile && (
            <p className="text-xs text-gray-500 text-center">
              Si vous avez déjà l'application, elle devrait s'ouvrir
              automatiquement. Sinon, téléchargez-la et cliquez sur "Ouvrir
              EpiList".
            </p>
          )}
        </div>
      </Card>
    </div>
  );
}
