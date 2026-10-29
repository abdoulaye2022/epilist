"use client";

// La bannière de consentement.
//
// TROIS CHOSES QU'ELLE FAIT, et qui ne sont pas négociables sous la
// Loi 25 :
//
//   1. « Refuser » est AUSSI VISIBLE que « Accepter ». Même taille,
//      même poids, côte à côte. Un refus caché dans un lien gris n'est
//      pas un refus possible ;
//   2. rien ne se charge avant le choix — ni Google Analytics, ni le
//      pixel, ni Hotjar. C'est `ConsentGate` qui le garantit, cette
//      bannière ne fait que recueillir la décision ;
//   3. le choix se change plus tard, par « Gérer les témoins » dans le
//      pied de page. Un consentement qu'on ne peut pas retirer n'en est
//      pas un.
//
// Le détail par catégorie s'ouvre d'un geste : la plupart des gens
// répondront aux deux gros boutons, et c'est très bien.
import { useEffect, useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";
import {
  EVENEMENT_CHANGEMENT,
  enregistrerConsentement,
  lireConsentement,
} from "@/lib/consent";
import { Button } from "@/components/ui/button";
import { Cookie, ChevronDown, ChevronUp } from "lucide-react";

export default function ConsentBanner() {
  const { t, language } = useLanguage();
  const [visible, setVisible] = useState(false);
  const [detail, setDetail] = useState(false);
  const [mesure, setMesure] = useState(true);
  const [marketing, setMarketing] = useState(false);

  useEffect(() => {
    // Le premier rendu se fait côté serveur, sans localStorage : la
    // bannière ne peut donc apparaître qu'après montage, et c'est tant
    // mieux — elle ne clignote pas pour qui a déjà choisi.
    setVisible(lireConsentement() === null);

    const surChangement = (e: Event) => {
      const choix = (e as CustomEvent).detail;
      setVisible(choix === null);
      setDetail(false);
    };

    window.addEventListener(EVENEMENT_CHANGEMENT, surChangement);
    return () => window.removeEventListener(EVENEMENT_CHANGEMENT, surChangement);
  }, []);

  if (!visible) return null;

  const decider = (choix: { mesure: boolean; marketing: boolean }) => {
    enregistrerConsentement(choix);
    setVisible(false);
  };

  return (
    <div
      role="dialog"
      aria-live="polite"
      aria-label={t("consentTitle")}
      className="fixed inset-x-0 bottom-0 z-50 border-t border-gray-200 bg-white shadow-[0_-4px_20px_rgba(0,0,0,0.08)]"
    >
      <div className="container mx-auto max-w-4xl px-4 py-5">
        <div className="flex items-start gap-3">
          <Cookie className="mt-0.5 h-5 w-5 shrink-0 text-epilist-green" />
          <div className="flex-1">
            <h2 className="text-base font-bold text-gray-900">
              {t("consentTitle")}
            </h2>
            <p className="mt-1.5 text-sm leading-relaxed text-gray-600">
              {t("consentBody")}{" "}
              <Link
                href={href("privacy", language)}
                className="font-semibold text-epilist-green hover:underline"
              >
                {t("privacyPolicy")}
              </Link>
            </p>

            {detail && (
              <div className="mt-4 space-y-3 rounded-lg border border-gray-200 bg-gray-50 p-4">
                <Categorie
                  titre={t("consentCatMeasure")}
                  texte={t("consentCatMeasureDesc")}
                  actif={mesure}
                  onChange={setMesure}
                />
                <Categorie
                  titre={t("consentCatMarketing")}
                  texte={t("consentCatMarketingDesc")}
                  actif={marketing}
                  onChange={setMarketing}
                />
                <p className="pt-1 text-xs text-gray-500">
                  {t("consentNecessary")}
                </p>
              </div>
            )}

            <div className="mt-4 flex flex-col gap-2.5 sm:flex-row sm:items-center">
              {/* Refuser AVANT accepter, et de même poids : l'ordre et
                  la taille font partie de la conformité. */}
              <Button
                onClick={() => decider({ mesure: false, marketing: false })}
                variant="outline"
                className="h-11 flex-1 border-gray-300 text-sm font-semibold sm:flex-none sm:px-8"
              >
                {t("consentRefuse")}
              </Button>
              <Button
                onClick={() =>
                  decider(
                    detail
                      ? { mesure, marketing }
                      : { mesure: true, marketing: true }
                  )
                }
                className="h-11 flex-1 bg-epilist-green text-sm font-semibold text-white hover:bg-green-700 sm:flex-none sm:px-8"
              >
                {detail ? t("consentSaveChoice") : t("consentAccept")}
              </Button>
              <button
                type="button"
                onClick={() => setDetail((d) => !d)}
                className="inline-flex items-center justify-center gap-1 text-sm font-medium text-gray-600 hover:text-gray-900 sm:ml-2"
              >
                {detail ? t("consentHideDetail") : t("consentShowDetail")}
                {detail ? (
                  <ChevronUp className="h-4 w-4" />
                ) : (
                  <ChevronDown className="h-4 w-4" />
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Categorie({
  titre,
  texte,
  actif,
  onChange,
}: {
  titre: string;
  texte: string;
  actif: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex cursor-pointer items-start gap-3">
      <input
        type="checkbox"
        checked={actif}
        onChange={(e) => onChange(e.target.checked)}
        className="mt-0.5 h-4 w-4 shrink-0 accent-epilist-green"
      />
      <span>
        <span className="block text-sm font-semibold text-gray-900">
          {titre}
        </span>
        <span className="block text-xs leading-relaxed text-gray-600">
          {texte}
        </span>
      </span>
    </label>
  );
}
