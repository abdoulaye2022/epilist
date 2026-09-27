"use client";

// Ancrage local : conçue au Nouveau-Brunswick. Icônes Lucide, pas
// d'emoji, une bande sobre sur fond sombre.
import { MapPin, Leaf, ShieldCheck, HeartHandshake } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

export default function NewBrunswickSection() {
  const { t } = useLanguage();

  const items = [
    { icon: Leaf, title: t("nbFeature1"), desc: t("nbFeature1Desc") },
    { icon: ShieldCheck, title: t("nbFeature2"), desc: t("nbFeature2Desc") },
    { icon: HeartHandshake, title: t("nbFeature3"), desc: t("nbFeature3Desc") },
  ];

  return (
    <section className="bg-gray-900 py-20 lg:py-24">
      <div className="container mx-auto px-4">
        <div className="mx-auto max-w-2xl text-center mb-12">
          <div className="inline-flex items-center gap-2 rounded-full border border-green-500/30 bg-green-500/10 px-4 py-1.5 text-sm font-medium text-green-400 mb-6">
            <MapPin className="h-4 w-4" />
            {t("madeInCanada")}
          </div>
          <h2 className="text-3xl md:text-4xl font-bold text-white tracking-tight">
            {t("nbTitle")}{" "}
            <span className="text-green-400">{t("nbTitleHighlight")}</span>
          </h2>
          <p className="mt-4 text-lg text-gray-400">{t("nbSubtitle")}</p>
        </div>

        <div className="grid gap-5 md:grid-cols-3">
          {items.map((item, index) => (
            <div
              key={index}
              className="rounded-2xl border border-white/10 bg-white/5 p-6"
            >
              <div className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-500/15 text-green-400">
                <item.icon className="h-5 w-5" />
              </div>
              <h3 className="text-base font-semibold text-white mb-1.5">
                {item.title}
              </h3>
              <p className="text-sm leading-relaxed text-gray-400">
                {item.desc}
              </p>
            </div>
          ))}
        </div>

        <p className="mt-12 text-center text-sm text-gray-500 max-w-2xl mx-auto">
          {t("nbDescription")}
        </p>
      </div>
    </section>
  );
}
