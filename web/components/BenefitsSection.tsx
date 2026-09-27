"use client";

// Avantages : six cartes sobres avec leur statistique, sans halos ni
// dégradés bicolores.
import { Clock, TrendingDown, Users, Heart, Target, Zap } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

const benefits = [
  { icon: Clock, n: 1 },
  { icon: TrendingDown, n: 2 },
  { icon: Users, n: 3 },
  { icon: Heart, n: 4 },
  { icon: Target, n: 5 },
  { icon: Zap, n: 6 },
] as const;

export default function BenefitsSection() {
  const { t } = useLanguage();

  return (
    <section id="avantages" className="bg-green-50/50 py-20 lg:py-28">
      <div className="container mx-auto px-4">
        <div className="mx-auto max-w-2xl text-center mb-14">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">
            {t("benefitsTitle")}{" "}
            <span className="text-epilist-green">
              {t("benefitsTitleHighlight")}
            </span>
          </h2>
          <p className="mt-4 text-lg text-gray-600">{t("benefitsSubtitle")}</p>
        </div>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {benefits.map(({ icon: Icon, n }) => (
            <div
              key={n}
              className="rounded-2xl border border-gray-200 bg-white p-6 transition-all duration-200 hover:border-green-300 hover:shadow-md"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                  <Icon className="h-5 w-5" />
                </div>
                <div className="text-right">
                  <div className="text-xl font-bold text-epilist-green leading-none">
                    {t(`benefit${n}Stat` as any)}
                  </div>
                  <div className="text-xs text-gray-500 mt-1">
                    {t(`benefit${n}StatLabel` as any)}
                  </div>
                </div>
              </div>
              <h3 className="text-base font-semibold text-gray-900 mb-1.5">
                {t(`benefit${n}Title` as any)}
              </h3>
              <p className="text-sm leading-relaxed text-gray-600">
                {t(`benefit${n}Desc` as any)}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
