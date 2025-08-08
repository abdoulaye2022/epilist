"use client";

import { useState, useEffect } from "react";
import { Card, CardContent } from "@/components/ui/card";
import {
  ListChecks,
  Share2,
  Copy,
  Shield,
  Clock,
  Users,
  Smartphone,
  Zap,
  Heart,
  DollarSign,
  BarChart3,
  Lock,
  Wifi,
  WifiOff,
  Bell,
  Star,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function FeaturesContent() {
  const [activeTab, setActiveTab] = useState("all");
  const { t } = useLanguage();

  const features = [
    {
      icon: Users,
      title: "Synchronisation Familiale",
      desc: "Partagez vos listes avec toute la famille. Modifications synchronisées en temps réel.",
      category: "collaboration",
    },
    {
      icon: WifiOff,
      title: "Mode Hors Ligne",
      desc: "Utilisez EpiList même sans connexion. Synchronisation automatique au retour.",
      category: "essential",
    },
    {
      icon: Zap,
      title: "Suggestions Intelligentes",
      desc: "IA qui apprend vos habitudes et suggère automatiquement vos produits usuels.",
      category: "smart",
    },
    {
      icon: Shield,
      title: "Sécurité Totale",
      desc: "Vos données familiales sont chiffrées et protégées. Conformité RGPD garantie.",
      category: "security",
    },
    {
      icon: Bell,
      title: "Notifications Contextuelles",
      desc: "Rappels intelligents basés sur votre localisation et vos habitudes.",
      category: "smart",
    },
    {
      icon: Copy,
      title: "Duplication de Listes",
      desc: "Dupliquez vos listes récurrentes en un clic. Parfait pour les courses hebdomadaires.",
      category: "essential",
    },
  ];

  return (
    <main className="min-h-screen">
      <Header />

      <section className="pt-32 pb-24 bg-gradient-to-br from-white via-gray-50 to-white relative overflow-hidden">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <div className="inline-flex items-center space-x-2 bg-gradient-to-r from-green-500 to-blue-500 text-white px-6 py-3 rounded-full text-sm font-medium mb-6">
              <Smartphone className="h-4 w-4" />
              <span>Fonctionnalités avancées</span>
            </div>

            <h1 className="text-5xl md:text-7xl font-bold text-gray-900 mb-6">
              Toutes les{" "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                fonctionnalités
              </span>
            </h1>

            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Découvrez pourquoi 50k+ familles canadiennes font confiance à
              EpiList pour simplifier leurs courses quotidiennes.
            </p>
          </div>

          {/* Features Grid */}
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-20">
            {features.map((feature, index) => (
              <Card
                key={index}
                className="group hover:shadow-2xl transition-all duration-500 border-0 shadow-lg bg-white/90 backdrop-blur-sm hover:bg-white hover:scale-105"
              >
                <CardContent className="p-8">
                  <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-500 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-all duration-300">
                    <feature.icon className="h-8 w-8 text-white" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-4">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600 leading-relaxed">
                    {feature.desc}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            {[
              { number: "6+", label: "Fonctionnalités principales" },
              { number: "100%", label: "Gratuit à vie" },
              { number: "24/7", label: "Synchronisation" },
              { number: "4.9⭐", label: "Note moyenne" },
            ].map((stat, i) => (
              <div key={i}>
                <div className="text-4xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent mb-2">
                  {stat.number}
                </div>
                <div className="text-gray-600 font-medium">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
