"use client";

// Appel à l'action final : fond vert de marque, deux badges de stores,
// trois garanties honnêtes.
import { trackAppDownload } from "@/lib/gtag";
import { Button } from "@/components/ui/button";
import { Apple, Play, BadgeCheck, WifiOff, ShieldCheck } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

const APP_STORE_URL =
  "https://apps.apple.com/ca/app/epilist/id6748285596";
const GOOGLE_PLAY_URL =
  "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

export default function CTASection() {
  const { t, language } = useLanguage();

  const open = (store: "ios" | "android") => {
    trackAppDownload(store, "cta_section");
    window.open(store === "ios" ? APP_STORE_URL : GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
  };

  return (
    <section className="bg-epilist-green py-20 lg:py-24">
      <div className="container mx-auto px-4 text-center">
        <h2 className="mx-auto max-w-2xl text-3xl md:text-4xl font-bold text-white tracking-tight">
          {t("ctaTitle")}
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-lg text-green-50">
          {t("ctaSubtitle")}
        </p>

        <div className="mt-9 flex flex-col sm:flex-row items-center justify-center gap-3">
          <Button
            onClick={() => open("ios")}
            size="lg"
            className="h-12 w-56 bg-gray-900 text-white hover:bg-black shadow-md"
          >
            <Apple className="mr-2 h-5 w-5" />
            {t("appStore")}
          </Button>
          <Button
            onClick={() => open("android")}
            size="lg"
            className="h-12 w-56 bg-white text-gray-900 hover:bg-gray-100 shadow-md"
          >
            <Play className="mr-2 h-5 w-5" />
            {t("googlePlay")}
          </Button>
        </div>

        <div className="mt-8 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-green-50">
          <span className="inline-flex items-center gap-2">
            <BadgeCheck className="h-4 w-4" />
            {t("free")}
          </span>
          <span className="inline-flex items-center gap-2">
            <WifiOff className="h-4 w-4" />
            {language === "fr" ? "Fonctionne hors ligne" : "Works offline"}
          </span>
          <span className="inline-flex items-center gap-2">
            <ShieldCheck className="h-4 w-4" />
            {t("secureData")}
          </span>
        </div>
      </div>
    </section>
  );
}
