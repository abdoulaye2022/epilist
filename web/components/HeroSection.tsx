"use client";

// Hero sobre : un badge honnête, un titre net, deux CTA, et l'écran de
// l'app. Pas d'effets de souris ni de compteurs invérifiables.
//
// L'écran n'est plus une capture : app-fr.jpg datait de deux refontes
// (bandeau bleu « Bonjour Alex », bouton « + » central dans la barre du
// bas) et montrait donc une application qui n'existe plus. Il est
// redessiné en HTML — voir components/AppScreens.tsx — et deux cartes
// flottantes en détachent ce qu'on y fait vraiment.
import { trackAppDownload } from "@/lib/gtag";
import { Button } from "@/components/ui/button";
import { AppScreenAccueil } from "@/components/AppScreens";
import Link from "next/link";
import {
  Download,
  ArrowDown,
  Users,
  WifiOff,
  BadgeCheck,
  MapPin,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";

const APP_STORE_URL =
  "https://apps.apple.com/ca/app/epilist/id6748285596";
const GOOGLE_PLAY_URL =
  "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

export default function HeroSection() {
  const { t, language } = useLanguage();

  const handleDownload = (): void => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    if (isIOS) {
      trackAppDownload("ios", "hero_main_cta");
      window.open(APP_STORE_URL, "_blank", "noopener,noreferrer");
    } else {
      trackAppDownload("android", "hero_main_cta");
      window.open(GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
    }
  };

  const scrollToFeatures = () => {
    document
      .getElementById("fonctionnalites")
      ?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <section
      className="relative bg-cover bg-center bg-no-repeat"
      style={{ backgroundImage: "url('/hero-bg.jpg')" }}
    >
      {/* Voile clair : lisibilité du texte + fondu vers le blanc en bas */}
      <div
        className="absolute inset-0 bg-gradient-to-b from-white/40 via-transparent to-white"
        aria-hidden="true"
      ></div>
      <div className="container relative z-10 mx-auto px-4 pt-28 pb-16 lg:pt-36 lg:pb-24">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Colonne texte */}
          <div className="space-y-7">
            <div className="inline-flex items-center gap-2 rounded-full border border-green-200 bg-white px-4 py-1.5 text-sm font-medium text-green-700">
              <MapPin className="h-4 w-4" />
              {t("madeInCanada")}
            </div>

            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 leading-[1.1] tracking-tight">
              {t("heroTitle")}{" "}
              <span className="text-epilist-green">
                {t("heroTitleHighlight")}
              </span>
            </h1>

            <p className="text-lg md:text-xl text-gray-600 leading-relaxed max-w-xl">
              {t("heroSubtitle")}{" "}
              <span className="text-gray-900 font-semibold">
                {t("heroSubtitleHighlight")}
              </span>
            </p>

            {/* CTA */}
            <div className="flex flex-col sm:flex-row gap-3">
              <Button
                onClick={handleDownload}
                size="lg"
                className="bg-epilist-green hover:bg-green-600 text-white shadow-md h-12 px-7 text-base"
              >
                <Download className="mr-2 h-5 w-5" />
                {t("downloadNow")}
              </Button>
              <Link href={href("features", language)}>
                <Button
                  size="lg"
                  variant="outline"
                  className="h-12 px-7 text-base border-gray-300 text-gray-700 hover:border-epilist-green hover:text-epilist-green w-full sm:w-auto"
                >
                  {t("discoverFeatures")}
                </Button>
              </Link>
            </div>

            {/* Garanties simples et vraies */}
            <div className="flex flex-wrap items-center gap-x-6 gap-y-2 pt-2 text-sm text-gray-600">
              <span className="inline-flex items-center gap-2">
                <BadgeCheck className="h-4 w-4 text-epilist-green" />
                {t("freeForLife")}
              </span>
              <span className="inline-flex items-center gap-2">
                <WifiOff className="h-4 w-4 text-epilist-green" />
                {language === "fr" ? "Fonctionne hors ligne" : "Works offline"}
              </span>
              <span className="inline-flex items-center gap-2">
                <Users className="h-4 w-4 text-epilist-green" />
                {t("familySync")}
              </span>
            </div>
          </div>

          {/* Colonne visuelle : l'écran d'accueil tel qu'il est
              aujourd'hui, et deux cartes qui disent ce qu'on y fait. */}
          <div className="relative mx-auto w-full max-w-[340px] pb-10 sm:pb-0">
            <div
              className="absolute -inset-6 rounded-[2.5rem] bg-green-100/70 blur-2xl"
              aria-hidden="true"
            ></div>

            <div className="relative">
              <AppScreenAccueil />

              {/* Ce que le prix saisi en magasin change : le budget
                  suit, au lieu de rester au chiffre d'avant. */}
              <div className="absolute hidden sm:block -left-3 top-[36%] w-[148px] rounded-xl border border-gray-200 bg-white p-2.5 shadow-lg sm:-left-32">
                <p className="text-[10px] font-semibold text-gray-500">
                  {language === "fr" ? "Au magasin" : "At the store"}
                </p>
                <p className="mt-1 text-[13px] font-bold text-gray-900">
                  {language === "fr" ? "Total : 87,40 $" : "Total: $87.40"}
                </p>
                <p className="text-[10px] text-gray-600">
                  {language === "fr"
                    ? "Reste : 272,55 $"
                    : "Left: $272.55"}
                </p>
              </div>

              <div className="absolute hidden sm:block -right-3 -bottom-2 w-[158px] rounded-xl border border-gray-200 bg-white p-2.5 shadow-lg sm:-right-32 sm:bottom-10">
                <p className="text-[10px] font-semibold text-gray-500">
                  {language === "fr" ? "À la maison" : "At home"}
                </p>
                <p className="mt-1 flex items-center gap-1.5 text-[12px] font-bold text-gray-900">
                  <span className="inline-block h-2.5 w-2.5 rounded-full bg-[#C2410C] ring-2 ring-white" />
                  {language === "fr" ? "Riz : stock bas" : "Rice: low stock"}
                </p>
                <p className="text-[10px] text-gray-600">
                  {language === "fr"
                    ? "Il en reste 1 sac sur 1"
                    : "1 bag left out of 1"}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Indicateur de défilement */}
        <div className="text-center mt-16">
          <button
            onClick={scrollToFeatures}
            className="inline-flex flex-col items-center gap-1.5 text-gray-400 hover:text-epilist-green transition-colors"
          >
            <span className="text-sm font-medium">{t("discoverFeatures")}</span>
            <ArrowDown className="h-5 w-5" />
          </button>
        </div>
      </div>
    </section>
  );
}
