"use client";

import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import {
  ChevronDown,
  ChevronRight,
  MessageCircle,
  Book,
  Video,
  Phone,
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function HelpContent() {
  const [openFAQ, setOpenFAQ] = useState<number | null>(0);

  const faqs = [
    {
      question: "EpiList est-elle vraiment gratuite ?",
      answer:
        "Oui, EpiList est 100% gratuite à vie ! Aucun frais caché, aucun abonnement, aucune publicité. Nous croyons que l'organisation familiale devrait être accessible à tous.",
    },
    {
      question: "Comment synchroniser mes listes avec ma famille ?",
      answer:
        "Créez votre liste et partagez-la avec un code unique. Invitez les membres de votre famille via email ou SMS. Tous les changements sont synchronisés instantanément.",
    },
    {
      question: "L'application fonctionne-t-elle hors ligne ?",
      answer:
        "Absolument ! EpiList fonctionne parfaitement sans connexion. Vos listes sont stockées localement et se synchronisent dès que vous retrouvez internet.",
    },
    {
      question: "Sur quelles plateformes EpiList est disponible ?",
      answer:
        "EpiList est disponible sur iOS (App Store), Android (Google Play) et bientôt en version web. Synchronisation parfaite entre tous vos appareils.",
    },
    {
      question: "Mes données sont-elles sécurisées ?",
      answer:
        "Oui ! Vos données sont chiffrées de bout en bout. Nous ne vendons jamais vos informations et respectons strictement la confidentialité de votre famille.",
    },
  ];

  return (
    <main className="min-h-screen">
      <Header />

      <section className="pt-32 pb-24 bg-gradient-to-br from-white via-gray-50 to-white">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
              Centre d'{" "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                aide
              </span>
            </h1>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Trouvez rapidement les réponses à vos questions ou contactez notre
              équipe du Nouveau-Brunswick.
            </p>
          </div>

          {/* Quick Help Cards */}
          <div className="grid md:grid-cols-3 gap-8 mb-16">
            {[
              {
                icon: Book,
                title: "Documentation",
                desc: "Guides complets et tutoriels",
                color: "from-blue-500 to-blue-400",
              },
              {
                icon: Video,
                title: "Vidéos",
                desc: "Tutoriels vidéo étape par étape",
                color: "from-green-500 to-green-400",
              },
              {
                icon: MessageCircle,
                title: "Support",
                desc: "Réponse garantie sous 24h",
                color: "from-purple-500 to-purple-400",
              },
            ].map((item, i) => (
              <Card
                key={i}
                className="group hover:shadow-xl transition-all duration-300 cursor-pointer"
              >
                <CardContent className="p-8 text-center">
                  <div
                    className={`w-16 h-16 bg-gradient-to-br ${item.color} rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform`}
                  >
                    <item.icon className="h-8 w-8 text-white" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-600">{item.desc}</p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* FAQ Section */}
          <div className="max-w-4xl mx-auto">
            <h2 className="text-3xl font-bold text-gray-900 mb-8 text-center">
              Questions fréquentes
            </h2>
            <div className="space-y-4">
              {faqs.map((faq, index) => (
                <Card key={index} className="overflow-hidden">
                  <CardContent className="p-0">
                    <button
                      onClick={() =>
                        setOpenFAQ(openFAQ === index ? null : index)
                      }
                      className="w-full p-6 text-left flex items-center justify-between hover:bg-gray-50 transition-colors"
                    >
                      <h3 className="text-lg font-semibold text-gray-900 pr-4">
                        {faq.question}
                      </h3>
                      {openFAQ === index ? (
                        <ChevronDown className="h-5 w-5 text-green-500 flex-shrink-0" />
                      ) : (
                        <ChevronRight className="h-5 w-5 text-gray-400 flex-shrink-0" />
                      )}
                    </button>
                    {openFAQ === index && (
                      <div className="px-6 pb-6">
                        <p className="text-gray-600 leading-relaxed">
                          {faq.answer}
                        </p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* Contact Section */}
          <div className="text-center mt-16">
            <Card className="max-w-2xl mx-auto">
              <CardContent className="p-8">
                <Phone className="h-12 w-12 text-green-500 mx-auto mb-4" />
                <h3 className="text-2xl font-bold text-gray-900 mb-4">
                  Besoin d'aide personnalisée ?
                </h3>
                <p className="text-gray-600 mb-6">
                  Notre équipe basée au Nouveau-Brunswick est là pour vous
                  aider. Support gratuit 24/7.
                </p>
                <div className="flex flex-col sm:flex-row gap-4 justify-center">
                  <span className="text-green-600 font-medium">
                    📧 support@epilist.app
                  </span>
                  <span className="text-blue-600 font-medium">
                    ⏱️ Réponse sous 24h
                  </span>
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
