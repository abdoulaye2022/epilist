"use client";

// Comparaison factuelle : tableau traduit fr/en, initiales dans des
// pastilles au lieu d'emojis, pas de notes inventées.
import { Card, CardContent } from "@/components/ui/card";
import { Check, X, DollarSign, Wifi, MapPin } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { useLanguage } from "@/hooks/useLanguage";

type Cell = boolean | string;

export default function ComparisonContent() {
  const { t, language } = useLanguage();
  const perMonth = (price: string) =>
    language === "fr" ? `${price} $/mois` : `$${price}/mo`;

  const apps = [
    { name: "EpiList", highlight: true },
    { name: "AnyList", highlight: false },
    { name: "Cozi", highlight: false },
    { name: "OurGroceries", highlight: false },
  ];

  const rows: { label: string; values: Cell[] }[] = [
    {
      label: t("cmpRowPrice"),
      values: [
        t("cmpFreeForever"),
        perMonth(language === "fr" ? "9,99" : "9.99"),
        perMonth(language === "fr" ? "4,99" : "4.99"),
        perMonth(language === "fr" ? "2,99" : "2.99"),
      ],
    },
    { label: t("cmpRowShare"), values: [true, true, true, true] },
    { label: t("cmpRowOffline"), values: [true, false, false, true] },
    { label: t("cmpRowNoAds"), values: [true, false, false, false] },
    { label: t("cmpRowSuggestions"), values: [true, true, false, false] },
    { label: t("cmpRowPrices"), values: [true, false, false, false] },
  ];

  const why = [
    { icon: DollarSign, title: t("cmpWhy1Title"), desc: t("cmpWhy1Desc") },
    { icon: Wifi, title: t("cmpWhy2Title"), desc: t("cmpWhy2Desc") },
    { icon: MapPin, title: t("cmpWhy3Title"), desc: t("cmpWhy3Desc") },
  ];

  const cell = (value: Cell, highlight: boolean) =>
    typeof value === "boolean" ? (
      value ? (
        <Check className="mx-auto h-5 w-5 text-epilist-green" />
      ) : (
        <X className="mx-auto h-5 w-5 text-gray-300" />
      )
    ) : (
      <span
        className={
          highlight ? "font-semibold text-epilist-green" : "text-gray-600"
        }
      >
        {value}
      </span>
    );

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="pt-32 pb-20">
        <div className="container mx-auto px-4">
          <div className="mx-auto max-w-2xl text-center mb-14">
            <h1 className="text-4xl md:text-5xl font-bold text-gray-900 tracking-tight mb-5">
              {t("cmpTitle")}
            </h1>
            <p className="text-lg text-gray-600">{t("cmpSubtitle")}</p>
          </div>

          {/* Tableau */}
          <div className="mx-auto max-w-5xl overflow-x-auto">
            <table className="w-full overflow-hidden rounded-2xl border border-gray-200 bg-white text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="p-5 text-left font-semibold text-gray-900">
                    {t("cmpColFeatures")}
                  </th>
                  {apps.map((app) => (
                    <th
                      key={app.name}
                      className={`p-5 text-center ${
                        app.highlight ? "bg-green-50" : ""
                      }`}
                    >
                      <div className="flex flex-col items-center gap-2">
                        <span
                          className={`flex h-9 w-9 items-center justify-center rounded-xl text-sm font-bold ${
                            app.highlight
                              ? "bg-epilist-green text-white"
                              : "bg-gray-100 text-gray-600"
                          }`}
                        >
                          {app.name.charAt(0)}
                        </span>
                        <span
                          className={
                            app.highlight
                              ? "font-bold text-epilist-green"
                              : "font-semibold text-gray-900"
                          }
                        >
                          {app.name}
                        </span>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => (
                  <tr
                    key={i}
                    className={`border-t border-gray-100 ${
                      i % 2 === 0 ? "bg-white" : "bg-gray-50/50"
                    }`}
                  >
                    <td className="p-5 font-medium text-gray-900">
                      {row.label}
                    </td>
                    {row.values.map((value, j) => (
                      <td
                        key={j}
                        className={`p-5 text-center ${
                          apps[j].highlight ? "bg-green-50/60" : ""
                        }`}
                      >
                        {cell(value, apps[j].highlight)}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pourquoi EpiList */}
          <div className="mt-16">
            <Card className="mx-auto max-w-4xl border border-gray-200 shadow-sm">
              <CardContent className="p-10">
                <h2 className="mb-8 text-center text-2xl font-bold text-gray-900">
                  {t("cmpWhyTitle")}
                </h2>
                <div className="grid gap-8 md:grid-cols-3">
                  {why.map((item, i) => (
                    <div key={i} className="text-center">
                      <div className="mx-auto mb-3 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                        <item.icon className="h-5 w-5" />
                      </div>
                      <h3 className="mb-1 font-semibold text-gray-900">
                        {item.title}
                      </h3>
                      <p className="text-sm text-gray-600">{item.desc}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
