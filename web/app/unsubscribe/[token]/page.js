// app/unsubscribe/[token]/page.js (App Router Next.js 13+)

"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import axios from "axios";

export default function UnsubscribePage() {
  const params = useParams();
  const token = params.token;

  const [status, setStatus] = useState("loading"); // loading, success, error, already_unsubscribed
  const [message, setMessage] = useState("");
  const [userEmail, setUserEmail] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    if (token) {
      handleUnsubscribe();
    }
  }, [token]);

  const handleUnsubscribe = async () => {
    if (!token) {
      setStatus("error");
      setMessage("Token de désabonnement manquant");
      return;
    }

    setIsProcessing(true);

    try {
      // ✅ CORRECTION: Utiliser la bonne URL de l'API avec le bon endpoint
      const response = await axios.get(
        `${
          process.env.NEXT_PUBLIC_API_URL ||
          "https://m2atodev.com/api.epilist/public"
        }/unsubscribe/${token}`,
        {
          timeout: 10000,
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
        }
      );

      // ✅ GESTION DE LA RÉPONSE SELON VOTRE API
      if (response.data.success) {
        if (response.data.data?.already_unsubscribed) {
          setStatus("already_unsubscribed");
          setMessage(
            response.data.message ||
              "Vous êtes déjà désabonné des emails marketing d'EpiList."
          );
        } else {
          setStatus("success");
          setMessage(
            response.data.message ||
              "Désabonnement effectué avec succès ! Vous ne recevrez plus nos emails marketing."
          );
          setUserEmail(response.data.data?.user_email || "");
        }
      } else {
        throw new Error(response.data.message || "Erreur inconnue");
      }
    } catch (error) {
      console.error("Erreur de désabonnement:", error);

      setStatus("error");

      // ✅ GESTION D'ERREURS SELON VOTRE API
      if (error.response?.status === 404) {
        setMessage("Lien de désabonnement invalide ou expiré.");
      } else if (error.response?.status === 400) {
        setMessage("Token de désabonnement invalide.");
      } else if (error.response?.status === 410) {
        // Token déjà utilisé
        setMessage("Ce lien de désabonnement a déjà été utilisé.");
      } else if (error.code === "ECONNABORTED") {
        setMessage("Délai d'attente dépassé. Veuillez réessayer.");
      } else if (error.code === "ERR_NETWORK") {
        setMessage("Erreur de connexion. Vérifiez votre connexion internet.");
      } else {
        setMessage(
          error.response?.data?.message ||
            error.message ||
            "Une erreur est survenue lors du désabonnement. Veuillez réessayer plus tard."
        );
      }
    } finally {
      setIsProcessing(false);
    }
  };

  const retryUnsubscribe = () => {
    setStatus("loading");
    setMessage("");
    handleUnsubscribe();
  };

  return (
    <>
      <title>Désabonnement - EpiList</title>
      <meta
        name="description"
        content="Désabonnement des emails marketing EpiList"
      />
      <meta name="robots" content="noindex, nofollow" />

      <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-100 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-white rounded-2xl shadow-xl overflow-hidden">
          {/* En-tête avec logo */}
          <div className="bg-gradient-to-r from-emerald-600 to-green-600 px-6 py-8 text-center">
            <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto mb-4">
              <img
                src="https://m2atodev.com/api.epilist/public/app_logo.png"
                alt="EpiList Logo"
                className="w-12 h-12 rounded-lg"
                onError={(e) => {
                  e.target.style.display = "none";
                  e.target.nextElementSibling.style.display = "flex";
                }}
              />
              {/* Fallback emoji si l'image ne charge pas */}
              <span className="text-2xl hidden">🛒</span>
            </div>
            <h1 className="text-2xl font-bold text-white">EpiList</h1>
            <p className="text-emerald-100 mt-2">
              Gestion de vos préférences email
            </p>
          </div>

          {/* Contenu principal */}
          <div className="p-6">
            {/* État de chargement */}
            {status === "loading" && (
              <div className="text-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mx-auto mb-4"></div>
                <h2 className="text-xl font-semibold text-gray-800 mb-2">
                  {isProcessing ? "Traitement en cours..." : "Chargement..."}
                </h2>
                <p className="text-gray-600">
                  Nous traitons votre demande de désabonnement.
                </p>
              </div>
            )}

            {/* Succès */}
            {status === "success" && (
              <div className="text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    className="w-8 h-8 text-green-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
                <h2 className="text-xl font-semibold text-gray-800 mb-3">
                  ✅ Désabonnement confirmé
                </h2>
                <p className="text-gray-600 mb-4">{message}</p>

                {userEmail && (
                  <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                    <p className="text-sm text-green-800">
                      <strong>Email:</strong> {userEmail}
                    </p>
                  </div>
                )}

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
                  <h3 className="font-semibold text-blue-800 mb-2">
                    📧 Ce que cela signifie :
                  </h3>
                  <ul className="text-sm text-blue-700 space-y-1 text-left">
                    <li>
                      • Vous ne recevrez plus d'emails sur les nouvelles
                      fonctionnalités
                    </li>
                    <li>• Aucune communication marketing ou promotionnelle</li>
                    <li>
                      • Vous continuerez à recevoir les emails importants
                      (sécurité, compte)
                    </li>
                    <li>• Votre compte EpiList reste actif et fonctionnel</li>
                  </ul>
                </div>

                <div className="space-y-3">
                  <a
                    href="https://epilist.app"
                    className="block w-full bg-emerald-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-emerald-700 transition-colors text-center"
                  >
                    Retour à EpiList
                  </a>

                  <p className="text-xs text-gray-500 text-center">
                    Changé d'avis ? Vous pouvez vous réabonner à tout moment
                    depuis les paramètres de votre compte.
                  </p>
                </div>
              </div>
            )}

            {/* Déjà désabonné */}
            {status === "already_unsubscribed" && (
              <div className="text-center">
                <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    className="w-8 h-8 text-yellow-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.35 16.5c-.77.833.192 2.5 1.732 2.5z"
                    />
                  </svg>
                </div>
                <h2 className="text-xl font-semibold text-gray-800 mb-3">
                  ℹ️ Déjà désabonné
                </h2>
                <p className="text-gray-600 mb-6">{message}</p>

                <div className="space-y-3">
                  <a
                    href="https://epilist.app"
                    className="block w-full bg-emerald-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-emerald-700 transition-colors text-center"
                  >
                    Retour à EpiList
                  </a>
                </div>
              </div>
            )}

            {/* Erreur */}
            {status === "error" && (
              <div className="text-center">
                <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    className="w-8 h-8 text-red-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </div>
                <h2 className="text-xl font-semibold text-gray-800 mb-3">
                  ❌ Erreur de désabonnement
                </h2>
                <p className="text-gray-600 mb-6">{message}</p>

                <div className="space-y-3">
                  <button
                    onClick={retryUnsubscribe}
                    disabled={isProcessing}
                    className="w-full bg-emerald-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-emerald-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
                  >
                    {isProcessing ? "Traitement..." : "Réessayer"}
                  </button>

                  <a
                    href="https://epilist.app"
                    className="block w-full bg-gray-100 text-gray-700 py-3 px-4 rounded-lg font-semibold hover:bg-gray-200 transition-colors text-center"
                  >
                    Retour à EpiList
                  </a>
                </div>

                <div className="mt-6 bg-gray-50 border border-gray-200 rounded-lg p-4">
                  <h3 className="font-semibold text-gray-800 mb-2">
                    🆘 Besoin d'aide ?
                  </h3>
                  <p className="text-sm text-gray-600">
                    Si le problème persiste, contactez notre support sur notre
                    site web ou essayez de vous désabonner depuis les paramètres
                    de votre compte EpiList.
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-6 py-4 text-center border-t">
            <p className="text-xs text-gray-500">
              © 2025 EpiList - Application de gestion de courses
              <br />
              <span className="text-emerald-600">
                🍁 Développée avec ❤️ au Nouveau-Brunswick, Canada
              </span>
            </p>
          </div>
        </div>
      </div>
    </>
  );
}

// ✅ Métadonnées pour App Router (app/unsubscribe/[token]/layout.js - OPTIONNEL)
/*
export const metadata = {
  title: 'Désabonnement - EpiList',
  description: 'Désabonnement des emails marketing EpiList',
  robots: 'noindex, nofollow'
};

export default function UnsubscribeLayout({ children }) {
  return children;
}
*/
