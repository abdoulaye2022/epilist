"use client";

import { useLanguage } from "@/hooks/useLanguage";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  ArrowLeft,
  Shield,
  Eye,
  Lock,
  Database,
  Users,
  Mail,
  Phone,
  MapPin,
  CheckCircle,
  AlertCircle,
  FileText,
  Settings,
  Share2,
  Calculator,
} from "lucide-react";
import Link from "next/link";

export default function PrivacyContent() {
  const { t } = useLanguage();

  const privacySections = [
    {
      icon: Database,
      titleKey: "dataCollectionTitle",
      contentKey: "dataCollectionContent",
      color: "from-blue-500 to-blue-600",
      bgColor: "bg-blue-50",
    },
    {
      icon: Settings,
      titleKey: "dataUsageTitle",
      contentKey: "dataUsageContent",
      color: "from-green-500 to-green-600",
      bgColor: "bg-green-50",
    },
    {
      icon: Lock,
      titleKey: "dataSecurityTitle",
      contentKey: "dataSecurityContent",
      color: "from-purple-500 to-purple-600",
      bgColor: "bg-purple-50",
    },
    {
      icon: Share2,
      titleKey: "dataSharingTitle",
      contentKey: "dataSharingContent",
      color: "from-orange-500 to-orange-600",
      bgColor: "bg-orange-50",
    },
    {
      icon: Shield,
      titleKey: "userRightsTitle",
      contentKey: "userRightsContent",
      color: "from-indigo-500 to-indigo-600",
      bgColor: "bg-indigo-50",
    },
    {
      icon: Calculator,
      titleKey: "appFeaturesTitle",
      contentKey: "appFeaturesContent",
      color: "from-teal-500 to-teal-600",
      bgColor: "bg-teal-50",
    },
    {
      icon: Eye,
      titleKey: "cookiesTitle",
      contentKey: "cookiesContent",
      color: "from-pink-500 to-pink-600",
      bgColor: "bg-pink-50",
    },
    {
      icon: FileText,
      titleKey: "modificationsTitle",
      contentKey: "modificationsContent",
      color: "from-gray-500 to-gray-600",
      bgColor: "bg-gray-50",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-blue-600 via-purple-600 to-blue-800 text-white overflow-hidden">
        <div className="absolute inset-0 bg-black/20"></div>
        <div className="absolute inset-0">
          <div className="absolute top-20 left-20 w-64 h-64 bg-white/10 rounded-full blur-3xl animate-float"></div>
          <div className="absolute bottom-20 right-20 w-80 h-80 bg-white/10 rounded-full blur-3xl animate-float-reverse"></div>
        </div>

        <div className="container mx-auto px-4 py-20 relative z-10">
          <Link href="/">
            <Button
              variant="ghost"
              className="text-white hover:bg-white/20 mb-8 group"
            >
              <ArrowLeft className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
              {t("backToHome")}
            </Button>
          </Link>

          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-8">
              <Shield className="h-10 w-10" />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white to-blue-100 bg-clip-text text-transparent">
              {t("privacyPolicyTitle")}
            </h1>
            <p className="text-xl md:text-2xl text-blue-100 max-w-3xl mx-auto leading-relaxed">
              {t("privacyPolicySubtitle")}
            </p>
            <div className="mt-8 inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-6 py-3">
              <CheckCircle className="h-5 w-5 text-green-300" />
              <span className="text-white/90">
                {t("lastUpdated")}:{" "}
                {t("language") === "fr" ? "5 juillet 2025" : "July 5, 2025"}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Content Sections */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          {/* Trust Indicators */}
          <div className="grid md:grid-cols-3 gap-6 mb-16">
            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-green-100">
              <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Lock className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">
                {t("bankLevelSecurity")}
              </h3>
              <p className="text-gray-600 text-sm">{t("encryptedStorage")}</p>
            </div>

            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-blue-100">
              <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">
                {t("dataProtection")}
              </h3>
              <p className="text-gray-600 text-sm">{t("industryStandards")}</p>
            </div>

            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-purple-100">
              <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">
                {t("userControl")}
              </h3>
              <p className="text-gray-600 text-sm">{t("fullDataControl")}</p>
            </div>
          </div>

          {/* Privacy Sections */}
          <div className="space-y-8">
            {privacySections.map((section, index) => (
              <Card
                key={index}
                className="overflow-hidden shadow-xl border-0 hover:shadow-2xl transition-all duration-300"
              >
                <CardContent className="p-0">
                  <div
                    className={`${section.bgColor} p-8 border-l-4 border-l-current`}
                  >
                    <div className="flex items-start space-x-6">
                      <div
                        className={`w-16 h-16 bg-gradient-to-r ${section.color} rounded-2xl flex items-center justify-center flex-shrink-0 shadow-lg`}
                      >
                        <section.icon className="h-8 w-8 text-white" />
                      </div>
                      <div className="flex-1">
                        <h2 className="text-3xl font-bold text-gray-900 mb-4">
                          {t(section.titleKey as any)}
                        </h2>
                        <div className="prose prose-lg max-w-none text-gray-700">
                          <div className="whitespace-pre-line leading-relaxed">
                            {t(section.contentKey as any)}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Contact Section */}
          <div className="mt-16">
            <Card className="overflow-hidden shadow-xl border-0">
              <CardContent className="p-0">
                <div className="bg-gradient-to-r from-epilist-green/10 to-epilist-blue/10 p-8 border-l-4 border-l-epilist-green">
                  <div className="flex items-start space-x-6">
                    <div className="w-16 h-16 bg-gradient-to-r from-epilist-green to-epilist-blue rounded-2xl flex items-center justify-center flex-shrink-0 shadow-lg">
                      <Mail className="h-8 w-8 text-white" />
                    </div>
                    <div className="flex-1">
                      <h2 className="text-3xl font-bold text-gray-900 mb-4">
                        {t("contactTitle")}
                      </h2>
                      <p className="text-gray-700 leading-relaxed mb-6">
                        {t("contactContent")}
                      </p>
                      <Link href="/contact">
                        <Button className="bg-gradient-epilist hover:shadow-glow-green text-white transition-all duration-300">
                          <Mail className="mr-2 h-4 w-4" />
                          {t("contact")}
                        </Button>
                      </Link>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Copyright */}
          <div className="text-center mt-16">
            <p className="text-gray-500 text-sm">
              © 2025 EpiList - {t("allRightsReserved")}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
