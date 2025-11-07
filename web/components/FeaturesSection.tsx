"use client";

import { useEffect, useState } from "react";
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
  WifiOff,
  Coins,
  KeyRound,
  FolderOpen,
  Bell,
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

const features = [
  {
    icon: ListChecks,
    titleKey: "feature1Title",
    descKey: "feature1Desc",
    color: "from-green-500 to-green-400",
    delay: 0,
    category: "essential",
  },
  {
    icon: Share2,
    titleKey: "feature2Title",
    descKey: "feature2Desc",
    color: "from-blue-500 to-blue-400",
    delay: 100,
    category: "collaborative",
  },
  {
    icon: Copy,
    titleKey: "feature3Title",
    descKey: "feature3Desc",
    color: "from-green-500 to-green-400",
    delay: 200,
    category: "essential",
  },
  {
    icon: DollarSign,
    titleKey: "feature4Title",
    descKey: "feature4Desc",
    color: "from-emerald-500 to-emerald-400",
    delay: 300,
    category: "advanced",
  },
  {
    icon: BarChart3,
    titleKey: "feature5Title",
    descKey: "feature5Desc",
    color: "from-blue-500 to-blue-400",
    delay: 400,
    category: "analytics",
  },
  {
    icon: Lock,
    titleKey: "feature6Title",
    descKey: "feature6Desc",
    color: "from-purple-500 to-purple-400",
    delay: 500,
    category: "security",
  },
  {
    icon: Users,
    titleKey: "feature7Title",
    descKey: "feature7Desc",
    color: "from-indigo-500 to-indigo-400",
    delay: 600,
    category: "collaborative",
  },
  {
    icon: WifiOff,
    titleKey: "feature8Title",
    descKey: "feature8Desc",
    color: "from-teal-500 to-teal-400",
    delay: 700,
    category: "advanced",
  },
  {
    icon: Coins,
    titleKey: "feature9Title",
    descKey: "feature9Desc",
    color: "from-emerald-500 to-emerald-400",
    delay: 800,
    category: "advanced",
  },
  {
    icon: KeyRound,
    titleKey: "feature10Title",
    descKey: "feature10Desc",
    color: "from-blue-500 to-blue-400",
    delay: 900,
    category: "security",
  },
  {
    icon: FolderOpen,
    titleKey: "feature11Title",
    descKey: "feature11Desc",
    color: "from-purple-500 to-purple-400",
    delay: 1000,
    category: "essential",
  },
  {
    icon: Bell,
    titleKey: "feature12Title",
    descKey: "feature12Desc",
    color: "from-red-500 to-red-400",
    delay: 1100,
    category: "collaborative",
  },
  {
    icon: TrendingUp,
    titleKey: "feature13Title",
    descKey: "feature13Desc",
    color: "from-indigo-500 to-indigo-400",
    delay: 1200,
    category: "analytics",
  },
  {
    icon: Mail,
    titleKey: "feature14Title",
    descKey: "feature14Desc",
    color: "from-pink-500 to-pink-400",
    delay: 1300,
    category: "advanced",
  },
  {
    icon: Mic,
    titleKey: "feature15Title",
    descKey: "feature15Desc",
    color: "from-green-500 to-green-400",
    delay: 1400,
    category: "essential",
  },
  {
    icon: CheckCheck,
    titleKey: "feature16Title",
    descKey: "feature16Desc",
    color: "from-blue-500 to-blue-400",
    delay: 1500,
    category: "advanced",
  },
  {
    icon: Lightbulb,
    titleKey: "feature17Title",
    descKey: "feature17Desc",
    color: "from-yellow-500 to-yellow-400",
    delay: 1600,
    category: "analytics",
  },
  {
    icon: ScanBarcode,
    titleKey: "feature18Title",
    descKey: "feature18Desc",
    color: "from-purple-500 to-purple-400",
    delay: 1700,
    category: "essential",
  },
  {
    icon: MessageSquare,
    titleKey: "feature19Title",
    descKey: "feature19Desc",
    color: "from-indigo-500 to-indigo-400",
    delay: 1800,
    category: "collaborative",
  },
  {
    icon: Receipt,
    titleKey: "feature20Title",
    descKey: "feature20Desc",
    color: "from-teal-500 to-teal-400",
    delay: 1900,
    category: "advanced",
  },
];

const categoryColors = {
  essential: "bg-green-100 text-green-800",
  collaborative: "bg-blue-100 text-blue-800",
  advanced: "bg-purple-100 text-purple-800",
  analytics: "bg-orange-100 text-orange-800",
  security: "bg-red-100 text-red-800",
};

const categoryLabels = {
  essential: "essentialFeatures",
  collaborative: "collaborativeTools",
  advanced: "advancedTools",
  analytics: "analyticsTools",
  security: "securityTools",
};

export default function FeaturesSection() {
  const [visibleItems, setVisibleItems] = useState<number[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const { t } = useLanguage();

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = parseInt(
              entry.target.getAttribute("data-feature-index") || "0"
            );
            setTimeout(() => {
              setVisibleItems((prev) => [...prev, index]);
            }, features[index].delay);
          }
        });
      },
      { threshold: 0.1 }
    );

    const elements = document.querySelectorAll("[data-feature-index]");
    elements.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  const filteredFeatures =
    selectedCategory === "all"
      ? features
      : features.filter((feature) => feature.category === selectedCategory);

  return (
    <section
      id="fonctionnalites"
      className="py-24 bg-gradient-to-br from-white via-gray-50 to-white relative overflow-hidden"
    >
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-10 w-72 h-72 bg-green-500/10 rounded-full blur-3xl animate-pulse"></div>
        <div
          className="absolute bottom-20 right-10 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl animate-pulse"
          style={{ animationDelay: "1s" }}
        ></div>
        <div
          className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-purple-500/5 rounded-full blur-3xl animate-pulse"
          style={{ animationDelay: "2s" }}
        ></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center space-x-2 bg-gradient-to-r from-green-500 to-blue-500 text-white px-6 py-3 rounded-full text-sm font-medium mb-6 shadow-lg">
            <Smartphone className="h-4 w-4" />
            <span>{t("advancedFeatures")}</span>
          </div>
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            {t("featuresTitle")}{" "}
            <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
              {t("featuresTitleHighlight")}
            </span>
          </h2>
          <p className="text-xl md:text-2xl text-gray-600 max-w-4xl mx-auto leading-relaxed">
            {t("featuresSubtitle")}
          </p>
        </div>

        {/* Category Filter */}
        <div className="flex flex-wrap justify-center gap-3 mb-12">
          <button
            onClick={() => setSelectedCategory("all")}
            className={`px-6 py-3 rounded-full text-sm font-medium transition-all duration-300 ${
              selectedCategory === "all"
                ? "bg-gradient-to-r from-green-500 to-blue-500 text-white shadow-lg scale-105"
                : "bg-white/80 text-gray-700 hover:bg-white hover:shadow-md"
            }`}
          >
            {t("language") === "fr"
              ? "Toutes les fonctionnalités"
              : "All Features"}
          </button>
          {Object.entries(categoryLabels).map(([key, labelKey]) => (
            <button
              key={key}
              onClick={() => setSelectedCategory(key)}
              className={`px-6 py-3 rounded-full text-sm font-medium transition-all duration-300 ${
                selectedCategory === key
                  ? "bg-gradient-to-r from-green-500 to-blue-500 text-white shadow-lg scale-105"
                  : "bg-white/80 text-gray-700 hover:bg-white hover:shadow-md"
              }`}
            >
              {t(labelKey as any)}
            </button>
          ))}
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {filteredFeatures.map((feature, index) => (
            <Card
              key={`${feature.titleKey}-${selectedCategory}`}
              data-feature-index={index}
              className={`group hover:shadow-2xl transition-all duration-500 cursor-pointer border-0 shadow-lg bg-white/90 backdrop-blur-sm hover:bg-white hover:scale-105 ${
                visibleItems.includes(index) || selectedCategory !== "all"
                  ? "animate-fade-in-up"
                  : "opacity-0"
              }`}
            >
              <CardContent className="p-8 relative overflow-hidden">
                {/* Category Badge */}
                <div
                  className={`absolute top-4 right-4 px-3 py-1 rounded-full text-xs font-medium ${
                    categoryColors[
                      feature.category as keyof typeof categoryColors
                    ]
                  }`}
                >
                  {t(
                    categoryLabels[
                      feature.category as keyof typeof categoryLabels
                    ] as any
                  )}
                </div>

                {/* Background Gradient */}
                <div
                  className={`absolute inset-0 bg-gradient-to-br ${feature.color} opacity-0 group-hover:opacity-5 transition-opacity duration-300`}
                ></div>

                {/* Icon */}
                <div className="relative mb-6">
                  <div
                    className={`w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl flex items-center justify-center group-hover:scale-110 group-hover:rotate-3 transition-all duration-300 shadow-lg`}
                  >
                    <feature.icon className="h-8 w-8 text-white" />
                  </div>
                  <div
                    className={`absolute inset-0 w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity duration-300`}
                  ></div>
                </div>

                {/* Content */}
                <div className="relative">
                  <h3 className="text-xl font-bold text-gray-900 mb-4 group-hover:text-green-600 transition-colors duration-300">
                    {t(feature.titleKey as any)}
                  </h3>
                  <p className="text-gray-600 leading-relaxed text-sm">
                    {t(feature.descKey as any)}
                  </p>
                </div>

                {/* Hover Effect */}
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-green-500 to-blue-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Statistics Section */}
        <div className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-8">
          {[
            {
              number: "20+",
              label:
                t("language") === "fr"
                  ? "Fonctionnalités"
                  : "Features",
            },
            {
              number: "200+",
              label:
                t("language") === "fr"
                  ? "Utilisateurs actifs"
                  : "Active Users",
            },
            {
              number: "4.9/5",
              label:
                t("language") === "fr"
                  ? "Note moyenne"
                  : "Average Rating",
            },
            {
              number: "450+",
              label:
                t("language") === "fr"
                  ? "Listes créées"
                  : "Lists Created",
            },
          ].map((stat, index) => (
            <div key={index} className="text-center">
              <div className="text-3xl md:text-4xl font-bold text-gray-900 mb-2 bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                {stat.number}
              </div>
              <div className="text-gray-600 text-sm font-medium">
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        {/* Enhanced Bottom CTA */}
        <div className="text-center mt-16">
          <div className="inline-flex items-center space-x-4 bg-gradient-to-r from-white/90 to-gray-50/90 backdrop-blur-sm rounded-2xl p-8 shadow-xl border border-white/20">
            <div className="flex space-x-2">
              {[...Array(5)].map((_, i) => (
                <div
                  key={i}
                  className="w-3 h-3 bg-gradient-to-r from-green-500 to-blue-500 rounded-full animate-pulse"
                  style={{ animationDelay: `${i * 0.3}s` }}
                ></div>
              ))}
            </div>
            <div className="text-center">
              <span className="text-gray-800 font-semibold text-lg block mb-1">
                {t("moreToDiscover")}
              </span>
              <span className="text-gray-600 text-sm">
                {t("language") === "fr"
                  ? "Explorez toutes nos fonctionnalités avancées"
                  : "Explore all our advanced features"}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
