"use client";

// Page Télécharger : traduite fr/en, sans effets de souris ni faux
// compteurs, avec les captures de l'application.
import { trackAppDownloadUnified } from "@/lib/unified-tracking";
import { Button } from "@/components/ui/button";
import { Download, Zap, Heart, MapPin, Apple, Play } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

const APP_STORE_URL =
  "https://apps.apple.com/ca/app/epilist/id6748285596";
const GOOGLE_PLAY_URL =
  "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

export default function DownloadContent() {
  const { t } = useLanguage();

  const handleDownload = (platform: "ios" | "android") => {
    trackAppDownloadUnified(platform, "download_page");
    const url = platform === "ios" ? APP_STORE_URL : GOOGLE_PLAY_URL;
    window.open(url, "_blank", "noopener,noreferrer");
  };

  const perks = [
    { icon: Zap, title: t("dlFeature1Title"), desc: t("dlFeature1Desc") },
    { icon: Heart, title: t("dlFeature2Title"), desc: t("dlFeature2Desc") },
    { icon: MapPin, title: t("dlFeature3Title"), desc: t("dlFeature3Desc") },
  ];

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="bg-gradient-to-b from-green-50/60 to-white pt-32 pb-16">
        <div className="container mx-auto px-4 text-center">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-green-200 bg-white px-4 py-1.5 text-sm font-medium text-green-700">
            <Download className="h-4 w-4" />
            {t("dlBadge")}
          </div>

          <h1 className="mx-auto max-w-2xl text-4xl md:text-5xl font-bold text-gray-900 tracking-tight mb-5">
            {t("dlTitle")}
          </h1>
          <p className="mx-auto mb-10 max-w-2xl text-lg text-gray-600">
            {t("dlSubtitle")}
          </p>

          {/* Boutons de téléchargement */}
          <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Button
              onClick={() => handleDownload("ios")}
              size="lg"
              className="h-14 w-60 rounded-xl bg-gray-900 text-white shadow-md hover:bg-black"
            >
              <Apple className="mr-3 h-6 w-6" />
              <span className="text-left leading-tight">
                <span className="block text-[11px] font-normal opacity-80">
                  {t("dlOnStore")}
                </span>
                <span className="block text-base font-semibold">
                  {t("appStore")}
                </span>
              </span>
            </Button>
            <Button
              onClick={() => handleDownload("android")}
              size="lg"
              className="h-14 w-60 rounded-xl bg-epilist-green text-white shadow-md hover:bg-green-600"
            >
              <Play className="mr-3 h-6 w-6" />
              <span className="text-left leading-tight">
                <span className="block text-[11px] font-normal opacity-90">
                  {t("dlOnStore")}
                </span>
                <span className="block text-base font-semibold">
                  {t("googlePlay")}
                </span>
              </span>
            </Button>
          </div>

          {/* Trois garanties */}
          <div className="mx-auto mt-14 grid max-w-3xl gap-5 md:grid-cols-3">
            {perks.map((item, i) => (
              <div
                key={i}
                className="rounded-2xl border border-gray-200 bg-white p-6"
              >
                <div className="mx-auto mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                  <item.icon className="h-5 w-5" />
                </div>
                <h3 className="mb-1 font-semibold text-gray-900">
                  {item.title}
                </h3>
                <p className="text-sm text-gray-600">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
