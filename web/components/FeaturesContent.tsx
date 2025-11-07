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
  Coins,
  KeyRound,
  FolderOpen,
  TrendingUp,
  Mail,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function FeaturesContent() {
  const [activeTab, setActiveTab] = useState("all");
  const { t } = useLanguage();

  const features = [
    {
      icon: ListChecks,
      title: t("feature1Title"),
      desc: t("feature1Desc"),
      category: "essential",
    },
    {
      icon: Share2,
      title: t("feature2Title"),
      desc: t("feature2Desc"),
      category: "collaboration",
    },
    {
      icon: Copy,
      title: t("feature3Title"),
      desc: t("feature3Desc"),
      category: "essential",
    },
    {
      icon: DollarSign,
      title: t("feature4Title"),
      desc: t("feature4Desc"),
      category: "advanced",
    },
    {
      icon: BarChart3,
      title: t("feature5Title"),
      desc: t("feature5Desc"),
      category: "analytics",
    },
    {
      icon: Lock,
      title: t("feature6Title"),
      desc: t("feature6Desc"),
      category: "security",
    },
    {
      icon: Users,
      title: t("feature7Title"),
      desc: t("feature7Desc"),
      category: "collaboration",
    },
    {
      icon: WifiOff,
      title: t("feature8Title"),
      desc: t("feature8Desc"),
      category: "advanced",
    },
    {
      icon: Coins,
      title: t("feature9Title"),
      desc: t("feature9Desc"),
      category: "advanced",
    },
    {
      icon: KeyRound,
      title: t("feature10Title"),
      desc: t("feature10Desc"),
      category: "security",
    },
    {
      icon: FolderOpen,
      title: t("feature11Title"),
      desc: t("feature11Desc"),
      category: "essential",
    },
    {
      icon: Bell,
      title: t("feature12Title"),
      desc: t("feature12Desc"),
      category: "collaboration",
    },
    {
      icon: TrendingUp,
      title: t("feature13Title"),
      desc: t("feature13Desc"),
      category: "analytics",
    },
    {
      icon: Mail,
      title: t("feature14Title"),
      desc: t("feature14Desc"),
      category: "advanced",
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
              {t("language") === "fr" ? "Toutes les " : "All "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                {t("language") === "fr" ? "fonctionnalités" : "features"}
              </span>
            </h1>

            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              {t("language") === "fr"
                ? "Découvrez pourquoi 50k+ familles canadiennes font confiance à EpiList pour simplifier leurs courses quotidiennes."
                : "Discover why 50k+ Canadian families trust EpiList to simplify their daily shopping."}
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
              {
                number: "14+",
                label:
                  t("language") === "fr"
                    ? "Fonctionnalités principales"
                    : "Main Features",
              },
              {
                number: "150+",
                label:
                  t("language") === "fr"
                    ? "Devises supportées"
                    : "Supported Currencies",
              },
              {
                number: "24/7",
                label:
                  t("language") === "fr" ? "Synchronisation" : "Sync",
              },
              {
                number: "4.9⭐",
                label:
                  t("language") === "fr" ? "Note moyenne" : "Average Rating",
              },
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
