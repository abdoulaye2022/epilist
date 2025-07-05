"use client";

import { useEffect, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { MapPin, Leaf, Users, Award, Flag, Globe } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

export default function NewBrunswickSection() {
  const [isVisible, setIsVisible] = useState(false);
  const { t } = useLanguage();

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsVisible(true);
          }
        });
      },
      { threshold: 0.1 }
    );

    const element = document.getElementById("nouveau-brunswick");
    if (element) observer.observe(element);

    return () => observer.disconnect();
  }, []);

  return (
    <section
      id="nouveau-brunswick"
      className="py-24 bg-gradient-to-br from-red-50 via-white to-red-50 relative overflow-hidden"
    >
      {/* Canadian Flag Colors Background */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-r from-red-500/10 to-red-600/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-gradient-to-r from-red-600/10 to-red-500/10 rounded-full blur-3xl animate-float-reverse"></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <div className="text-center mb-20">
          <div className="inline-flex items-center space-x-2 bg-gradient-to-r from-red-500 to-red-600 text-white px-6 py-2 rounded-full text-sm font-medium mb-6">
            <Flag className="h-4 w-4" />
            <span>{t("madeInCanada")}</span>
          </div>
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            {t("nbTitle")}{" "}
            <span className="bg-gradient-to-r from-red-500 to-red-600 bg-clip-text text-transparent">
              {t("nbTitleHighlight")}
            </span>
          </h2>
          <p className="text-xl md:text-2xl text-gray-600 max-w-3xl mx-auto leading-relaxed mb-8">
            {t("nbSubtitle")}
          </p>
          <p className="text-lg text-gray-600 max-w-4xl mx-auto leading-relaxed">
            {t("nbDescription")}
          </p>
        </div>

        {/* New Brunswick Features */}
        <div className="grid md:grid-cols-3 gap-8 mb-16">
          {[
            {
              icon: Award,
              title: t("nbFeature1"),
              description: t("nbFeature1Desc"),
              color: "from-red-500 to-red-600",
            },
            {
              icon: Globe,
              title: t("nbFeature2"),
              description: t("nbFeature2Desc"),
              color: "from-red-500 to-red-600",
            },
            {
              icon: Users,
              title: t("nbFeature3"),
              description: t("nbFeature3Desc"),
              color: "from-red-500 to-red-600",
            },
          ].map((feature, index) => (
            <Card
              key={index}
              className={`group hover:shadow-card-hover transition-all duration-500 cursor-pointer border-0 shadow-lg bg-white/80 backdrop-blur-sm hover:bg-white ${
                isVisible ? "animate-fade-in-up" : "opacity-0"
              }`}
              style={{ animationDelay: `${index * 200}ms` }}
            >
              <CardContent className="p-8 text-center relative overflow-hidden">
                {/* Background Pattern */}
                <div className="absolute inset-0 bg-red-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>

                {/* Icon */}
                <div className="relative mb-6">
                  <div
                    className={`w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl flex items-center justify-center group-hover:scale-110 group-hover:rotate-3 transition-all duration-300 shadow-lg mx-auto`}
                  >
                    <feature.icon className="h-8 w-8 text-white" />
                  </div>
                  <div
                    className={`absolute inset-0 w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity duration-300 mx-auto`}
                  ></div>
                </div>

                {/* Content */}
                <div className="relative">
                  <h3 className="text-xl font-bold text-gray-900 mb-4 group-hover:text-red-600 transition-colors duration-300">
                    {feature.title}
                  </h3>
                  <p className="text-gray-600 leading-relaxed">
                    {feature.description}
                  </p>
                </div>

                {/* Hover Effect */}
                <div
                  className={`absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r ${feature.color} transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-center`}
                ></div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* New Brunswick Map & Stats */}
        <div className="bg-white/80 backdrop-blur-sm rounded-3xl p-8 shadow-xl">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            {/* Map Side */}
            <div className="text-center">
              <div className="relative inline-block">
                <div className="w-64 h-64 bg-gradient-to-br from-red-500/20 to-red-600/20 rounded-full flex items-center justify-center mx-auto mb-6">
                  <MapPin className="h-24 w-24 text-red-600" />
                </div>
                <div className="absolute -top-4 -right-4 bg-red-600 text-white px-4 py-2 rounded-full text-sm font-bold animate-pulse-gentle">
                  🍁 Canada
                </div>
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-2">
                Fredericton, NB
              </h3>
              <p className="text-gray-600">{t("nbCapital")}</p>
            </div>

            {/* Stats Side */}
            <div className="space-y-6">
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                {t("nbWhyTitle")}
              </h3>
              <div className="space-y-4">
                {[
                  {
                    icon: "🏛️",
                    title: t("nbOfficiallyBilingual"),
                    desc: t("nbOfficiallyBilingualDesc"),
                  },
                  {
                    icon: "🌊",
                    title: t("nbMaritimeInnovation"),
                    desc: t("nbMaritimeInnovationDesc"),
                  },
                  {
                    icon: "👨‍👩‍👧‍👦",
                    title: t("nbFamilyValues"),
                    desc: t("nbFamilyValuesDesc"),
                  },
                  {
                    icon: "🌲",
                    title: t("nbQualityOfLife"),
                    desc: t("nbQualityOfLifeDesc"),
                  },
                ].map((item, index) => (
                  <div
                    key={index}
                    className="flex items-start space-x-4 p-4 bg-red-50/50 rounded-xl"
                  >
                    <div className="text-2xl">{item.icon}</div>
                    <div>
                      <h4 className="font-bold text-gray-900">{item.title}</h4>
                      <p className="text-gray-600 text-sm">{item.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
