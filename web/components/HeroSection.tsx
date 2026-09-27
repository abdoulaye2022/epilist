"use client";

// Hero sobre : un badge honnête, un titre net, deux CTA, la capture de
// l'app. Pas d'effets de souris ni de compteurs invérifiables.
import { trackAppDownload } from "@/lib/gtag";
import { Button } from "@/components/ui/button";
import Image from "next/image";
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
  "https://apps.apple.com/ca/app/epilist/id6748285596?l=fr-CA";
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

          {/* Colonne visuelle */}
          <div className="relative mx-auto w-full max-w-[320px]">
            <div
              className="absolute -inset-6 rounded-[2.5rem] bg-green-100/70 blur-2xl"
              aria-hidden="true"
            ></div>
            <div className="relative rounded-3xl border border-gray-200 bg-white p-3 shadow-xl">
              {/* Capture du tableau de bord dans la langue de la page */}
              <Image
                src={language === "fr" ? "/app-fr.jpg" : "/app-en.jpg"}
                alt={
                  language === "fr"
                    ? "Tableau de bord de l'application EpiList"
                    : "EpiList app dashboard"
                }
                width={900}
                height={1956}
                className="w-full h-auto rounded-2xl object-cover"
                priority
              />
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
