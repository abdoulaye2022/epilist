"use client";

// Grille de fonctionnalités : cartes blanches sobres, icônes Lucide,
// et surtout les capacités récentes (scanner de reçus, comparateur de
// prix, suggestions prédictives, inventaire, mode magasin, repas).
import {
  Share2,
  Wallet,
  ReceiptText,
  Scale,
  Sparkles,
  Home,
  Store,
  UtensilsCrossed,
  WifiOff,
  ArrowRight,
} from "lucide-react";
import Link from "next/link";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";

export default function FeaturesSection() {
  const { t, language } = useLanguage();

  const features = [
    { icon: Share2, title: t("feature2Title"), desc: t("feature2Desc") },
    { icon: ReceiptText, title: t("featureScanTitle"), desc: t("featureScanDesc") },
    { icon: Scale, title: t("featurePricesTitle"), desc: t("featurePricesDesc") },
    { icon: Sparkles, title: t("featurePredictTitle"), desc: t("featurePredictDesc") },
    { icon: Wallet, title: t("feature4Title"), desc: t("feature4Desc") },
    { icon: Home, title: t("featureInventoryTitle"), desc: t("featureInventoryDesc") },
    { icon: Store, title: t("featureStoreModeTitle"), desc: t("featureStoreModeDesc") },
    { icon: UtensilsCrossed, title: t("featureMealsTitle"), desc: t("featureMealsDesc") },
    { icon: WifiOff, title: t("feature8Title"), desc: t("feature8Desc") },
  ];

  return (
    <section id="fonctionnalites" className="bg-white py-20 lg:py-28">
      <div className="container mx-auto px-4">
        {/* En-tête de section */}
        <div className="mx-auto max-w-2xl text-center mb-14">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">
            {t("featuresTitle")}{" "}
            <span className="text-epilist-green">
              {t("featuresTitleHighlight")}
            </span>
          </h2>
          <p className="mt-4 text-lg text-gray-600">{t("featuresSubtitle")}</p>
        </div>

        {/* Grille */}
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, index) => (
            <div
              key={index}
              className="group rounded-2xl border border-gray-200 bg-white p-6 transition-all duration-200 hover:border-green-300 hover:shadow-md"
            >
              <div className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                <feature.icon className="h-5 w-5" />
              </div>
              <h3 className="text-base font-semibold text-gray-900 mb-1.5">
                {feature.title}
              </h3>
              <p className="text-sm leading-relaxed text-gray-600">
                {feature.desc}
              </p>
            </div>
          ))}
        </div>

        {/* Lien vers la page complète */}
        <div className="mt-12 text-center">
          <Link
            href={href("features", language)}
            className="inline-flex items-center gap-2 font-semibold text-epilist-green hover:text-green-700 transition-colors"
          >
            {t("advancedFeatures")}
            <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </div>
    </section>
  );
}
