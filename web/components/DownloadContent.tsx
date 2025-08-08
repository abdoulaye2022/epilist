"use client";

import { trackAppDownloadUnified } from "@/lib/unified-tracking";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import Image from "next/image";
import {
  Download,
  Star,
  Users,
  Clock,
  Shield,
  Smartphone,
  Check,
  Apple,
  PlayCircle,
  ArrowRight,
  Zap,
  Heart,
  Award,
} from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function DownloadContent() {
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

  const handleDownload = (platform: "ios" | "android") => {
    trackAppDownloadUnified(platform, "cta_section");
    const url = platform === "ios" ? APP_STORE_URL : GOOGLE_PLAY_URL;
    window.open(url, "_blank", "noopener,noreferrer");
  };

  return (
    <main className="min-h-screen">
      <Header />

      {/* Hero Section */}
      <section className="min-h-screen bg-gradient-to-br from-white via-gray-50 to-white relative overflow-hidden pt-20">
        {/* Animated Background */}
        <div className="absolute inset-0">
          <div
            className="absolute w-96 h-96 bg-gradient-to-r from-green-500/20 to-blue-500/20 rounded-full blur-3xl animate-pulse"
            style={{
              left: `${20 + mousePosition.x * 0.02}%`,
              top: `${10 + mousePosition.y * 0.02}%`,
            }}
          />
        </div>

        <div className="container mx-auto px-4 py-16 relative z-10">
          <div className="text-center mb-16">
            <div className="inline-flex items-center space-x-2 bg-gradient-to-r from-green-500 to-blue-500 text-white px-6 py-3 rounded-full text-sm font-medium mb-6 shadow-lg">
              <Download className="h-4 w-4" />
              <span>Téléchargement gratuit</span>
            </div>

            <h1 className="text-5xl md:text-7xl font-bold text-gray-900 mb-6 leading-tight">
              Téléchargez{" "}
              <span className="bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                EpiList
              </span>
              <br />
              <span className="text-3xl md:text-5xl">100% Gratuit</span>
            </h1>

            <p className="text-xl md:text-2xl text-gray-600 max-w-3xl mx-auto mb-12">
              🛒 L'application de courses familiale la plus populaire au Canada.
              Synchronisation temps réel, mode hors ligne, sans publicité !
            </p>

            {/* Trust Indicators */}
            <div className="flex flex-wrap justify-center gap-6 text-sm mb-12">
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
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
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
                <Users className="h-4 w-4 text-blue-500" />
                <span className="font-semibold text-gray-700">
                  50k+ téléchargements
                </span>
              </div>
              <div className="flex items-center space-x-2 bg-white/90 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
                <Shield className="h-4 w-4 text-green-500" />
                <span className="font-semibold text-gray-700">
                  100% sécurisé
                </span>
              </div>
            </div>

            {/* Download Buttons */}
            <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
              <Button
                onClick={() => handleDownload("ios")}
                size="lg"
                className="bg-black hover:bg-gray-800 text-white px-8 py-4 rounded-2xl flex items-center space-x-4 text-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105"
              >
                <Apple className="h-8 w-8" />
                <div className="text-left">
                  <div className="text-xs opacity-80">Télécharger sur</div>
                  <div className="text-lg font-semibold">App Store</div>
                </div>
              </Button>

              <Button
                onClick={() => handleDownload("android")}
                size="lg"
                className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white px-8 py-4 rounded-2xl flex items-center space-x-4 text-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105"
              >
                <PlayCircle className="h-8 w-8" />
                <div className="text-left">
                  <div className="text-xs opacity-90">Télécharger sur</div>
                  <div className="text-lg font-semibold">Google Play</div>
                </div>
              </Button>
            </div>

            {/* Features Preview */}
            <div className="grid md:grid-cols-3 gap-6 mt-16 max-w-4xl mx-auto">
              {[
                {
                  icon: Zap,
                  title: "Installation rapide",
                  desc: "Prêt en 30 secondes",
                },
                {
                  icon: Heart,
                  title: "Gratuit à vie",
                  desc: "Aucun frais caché",
                },
                { icon: Award, title: "App #1", desc: "Au Canada" },
              ].map((item, i) => (
                <div
                  key={i}
                  className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg border border-white/20"
                >
                  <item.icon className="h-8 w-8 text-green-500 mx-auto mb-3" />
                  <h3 className="font-semibold text-gray-900 mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-600 text-sm">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Screenshots Section */}
      <section className="py-24 bg-white">
        <div className="container mx-auto px-4">
          <h2 className="text-4xl font-bold text-center text-gray-900 mb-16">
            Aperçu de l'application
          </h2>
          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            {[1, 2, 3].map((i) => (
              <div key={i} className="relative group">
                <div className="absolute -inset-4 bg-gradient-to-r from-green-500 to-blue-500 rounded-3xl blur-lg opacity-30 group-hover:opacity-50 transition-opacity" />
                <div className="relative bg-white rounded-3xl p-4 shadow-2xl">
                  <Image
                    src={`/screenshot-${i}.png`}
                    alt={`EpiList Screenshot ${i}`}
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-2xl"
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
