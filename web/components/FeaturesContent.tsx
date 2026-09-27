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
  Mic,
  CheckCheck,
  Lightbulb,
  ScanBarcode,
  MessageSquare,
  Receipt,
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
    {
      icon: Mic,
      title: t("feature15Title"),
      desc: t("feature15Desc"),
      category: "essential",
    },
    {
      icon: CheckCheck,
      title: t("feature16Title"),
      desc: t("feature16Desc"),
      category: "advanced",
    },
    {
      icon: Lightbulb,
      title: t("feature17Title"),
      desc: t("feature17Desc"),
      category: "analytics",
    },
    {
      icon: ScanBarcode,
      title: t("feature18Title"),
      desc: t("feature18Desc"),
      category: "essential",
    },
    {
      icon: MessageSquare,
      title: t("feature19Title"),
      desc: t("feature19Desc"),
      category: "collaboration",
    },
    {
      icon: Receipt,
      title: t("feature20Title"),
      desc: t("feature20Desc"),
      category: "advanced",
    },
  ];

  return (
    <main className="min-h-screen">
      <Header />

      <section className="pt-32 pb-24 bg-gradient-to-br from-white via-gray-50 to-white relative overflow-hidden">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <div className="inline-flex items-center space-x-2 rounded-full border border-green-200 bg-green-50 px-4 py-1.5 text-sm font-medium text-green-700 mb-6">
              <Smartphone className="h-4 w-4" />
              <span>{t("advancedFeatures")}</span>
            </div>

            <h1 className="text-5xl md:text-7xl font-bold text-gray-900 mb-6">
              {t("language") === "fr" ? "Toutes les " : "All "}
              <span className="text-epilist-green">
                {t("language") === "fr" ? "fonctionnalités" : "features"}
              </span>
            </h1>

            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              {t("language") === "fr"
                ? "Tout ce qu\u2019EpiList peut faire pour simplifier vos courses au quotidien."
                : "Everything EpiList can do to simplify your everyday groceries."}
            </p>
          </div>

          {/* Features Grid */}
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 mb-20">
            {features.map((feature, index) => (
              <Card
                key={index}
                className="group border border-gray-200 shadow-none transition-all duration-200 hover:border-green-300 hover:shadow-md"
              >
                <CardContent className="p-8">
                  <div className="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center mb-5">
                    <feature.icon className="h-6 w-6 text-epilist-green" />
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
                number: "20+",
                label:
                  t("language") === "fr"
                    ? "Fonctionnalités"
                    : "Features",
              },
              {
                number: "2",
                label:
                  t("language") === "fr"
                    ? "Langues" : "Languages",
              },
              {
                number: "150+",
                label:
                  t("language") === "fr"
                    ? "Devises supportées"
                    : "Supported currencies",
              },
              {
                number: "100 %",
                label:
                  t("language") === "fr"
                    ? "Gratuite, sans publicité"
                    : "Free, ad-free",
              },
            ].map((stat, i) => (
              <div key={i}>
                <div className="text-4xl font-bold text-epilist-green mb-2">
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
