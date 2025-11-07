"use client";

import { Card, CardContent } from "@/components/ui/card";
import { MapPin, Users, Heart, Award, Target, Zap } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";

export default function AboutContent() {
  const values = [
    {
      icon: Heart,
      title: "Famille d'abord",
      desc: "Nous créons des outils qui renforcent les liens familiaux et simplifient le quotidien.",
    },
    {
      icon: Zap,
      title: "Innovation locale",
      desc: "Startup tech fièrement basée au Nouveau-Brunswick, nous innovons depuis les Maritimes.",
    },
    {
      icon: Users,
      title: "Communauté",
      desc: "200+ utilisateurs actifs nous font confiance. Chaque retour nous aide à améliorer EpiList.",
    },
  ];

  const stats = [
    { number: "2024", label: "Année de création" },
    { number: "200+", label: "Utilisateurs actifs" },
    { number: "4.9⭐", label: "Note app stores" },
    { number: "100%", label: "Gratuit à vie" },
  ];

  return (
    <main className="min-h-screen">
      <Header />

      <section className="pt-32 pb-24 bg-gradient-to-br from-white via-gray-50 to-white">
        <div className="container mx-auto px-4">
          {/* Hero */}
          <div className="text-center mb-20">
            <div className="inline-flex items-center space-x-2 bg-gradient-to-r from-green-500 to-blue-500 text-white px-6 py-3 rounded-full text-sm font-medium mb-6">
              <MapPin className="h-4 w-4" />
              <span>Nouveau-Brunswick, Canada</span>
            </div>

            <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
              À propos d'{" "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                EpiList
              </span>
            </h1>

            <p className="text-xl text-gray-600 max-w-3xl mx-auto mb-12">
              Nous sommes une équipe passionnée basée au Nouveau-Brunswick,
              dédiée à simplifier la vie des familles canadiennes grâce à la
              technologie.
            </p>
          </div>

          {/* Mission */}
          <div className="max-w-4xl mx-auto mb-20">
            <Card className="border-0 shadow-xl bg-gradient-to-br from-white to-gray-50">
              <CardContent className="p-12 text-center">
                <Target className="h-16 w-16 text-green-500 mx-auto mb-6" />
                <h2 className="text-3xl font-bold text-gray-900 mb-6">
                  Notre Mission
                </h2>
                <p className="text-xl text-gray-600 leading-relaxed">
                  Révolutionner la façon dont les familles s'organisent au
                  quotidien. EpiList n'est pas qu'une app de courses, c'est un
                  outil qui renforce les liens familiaux en simplifiant les
                  tâches du quotidien.
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Values */}
          <div className="mb-20">
            <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">
              Nos Valeurs
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              {values.map((value, index) => (
                <Card
                  key={index}
                  className="group hover:shadow-xl transition-all duration-300"
                >
                  <CardContent className="p-8 text-center">
                    <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-500 rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform">
                      <value.icon className="h-8 w-8 text-white" />
                    </div>
                    <h3 className="text-xl font-bold text-gray-900 mb-4">
                      {value.title}
                    </h3>
                    <p className="text-gray-600 leading-relaxed">
                      {value.desc}
                    </p>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* Stats */}
          <div className="mb-20">
            <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">
              EpiList en chiffres
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
              {stats.map((stat, index) => (
                <div
                  key={index}
                  className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg"
                >
                  <div className="text-4xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent mb-2">
                    {stat.number}
                  </div>
                  <div className="text-gray-600 font-medium">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Team */}
          <div className="text-center">
            <Card className="max-w-3xl mx-auto">
              <CardContent className="p-12">
                <Award className="h-16 w-16 text-green-500 mx-auto mb-6" />
                <h2 className="text-3xl font-bold text-gray-900 mb-6">
                  Équipe Maritime
                </h2>
                <p className="text-xl text-gray-600 leading-relaxed mb-8">
                  Fiers de représenter l'innovation technologique des Maritimes
                  ! Notre équipe diversifiée combine expertise technique et
                  compréhension profonde des besoins des familles canadiennes.
                </p>
                <div className="bg-gradient-to-r from-green-50 to-blue-50 rounded-xl p-6">
                  <p className="text-lg text-gray-700">
                    💡 <strong>Saviez-vous ?</strong> EpiList a été conçue et
                    développée entièrement au Nouveau-Brunswick, contribuant à
                    l'écosystème tech maritime.
                  </p>
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
