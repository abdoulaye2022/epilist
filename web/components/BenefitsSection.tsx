"use client";

// Avantages : six cartes, six faits verifiables.
//
// Chaque carte portait une statistique en gros dans son coin : « 70 %
// de temps economise », « 30 % d'economies moyennes », « 100 % de
// synchronisation », « ∞ insights », « 100 % securise », « 24/7 ».
// Aucun de ces chiffres n'etait calcule, ni mesure, ni mesurable : ils
// etaient ecrits en dur dans les traductions. Le bloc est parti avec
// eux. Ce qui reste se verifie en installant l'application.
import {
  BadgeCheck,
  Languages,
  WifiOff,
  Receipt,
  Users,
  Wallet,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

// Les icones suivent le fait, pas l'inverse : horloge pour « 70 % de
// temps economise », courbe descendante pour « 30 % d'economies »...
// elles avaient ete choisies pour des chiffres qui n'existent plus.
const benefits = [
  { icon: BadgeCheck, n: 1 }, // gratuite, sans publicite
  { icon: Languages, n: 2 }, // bilingue
  { icon: WifiOff, n: 3 }, // hors ligne
  { icon: Receipt, n: 4 }, // lecture des recus sur l'appareil
  { icon: Users, n: 5 }, // partage avec le foyer
  { icon: Wallet, n: 6 }, // budgets et alertes
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
              <div className="mb-4">
                <div className="inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                  <Icon className="h-5 w-5" />
                </div>
              </div>
              <h3 className="text-base font-semibold text-gray-900 mb-1.5">
                {t(`benefit${n}Title` as Parameters<typeof t>[0])}
              </h3>
              <p className="text-sm leading-relaxed text-gray-600">
                {t(`benefit${n}Desc` as Parameters<typeof t>[0])}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
