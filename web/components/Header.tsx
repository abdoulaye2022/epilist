"use client";

// Header sobre : logo + nom, navigation, bascule de langue, un seul CTA.
// Tous les liens passent par la carte de routes bilingues.
import { trackAppDownload } from "@/lib/gtag";
import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { Menu, X, Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/hooks/useLanguage";
import LanguageToggle from "@/components/LanguageToggle";
import { href } from "@/lib/routes";

export default function Header() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const { t, language } = useLanguage();

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 12);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navItems = [
    { key: "features" as const, route: "features" as const },
    { key: "help" as const, route: "help" as const },
    { key: "contact" as const, route: "contact" as const },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? "bg-white/95 backdrop-blur border-b border-gray-200 shadow-sm"
          : "bg-white/60 backdrop-blur"
      }`}
    >
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href={href("home", language)} className="flex items-center gap-2.5">
            <div className="relative w-8 h-8">
              <Image
                src="/app_logo.png"
                alt="EpiList"
                fill
                className="object-contain"
                priority
                sizes="32px"
              />
            </div>
            <span className="text-xl font-bold text-gray-900">EpiList</span>
          </Link>

          {/* Navigation desktop */}
          <nav className="hidden lg:flex items-center gap-8">
            {navItems.map((item) => (
              <Link
                key={item.key}
                href={href(item.route, language)}
                className="text-sm font-medium text-gray-600 hover:text-epilist-green transition-colors"
              >
                {t(item.key)}
              </Link>
            ))}
          </nav>

          {/* Actions desktop */}
          <div className="hidden lg:flex items-center gap-3">
            <LanguageToggle />
            <Link
              href={href("download", language)}
              onClick={() => trackAppDownload("android", "header")}
            >
              <Button className="bg-epilist-green hover:bg-green-600 text-white shadow-sm">
                <Download className="mr-2 h-4 w-4" />
                {t("download")}
              </Button>
            </Link>
          </div>

          {/* Bouton menu mobile */}
          <button
            className="lg:hidden p-2 -mr-2"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            aria-label="Menu"
          >
            {isMobileMenuOpen ? (
              <X className="h-6 w-6 text-gray-700" />
            ) : (
              <Menu className="h-6 w-6 text-gray-700" />
            )}
          </button>
        </div>
      </div>

      {/* Menu mobile */}
      {isMobileMenuOpen && (
        <div className="lg:hidden border-t border-gray-200 bg-white">
          <nav className="container mx-auto px-4 py-4 flex flex-col gap-1">
            {navItems.map((item) => (
              <Link
                key={item.key}
                href={href(item.route, language)}
                className="py-2.5 text-gray-700 font-medium hover:text-epilist-green transition-colors"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {t(item.key)}
              </Link>
            ))}
            <div className="flex items-center gap-3 pt-3 mt-2 border-t border-gray-100">
              <LanguageToggle />
              <Link
                href={href("download", language)}
                className="flex-1"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                <Button className="w-full bg-epilist-green hover:bg-green-600 text-white">
                  <Download className="mr-2 h-4 w-4" />
                  {t("downloadApp")}
                </Button>
              </Link>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}
