"use client";

// Page À propos : entièrement traduite (fr/en), design sobre.
import { Card, CardContent } from "@/components/ui/card";
import { MapPin, Users, Heart, Award, Target, Zap } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { useLanguage } from "@/hooks/useLanguage";

export default function AboutContent() {
  const { t } = useLanguage();

  const values = [
    { icon: Heart, title: t("aboutValue1Title"), desc: t("aboutValue1Desc") },
    { icon: Zap, title: t("aboutValue2Title"), desc: t("aboutValue2Desc") },
    { icon: Users, title: t("aboutValue3Title"), desc: t("aboutValue3Desc") },
  ];

  const stats = [1, 2, 3, 4] as const;

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="pt-32 pb-20">
        <div className="container mx-auto px-4">
          {/* En-tête */}
          <div className="mx-auto max-w-2xl text-center mb-16">
            <div className="inline-flex items-center gap-2 rounded-full border border-green-200 bg-green-50 px-4 py-1.5 text-sm font-medium text-green-700 mb-6">
              <MapPin className="h-4 w-4" />
              {t("madeInCanada")}
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-gray-900 tracking-tight mb-5">
              {t("aboutPageTitle")}
            </h1>
            <p className="text-lg text-gray-600">{t("aboutPageSubtitle")}</p>
          </div>

          {/* Mission */}
          <Card className="mx-auto max-w-3xl border border-gray-200 shadow-sm mb-16">
            <CardContent className="p-10 text-center">
              <div className="mx-auto mb-5 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                <Target className="h-6 w-6" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                {t("aboutMissionTitle")}
              </h2>
              <p className="text-lg leading-relaxed text-gray-600">
                {t("aboutMissionText")}
              </p>
            </CardContent>
          </Card>

          {/* Valeurs */}
          <div className="mb-16">
            <h2 className="text-2xl font-bold text-center text-gray-900 mb-10">
              {t("aboutValuesTitle")}
            </h2>
            <div className="grid gap-5 md:grid-cols-3">
              {values.map((value, index) => (
                <Card key={index} className="border border-gray-200 shadow-none">
                  <CardContent className="p-7 text-center">
                    <div className="mx-auto mb-4 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                      <value.icon className="h-5 w-5" />
                    </div>
                    <h3 className="text-base font-semibold text-gray-900 mb-2">
                      {value.title}
                    </h3>
                    <p className="text-sm leading-relaxed text-gray-600">
                      {value.desc}
                    </p>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* Chiffres honnêtes */}
          <div className="mb-16">
            <h2 className="text-2xl font-bold text-center text-gray-900 mb-10">
              {t("aboutStatsTitle")}
            </h2>
            <div className="grid grid-cols-2 gap-5 md:grid-cols-4 text-center">
              {stats.map((n) => (
                <div
                  key={n}
                  className="rounded-2xl border border-gray-200 bg-white p-6"
                >
                  <div className="text-3xl font-bold text-epilist-green mb-1">
                    {t(`aboutStat${n}Value` as any)}
                  </div>
                  <div className="text-sm text-gray-600">
                    {t(`aboutStat${n}Label` as any)}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Équipe */}
          <Card className="mx-auto max-w-3xl border border-gray-200 shadow-sm">
            <CardContent className="p-10 text-center">
              <div className="mx-auto mb-5 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                <Award className="h-6 w-6" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                {t("aboutTeamTitle")}
              </h2>
              <p className="text-lg leading-relaxed text-gray-600">
                {t("aboutTeamText")}
              </p>
            </CardContent>
          </Card>
        </div>
      </section>

      <Footer />
    </main>
  );
}
