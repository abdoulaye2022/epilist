"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import Image from "next/image";
import {
  Download,
  Star,
  ArrowDown,
  Play,
  Users,
  Clock,
  Shield,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

export default function HeroSection() {
  const [isVisible, setIsVisible] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const { t } = useLanguage();

  // URLs des stores
  const APP_STORE_URL =
    "https://apps.apple.com/ca/app/epilist/id6748285596?l=fr-CA";
  const GOOGLE_PLAY_URL =
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

  useEffect(() => {
    setIsVisible(true);

    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, []);

  const scrollToFeatures = () => {
    const element = document.getElementById("fonctionnalites");
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  // Fonction pour détecter l'appareil et ouvrir le bon store
  const handleDownload = () => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isAndroid = /Android/.test(navigator.userAgent);

    if (isIOS) {
      window.open(APP_STORE_URL, "_blank", "noopener,noreferrer");
    } else if (isAndroid) {
      window.open(GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
    } else {
      // Par défaut sur desktop, ouvrir Google Play
      window.open(GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
    }
  };

  // Fonction pour ouvrir la démo vidéo (peut être modifiée selon vos besoins)
  const handleWatchDemo = () => {
    // Remplacez par l'URL de votre vidéo de démo
    // Pour l'instant, on redirige vers Google Play aussi
    window.open(GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
  };

  return (
    <section className="min-h-screen bg-gradient-to-br from-white via-gray-50 to-white relative overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0">
        <div
          className="absolute w-96 h-96 bg-gradient-to-r from-green-500/20 to-blue-500/20 rounded-full blur-3xl animate-pulse"
          style={{
            left: `${20 + mousePosition.x * 0.02}%`,
            top: `${10 + mousePosition.y * 0.02}%`,
          }}
        ></div>
        <div
          className="absolute w-80 h-80 bg-gradient-to-r from-blue-500/20 to-green-500/20 rounded-full blur-3xl animate-pulse"
          style={{
            right: `${15 + mousePosition.x * 0.015}%`,
            bottom: `${20 + mousePosition.y * 0.015}%`,
            animationDelay: "1s",
          }}
        ></div>
        <div
          className="absolute top-1/2 left-1/2 w-[600px] h-[600px] bg-gradient-to-r from-green-500/10 to-blue-500/10 rounded-full blur-3xl animate-pulse transform -translate-x-1/2 -translate-y-1/2"
          style={{ animationDelay: "2s" }}
        ></div>
      </div>

      <div className="container mx-auto px-4 pt-32 pb-16 relative z-10">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left Content */}
          <div
            className={`space-y-8 ${
              isVisible ? "animate-fade-in-up" : "opacity-0"
            }`}
          >
            {/* Trust Indicators */}
            <div className="flex flex-wrap items-center gap-6 text-sm">
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg border border-white/20">
                <div className="flex space-x-1">
                  {[...Array(5)].map((_, i) => (
                    <Star
                      key={i}
                      className="h-4 w-4 fill-green-500 text-green-500"
                    />
                  ))}
                </div>
                <span className="font-semibold text-gray-700">4.9/5</span>
              </div>
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg border border-white/20">
                <Users className="h-4 w-4 text-blue-500" />
                <span className="font-semibold text-gray-700">
                  50k+ {t("activeUsers")}
                </span>
              </div>
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg border border-white/20">
                <Shield className="h-4 w-4 text-green-500" />
                <span className="font-semibold text-gray-700">
                  100% {t("secureData")}
                </span>
              </div>
            </div>

            {/* Main Headline */}
            <div className="space-y-6">
              <h1 className="text-5xl md:text-7xl font-bold text-gray-900 leading-tight">
                {t("heroTitle")}{" "}
                <span className="relative">
                  <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                    {t("heroTitleHighlight")}
                  </span>
                  <div className="absolute -bottom-2 left-0 right-0 h-1 bg-gradient-to-r from-green-500 to-blue-500 rounded-full"></div>
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-gray-600 leading-relaxed max-w-2xl">
                {t("heroSubtitle")}{" "}
                <span className="text-green-600 font-semibold">
                  {t("heroSubtitleHighlight")}
                </span>
              </p>
            </div>

            {/* Key Benefits */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {[
                {
                  icon: Clock,
                  text: t("timeSaved"),
                  color: "text-green-600",
                },
                {
                  icon: Users,
                  text: t("familySync"),
                  color: "text-blue-600",
                },
                {
                  icon: Shield,
                  text: t("secureData"),
                  color: "text-green-600",
                },
              ].map((benefit, index) => (
                <div
                  key={index}
                  className="flex items-center space-x-3 bg-white/80 backdrop-blur-sm rounded-2xl p-4 shadow-lg hover:shadow-xl transition-all duration-300 group border border-white/20"
                >
                  <benefit.icon
                    className={`h-6 w-6 ${benefit.color} group-hover:scale-110 transition-transform duration-300`}
                  />
                  <span className="text-sm font-medium text-gray-700">
                    {benefit.text}
                  </span>
                </div>
              ))}
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <Button
                onClick={handleDownload}
                size="lg"
                className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white group transition-all duration-300 transform hover:scale-105 relative overflow-hidden cursor-pointer shadow-lg hover:shadow-xl"
              >
                <span className="relative z-10 flex items-center">
                  <Download className="mr-3 h-5 w-5 group-hover:animate-bounce" />
                  {t("downloadNow")}
                </span>
              </Button>
              <Button
                onClick={handleWatchDemo}
                size="lg"
                variant="outline"
                className="border-2 border-blue-500 text-blue-600 hover:bg-blue-500 hover:text-white transition-all duration-300 group relative overflow-hidden cursor-pointer"
              >
                <span className="relative z-10 flex items-center">
                  <Play className="mr-3 h-5 w-5 group-hover:animate-bounce" />
                  {t("watchDemo")}
                </span>
                <div className="absolute inset-0 bg-blue-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></div>
              </Button>
            </div>

            {/* Social Proof */}
            <div className="flex items-center space-x-8 text-sm text-gray-500 pt-4">
              <div className="flex items-center space-x-2">
                <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                <span>{t("freeForLife")}</span>
              </div>
              <div className="flex items-center space-x-2">
                <div
                  className="w-3 h-3 bg-blue-500 rounded-full animate-pulse"
                  style={{ animationDelay: "0.5s" }}
                ></div>
                <span>{t("noAds")}</span>
              </div>
              <div className="flex items-center space-x-2">
                <div
                  className="w-3 h-3 bg-green-500 rounded-full animate-pulse"
                  style={{ animationDelay: "1s" }}
                ></div>
                <span>{t("instantInstall")}</span>
              </div>
            </div>
          </div>

          {/* Right Content - Hero Image */}
          <div
            className={`relative ${
              isVisible ? "animate-fade-in-up" : "opacity-0"
            }`}
            style={{ animationDelay: "0.3s" }}
          >
            <div className="relative mx-auto max-w-lg">
              {/* Main Hero Image */}
              <div className="relative group">
                <div className="absolute -inset-4 bg-gradient-to-r from-green-500 to-blue-500 rounded-3xl blur-lg opacity-30 group-hover:opacity-50 transition-opacity duration-300"></div>
                <div className="relative bg-white rounded-3xl p-4 shadow-2xl hover:shadow-3xl transition-all duration-500 transform hover:scale-105">
                  <Image
                    src="/dash.png" // Remplacez par le chemin de votre image
                    alt="EpiList App Interface"
                    width={500}
                    height={600}
                    className="w-full h-auto rounded-2xl object-cover"
                    priority
                    placeholder="blur"
                    blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="
                  />
                </div>
              </div>

              {/* Floating Elements */}
              <div className="absolute -top-8 -right-8 bg-white/90 backdrop-blur-sm rounded-2xl p-4 shadow-xl animate-pulse border border-white/20">
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                  <span className="text-sm font-medium text-gray-700">
                    {t("synchronized")}
                  </span>
                </div>
              </div>

              <div
                className="absolute -bottom-8 -left-8 bg-white/90 backdrop-blur-sm rounded-2xl p-4 shadow-xl animate-pulse border border-white/20"
                style={{ animationDelay: "1s" }}
              >
                <div className="flex items-center space-x-2">
                  <Users className="w-4 h-4 text-blue-500" />
                  <span className="text-sm font-medium text-gray-700">
                    3 {t("members")}
                  </span>
                </div>
              </div>

              <div
                className="absolute top-1/2 -left-12 bg-white/90 backdrop-blur-sm rounded-2xl p-3 shadow-xl animate-pulse border border-white/20"
                style={{ animationDelay: "2s" }}
              >
                <div className="flex items-center space-x-2">
                  <div className="flex space-x-1">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className="h-3 w-3 fill-green-500 text-green-500"
                      />
                    ))}
                  </div>
                  <span className="text-xs font-medium text-gray-700">4.9</span>
                </div>
              </div>

              <div
                className="absolute top-1/4 -right-12 bg-white/90 backdrop-blur-sm rounded-2xl p-3 shadow-xl animate-pulse border border-white/20"
                style={{ animationDelay: "1.5s" }}
              >
                <div className="flex items-center space-x-2">
                  <Clock className="w-4 h-4 text-green-500" />
                  <span className="text-xs font-medium text-gray-700">
                    {t("language") === "fr" ? "Temps réel" : "Real-time"}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll Indicator */}
        <div className="text-center mt-20">
          <button
            onClick={scrollToFeatures}
            className="inline-flex flex-col items-center space-y-2 text-gray-500 hover:text-green-600 transition-colors group"
          >
            <span className="text-sm font-medium">{t("discoverFeatures")}</span>
            <ArrowDown className="h-6 w-6 group-hover:animate-bounce" />
          </button>
        </div>
      </div>
    </section>
  );
}
