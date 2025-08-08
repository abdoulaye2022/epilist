"use client";

import { Card, CardContent } from "@/components/ui/card";
import { Check, X, Star, DollarSign, Users, Wifi } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function ComparisonContent() {
  const features = [
    {
      name: "Prix",
      epilist: "Gratuit à vie",
      anylist: "9.99$/mois",
      cozi: "4.99$/mois",
      our: "2.99$/mois",
    },
    {
      name: "Sync famille",
      epilist: true,
      anylist: true,
      cozi: true,
      our: true,
    },
    {
      name: "Mode hors ligne",
      epilist: true,
      anylist: false,
      cozi: false,
      our: true,
    },
    {
      name: "Sans publicité",
      epilist: true,
      anylist: false,
      cozi: false,
      our: false,
    },
    {
      name: "IA suggestions",
      epilist: true,
      anylist: true,
      cozi: false,
      our: false,
    },
    {
      name: "Support 24/7",
      epilist: true,
      anylist: false,
      cozi: false,
      our: false,
    },
  ];

  const apps = [
    {
      name: "EpiList",
      logo: "🛒",
      rating: "4.9",
      color: "from-green-500 to-blue-500",
      highlight: true,
    },
    {
      name: "AnyList",
      logo: "📝",
      rating: "4.7",
      color: "from-orange-500 to-red-500",
    },
    {
      name: "Cozi",
      logo: "🏠",
      rating: "4.5",
      color: "from-purple-500 to-pink-500",
    },
    {
      name: "OurGroceries",
      logo: "🍎",
      rating: "4.3",
      color: "from-blue-500 to-indigo-500",
    },
  ];

  return (
    <main className="min-h-screen">
      <Header />

      <section className="pt-32 pb-24 bg-gradient-to-br from-white via-gray-50 to-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h1 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
              Pourquoi choisir{" "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                EpiList ?
              </span>
            </h1>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Comparaison objective avec les principales applications de courses
              2025
            </p>
          </div>

          {/* Comparison Table */}
          <div className="max-w-6xl mx-auto overflow-x-auto">
            <table className="w-full bg-white rounded-2xl shadow-xl overflow-hidden">
              <thead>
                <tr className="bg-gradient-to-r from-gray-50 to-gray-100">
                  <th className="p-6 text-left font-semibold text-gray-900">
                    Fonctionnalités
                  </th>
                  {apps.map((app, i) => (
                    <th
                      key={i}
                      className={`p-6 text-center ${
                        app.highlight
                          ? "bg-gradient-to-r from-green-50 to-blue-50"
                          : ""
                      }`}
                    >
                      <div className="flex flex-col items-center">
                        <div className="text-3xl mb-2">{app.logo}</div>
                        <div
                          className={`font-bold ${
                            app.highlight ? "text-green-600" : "text-gray-900"
                          }`}
                        >
                          {app.name}
                        </div>
                        <div className="flex items-center mt-1">
                          <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                          <span className="text-sm ml-1">{app.rating}</span>
                        </div>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {features.map((feature, i) => (
                  <tr
                    key={i}
                    className={`border-t ${
                      i % 2 === 0 ? "bg-gray-50/50" : "bg-white"
                    }`}
                  >
                    <td className="p-6 font-medium text-gray-900">
                      {feature.name}
                    </td>
                    <td className="p-6 text-center bg-gradient-to-r from-green-50 to-blue-50">
                      {typeof feature.epilist === "boolean" ? (
                        feature.epilist ? (
                          <Check className="h-6 w-6 text-green-500 mx-auto" />
                        ) : (
                          <X className="h-6 w-6 text-red-500 mx-auto" />
                        )
                      ) : (
                        <span className="font-semibold text-green-600">
                          {feature.epilist}
                        </span>
                      )}
                    </td>
                    <td className="p-6 text-center">
                      {typeof feature.anylist === "boolean" ? (
                        feature.anylist ? (
                          <Check className="h-6 w-6 text-green-500 mx-auto" />
                        ) : (
                          <X className="h-6 w-6 text-red-500 mx-auto" />
                        )
                      ) : (
                        <span className="text-gray-600">{feature.anylist}</span>
                      )}
                    </td>
                    <td className="p-6 text-center">
                      {typeof feature.cozi === "boolean" ? (
                        feature.cozi ? (
                          <Check className="h-6 w-6 text-green-500 mx-auto" />
                        ) : (
                          <X className="h-6 w-6 text-red-500 mx-auto" />
                        )
                      ) : (
                        <span className="text-gray-600">{feature.cozi}</span>
                      )}
                    </td>
                    <td className="p-6 text-center">
                      {typeof feature.our === "boolean" ? (
                        feature.our ? (
                          <Check className="h-6 w-6 text-green-500 mx-auto" />
                        ) : (
                          <X className="h-6 w-6 text-red-500 mx-auto" />
                        )
                      ) : (
                        <span className="text-gray-600">{feature.our}</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Why EpiList */}
          <div className="mt-20">
            <Card className="max-w-4xl mx-auto border-0 shadow-2xl bg-gradient-to-br from-green-50 to-blue-50">
              <CardContent className="p-12 text-center">
                <h2 className="text-3xl font-bold text-gray-900 mb-8">
                  Pourquoi 50k+ familles choisissent EpiList
                </h2>
                <div className="grid md:grid-cols-3 gap-8">
                  {[
                    {
                      icon: DollarSign,
                      title: "100% Gratuit",
                      desc: "Pas de piège, pas d'abonnement caché",
                    },
                    {
                      icon: Wifi,
                      title: "Fonctionne partout",
                      desc: "Mode hors ligne complet",
                    },
                    {
                      icon: Users,
                      title: "Fait au Canada",
                      desc: "Pour les familles canadiennes",
                    },
                  ].map((item, i) => (
                    <div key={i} className="text-center">
                      <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                        <item.icon className="h-8 w-8 text-white" />
                      </div>
                      <h3 className="text-xl font-bold text-gray-900 mb-2">
                        {item.title}
                      </h3>
                      <p className="text-gray-600">{item.desc}</p>
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
