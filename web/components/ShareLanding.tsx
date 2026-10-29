"use client";

// La page d'arrivée d'un lien de partage.
//
// Ce qu'elle faisait avant : sur ordinateur, elle envoyait tout le monde
// vers l'App Store — y compris sous Windows, où personne ne peut
// installer une application iPhone. Sur téléphone, elle tentait le lien
// `epilist://` puis basculait vers le magasin après trois secondes, et
// le jeton de partage disparaissait en chemin : l'invité installait
// l'application et arrivait sur l'écran de bienvenue, sans la liste.
//
// Ce qu'elle fait maintenant :
//
//   - sur Android et iOS, elle tente d'ouvrir l'application, puis
//     bascule vers le bon magasin — et le lien Google Play porte le
//     jeton dans `referrer`, que Google rend à l'application au premier
//     lancement ;
//   - sur ordinateur, elle ne redirige plus rien. Elle affiche les deux
//     magasins, un QR code du lien pour passer au téléphone, et le code
//     d'invitation ;
//   - partout, elle montre le CODE à six caractères, parce que c'est la
//     seule chose qui survit à coup sûr au passage par le magasin.
import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { QRCodeSVG } from "qrcode.react";
import { Apple, Play, Smartphone, Monitor, Loader2 } from "lucide-react";

const APP_STORE_URL = "https://apps.apple.com/ca/app/epilist/id6748285596";
const PLAY_BASE_URL =
  "https://play.google.com/store/apps/details?id=com.m2atech.epilist";
const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "https://m2atodev.com/api.epilist/public";

type Plateforme = "android" | "ios" | "ordinateur";

interface InfoPartage {
  invite_code: string | null;
  list_name: string | null;
  owner_first_name: string | null;
}

/** Le lien Play qui transporte le jeton jusqu'à la première ouverture. */
export function lienPlayAvecReferrer(token: string): string {
  const referrer = `share_token=${token}&utm_source=share`;

  return `${PLAY_BASE_URL}&referrer=${encodeURIComponent(referrer)}`;
}

/**
 * iPadOS se présente comme un Mac depuis iOS 13 ; seul le nombre de
 * points de contact le trahit. Sans ce détail, une tablette Apple est
 * traitée comme un ordinateur et ne reçoit jamais l'App Store.
 */
function detecterPlateforme(): Plateforme {
  if (typeof navigator === "undefined") return "ordinateur";

  const ua = navigator.userAgent;

  if (/android/i.test(ua)) return "android";
  if (/iPad|iPhone|iPod/.test(ua)) return "ios";
  if (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1) return "ios";

  return "ordinateur";
}

const TEXTES = {
  fr: {
    invitationDe: (prenom: string) => `${prenom} vous invite`,
    invitationSans: "Vous êtes invité sur une liste EpiList",
    surLaListe: (liste: string) => `sur la liste « ${liste} »`,
    ouverture: "Ouverture de l'application...",
    sinonInstaller: "Si rien ne se passe, installez EpiList :",
    surOrdinateur: "Vous êtes sur un ordinateur",
    surOrdinateurTexte:
      "EpiList est une application mobile. Scannez ce code avec votre téléphone, ou installez-la depuis votre magasin d'applications.",
    codeTitre: "Après l'installation, entrez ce code",
    codeTexte:
      "Ouvrez EpiList, touchez « J'ai un code d'invitation » et saisissez-le. Le code fonctionne même si ce lien a été perdu en route.",
    scanner: "Scannez pour ouvrir sur votre téléphone",
    expiree: "Cette invitation n'est plus valable",
    expireeTexte:
      "Le lien a peut-être expiré, ou l'invitation a déjà été acceptée. Demandez-en un nouveau à la personne qui vous a invité.",
    chargement: "Un instant...",
  },
  en: {
    invitationDe: (prenom: string) => `${prenom} is inviting you`,
    invitationSans: "You have been invited to an EpiList list",
    surLaListe: (liste: string) => `to the list “${liste}”`,
    ouverture: "Opening the app...",
    sinonInstaller: "If nothing happens, install EpiList:",
    surOrdinateur: "You are on a computer",
    surOrdinateurTexte:
      "EpiList is a mobile app. Scan this code with your phone, or install it from your app store.",
    codeTitre: "After installing, enter this code",
    codeTexte:
      "Open EpiList, tap “I have an invitation code” and type it in. The code works even if this link gets lost on the way.",
    scanner: "Scan to open on your phone",
    expiree: "This invitation is no longer valid",
    expireeTexte:
      "The link may have expired, or the invitation was already accepted. Ask the person who invited you for a new one.",
    chargement: "One moment...",
  },
};

export default function ShareLanding({ token }: { token: string }) {
  const [plateforme, setPlateforme] = useState<Plateforme | null>(null);
  const [info, setInfo] = useState<InfoPartage | null>(null);
  const [introuvable, setIntrouvable] = useState(false);
  const [langue, setLangue] = useState<"fr" | "en">("fr");

  const t = TEXTES[langue];
  const lienPlay = useMemo(() => lienPlayAvecReferrer(token), [token]);
  const lienWeb = useMemo(
    () =>
      typeof window === "undefined"
        ? `https://epilist.app/share/${token}`
        : window.location.href,
    [token]
  );

  useEffect(() => {
    setPlateforme(detecterPlateforme());
    setLangue(navigator.language?.startsWith("en") ? "en" : "fr");
  }, []);

  // Le code d'invitation vient de l'API : l'URL ne porte que le jeton.
  useEffect(() => {
    let vivant = true;

    (async () => {
      try {
        const res = await fetch(
          `${API_URL}/share/public/${encodeURIComponent(token)}`,
          { headers: { Accept: "application/json" } }
        );
        const data = await res.json().catch(() => null);

        if (!vivant) return;

        if (res.ok && data?.success) {
          setInfo(data.data as InfoPartage);
        } else {
          setIntrouvable(true);
        }
      } catch {
        // Réseau indisponible : on garde la page utile, sans le code.
        if (vivant) setInfo(null);
      }
    })();

    return () => {
      vivant = false;
    };
  }, [token]);

  // Sur téléphone seulement : tenter l'app, puis le magasin. Sur
  // ordinateur, aucune redirection — il n'y a rien à y installer.
  useEffect(() => {
    if (plateforme === null || plateforme === "ordinateur") return;

    window.location.href = `epilist://share/${token}`;

    const bascule = setTimeout(() => {
      window.location.href = plateforme === "ios" ? APP_STORE_URL : lienPlay;
    }, 2500);

    // Si l'application s'ouvre, la page passe en arrière-plan : on
    // annule la bascule, sinon le magasin s'ouvre par-dessus au retour.
    const surMasquage = () => {
      if (document.visibilityState === "hidden") clearTimeout(bascule);
    };

    document.addEventListener("visibilitychange", surMasquage);

    return () => {
      clearTimeout(bascule);
      document.removeEventListener("visibilitychange", surMasquage);
    };
  }, [plateforme, token, lienPlay]);

  const code = info?.invite_code ?? null;

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12">
      <div className="w-full max-w-md">
        <div className="rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
          <div className="flex items-center justify-center gap-2.5">
            <Image
              src="/app_logo.png"
              alt="EpiList"
              width={32}
              height={32}
              className="object-contain"
            />
            <span className="text-xl font-bold text-gray-900">EpiList</span>
          </div>

          {introuvable ? (
            <div className="mt-8 text-center">
              <h1 className="text-xl font-bold text-gray-900">{t.expiree}</h1>
              <p className="mt-3 text-sm leading-relaxed text-gray-600">
                {t.expireeTexte}
              </p>
            </div>
          ) : (
            <>
              <div className="mt-8 text-center">
                <h1 className="text-xl font-bold text-gray-900">
                  {info?.owner_first_name
                    ? t.invitationDe(info.owner_first_name)
                    : t.invitationSans}
                </h1>
                {info?.list_name && (
                  <p className="mt-1.5 text-base text-gray-700">
                    {t.surLaListe(info.list_name)}
                  </p>
                )}
              </div>

              {/* Le code : la seule chose qui survit au magasin. */}
              {code && (
                <div className="mt-7 rounded-xl border border-green-200 bg-green-50/70 p-5 text-center">
                  <p className="text-sm font-semibold text-green-900">
                    {t.codeTitre}
                  </p>
                  <p className="mt-3 font-mono text-3xl font-bold tracking-[0.3em] text-epilist-green">
                    {code}
                  </p>
                  <p className="mt-3 text-xs leading-relaxed text-green-900/80">
                    {t.codeTexte}
                  </p>
                </div>
              )}

              {plateforme === "ordinateur" ? (
                <div className="mt-7">
                  <div className="flex items-center justify-center gap-2 text-sm font-medium text-gray-700">
                    <Monitor className="h-4 w-4" />
                    {t.surOrdinateur}
                  </div>
                  <p className="mt-2 text-center text-sm leading-relaxed text-gray-600">
                    {t.surOrdinateurTexte}
                  </p>

                  <div className="mt-6 flex flex-col items-center">
                    <div className="rounded-xl border border-gray-200 bg-white p-3">
                      <QRCodeSVG value={lienWeb} size={160} level="M" />
                    </div>
                    <p className="mt-3 flex items-center gap-1.5 text-xs text-gray-500">
                      <Smartphone className="h-3.5 w-3.5" />
                      {t.scanner}
                    </p>
                  </div>
                </div>
              ) : (
                <p className="mt-7 flex items-center justify-center gap-2 text-sm text-gray-600">
                  <Loader2 className="h-4 w-4 animate-spin text-epilist-green" />
                  {t.ouverture}
                </p>
              )}

              <p className="mt-7 text-center text-xs font-medium uppercase tracking-wide text-gray-400">
                {plateforme === "ordinateur" ? "" : t.sinonInstaller}
              </p>

              <div className="mt-3 flex flex-col gap-2.5">
                <a
                  href={APP_STORE_URL}
                  className="inline-flex h-11 items-center justify-center gap-2 rounded-lg bg-gray-900 px-4 text-sm font-semibold text-white transition-colors hover:bg-black"
                >
                  <Apple className="h-4 w-4" />
                  App Store
                </a>
                <a
                  href={lienPlay}
                  className="inline-flex h-11 items-center justify-center gap-2 rounded-lg border border-gray-300 bg-white px-4 text-sm font-semibold text-gray-900 transition-colors hover:bg-gray-50"
                >
                  <Play className="h-4 w-4" />
                  Google Play
                </a>
              </div>
            </>
          )}
        </div>

        <p className="mt-6 text-center text-xs text-gray-400">
          EpiList · M2atech Solutions Inc.
        </p>
      </div>
    </main>
  );
}
