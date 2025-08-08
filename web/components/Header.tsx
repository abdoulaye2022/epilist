// ==========================================
// 1. Header.tsx corrigé avec nouvelles URLs
// ==========================================
"use client";

import { trackAppDownload } from "@/lib/gtag";

import React from "react";
import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { Smartphone, Menu, X, Download, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/hooks/useLanguage";
import LanguageToggle from "@/components/LanguageToggle";

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const { t } = useLanguage();

  // URLs des stores
  const APP_STORE_URL =
    "https://apps.apple.com/ca/app/epilist/id6748285596?l=fr-CA";
  const GOOGLE_PLAY_URL =
    "https://play.google.com/store/apps/details?id=com.m2atech.epilist";

  const openAppStore = (): void => {
    trackAppDownload("ios", "header");
    window.open(APP_STORE_URL, "_blank", "noopener,noreferrer");
  };

  const openGooglePlay = (): void => {
    trackAppDownload("android", "header");
    window.open(GOOGLE_PLAY_URL, "_blank", "noopener,noreferrer");
  };

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const scrollToSection = (sectionId: string) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
    setIsMobileMenuOpen(false);
  };

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        isScrolled
          ? "bg-white/80 backdrop-blur-xl shadow-lg border-b border-white/20"
          : "bg-transparent"
      }`}
    >
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <Link
            href="/"
            className="flex items-center space-x-3 group cursor-pointer"
          >
            <div className="relative">
              <div className="relative w-8 h-8 group-hover:scale-110 transition-transform duration-300">
                <Image
                  src="/app_logo.png"
                  alt="EpiList Logo"
                  fill
                  className="object-contain"
                  priority
                  sizes="32px"
                />
              </div>
            </div>

            <div>
              <span className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
                EpiList
              </span>
              <div className="flex items-center space-x-1 mt-1">
                <div className="flex space-x-0.5">
                  {[...Array(5)].map((_, i) => (
                    <Star
                      key={i}
                      className="h-3 w-3 fill-green-500 text-green-500"
                    />
                  ))}
                </div>
                <span className="text-xs text-gray-500 ml-1">4.9</span>
              </div>
            </div>
          </Link>

          {/* Desktop Navigation - CORRIGÉ */}
          <nav className="hidden lg:flex items-center space-x-8">
            {[
              { key: "features", href: "/fonctionnalites" },
              { key: "benefits", id: "avantages" },
              { key: "testimonials", id: "temoignages" },
              { key: "help", href: "/aide" },
              { key: "contact", href: "/contact" },
            ].map((item) =>
              item.href ? (
                <Link
                  key={item.key}
                  href={item.href}
                  className="relative text-gray-700 hover:text-green-600 transition-all duration-300 font-medium group"
                >
                  {item.key === "features" && "Fonctionnalités"}
                  {item.key === "help" && "Aide"}
                  {item.key === "contact" && t(item.key as any)}
                  <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-green-500 to-blue-500 group-hover:w-full transition-all duration-300"></span>
                </Link>
              ) : (
                <button
                  key={item.key}
                  onClick={() => scrollToSection(item.id!)}
                  className="relative text-gray-700 hover:text-green-600 transition-all duration-300 font-medium group"
                >
                  {t(item.key as any)}
                  <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r from-green-500 to-blue-500 group-hover:w-full transition-all duration-300"></span>
                </button>
              )
            )}
          </nav>

          {/* Desktop CTA Buttons */}
          <div className="hidden lg:flex items-center space-x-3">
            <LanguageToggle />

            {/* Nouveau bouton Télécharger */}
            <Link href="/telecharger">
              <Button
                variant="outline"
                className="border-2 border-green-500 text-green-600 hover:bg-green-500 hover:text-white transition-all duration-300 group relative overflow-hidden"
              >
                <span className="relative z-10 flex items-center">
                  <Download className="mr-2 h-4 w-4 group-hover:animate-bounce" />
                  Télécharger
                </span>
                <div className="absolute inset-0 bg-green-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></div>
              </Button>
            </Link>

            <Button
              onClick={openGooglePlay}
              className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white transition-all duration-300 shadow-lg hover:shadow-xl group relative overflow-hidden"
            >
              <span className="relative z-10 flex items-center">
                <Download className="mr-2 h-4 w-4 group-hover:animate-bounce" />
                {t("googlePlay")}
              </span>
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="lg:hidden relative z-50"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          >
            <div className="relative">
              {isMobileMenuOpen ? (
                <X className="h-6 w-6 text-gray-700" />
              ) : (
                <Menu className="h-6 w-6 text-gray-700" />
              )}
            </div>
          </button>
        </div>

        {/* Mobile Menu - CORRIGÉ */}
        <div
          className={`lg:hidden absolute top-full left-0 right-0 transition-all duration-500 ${
            isMobileMenuOpen
              ? "opacity-100 translate-y-0 pointer-events-auto"
              : "opacity-0 -translate-y-4 pointer-events-none"
          }`}
        >
          <div className="bg-white/95 backdrop-blur-xl border border-white/20 rounded-2xl mx-4 mt-2 shadow-xl">
            <nav className="flex flex-col p-6 space-y-4">
              {[
                {
                  key: "features",
                  href: "/fonctionnalites",
                  label: "Fonctionnalités",
                },
                { key: "benefits", id: "avantages", label: t("benefits") },
                {
                  key: "testimonials",
                  id: "temoignages",
                  label: t("testimonials"),
                },
                { key: "help", href: "/aide", label: "Aide" },
                { key: "contact", href: "/contact", label: t("contact") },
              ].map((item) =>
                item.href ? (
                  <Link
                    key={item.key}
                    href={item.href}
                    className="text-left text-gray-700 hover:text-green-600 transition-colors duration-300 font-medium py-2"
                    onClick={() => setIsMobileMenuOpen(false)}
                  >
                    {item.label}
                  </Link>
                ) : (
                  <button
                    key={item.key}
                    onClick={() => scrollToSection(item.id!)}
                    className="text-left text-gray-700 hover:text-green-600 transition-colors duration-300 font-medium py-2"
                  >
                    {item.label}
                  </button>
                )
              )}

              <div className="flex flex-col space-y-3 pt-4 border-t border-gray-200">
                <LanguageToggle />

                <Link
                  href="/telecharger"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  <Button
                    variant="outline"
                    className="w-full border-green-500 text-green-600 hover:bg-green-500 hover:text-white transition-all duration-300"
                  >
                    <Download className="mr-2 h-4 w-4" />
                    Télécharger l'app
                  </Button>
                </Link>

                <Button
                  onClick={() => {
                    openGooglePlay();
                    setIsMobileMenuOpen(false);
                  }}
                  className="w-full bg-gradient-to-r from-green-500 to-blue-500 text-white"
                >
                  <Download className="mr-2 h-4 w-4" />
                  {t("googlePlay")}
                </Button>
              </div>
            </nav>
          </div>
        </div>
      </div>
    </header>
  );
}
