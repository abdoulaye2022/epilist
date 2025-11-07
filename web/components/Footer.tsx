"use client";

import { Smartphone, Facebook, Twitter, Instagram, Mail } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/hooks/useLanguage";

export default function Footer() {
  const { t } = useLanguage();

  return (
    <footer className="bg-gray-900 text-white relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-64 h-64 bg-green-500/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-80 h-80 bg-blue-500/10 rounded-full blur-3xl"></div>
      </div>

      <div className="container mx-auto px-4 py-16 relative z-10">
        {/* Main Footer Content */}
        <div className="text-center mb-12">
          {/* Logo */}
          <Link
            href="/"
            className="inline-flex items-center justify-center space-x-3 mb-6 group"
          >
            <div className="relative">
              <div className="relative w-8 h-8 group-hover:scale-105 transition-transform duration-300">
                <Image
                  src="/app_logo.png"
                  alt="EpiList Logo"
                  fill
                  className="object-contain"
                  sizes="32px"
                />
              </div>
            </div>

            <div>
              <span className="text-3xl font-bold bg-gradient-to-r from-green-400 to-blue-400 bg-clip-text text-transparent group-hover:from-green-300 group-hover:to-blue-300 transition-all duration-300">
                EpiList
              </span>
              <div className="text-gray-400 text-sm">
                {t("footerTagline")}
              </div>
            </div>
          </Link>

          {/* Description */}
          <p className="text-gray-400 mb-8 leading-relaxed text-lg max-w-2xl mx-auto">
            {t("footerDescription")}
          </p>

          {/* Social Media */}
          <div className="flex justify-center space-x-4 mb-8">
            {[
              {
                icon: Facebook,
                label: "Facebook",
                href: "https://facebook.com/epilistapp",
              },
              {
                icon: Twitter,
                label: "Twitter",
                href: "https://twitter.com/epilistapp",
              },
              {
                icon: Instagram,
                label: "Instagram",
                href: "https://instagram.com/epilistapp",
              },
              {
                icon: Mail,
                label: "Email",
                href: "mailto:support@epilist.app",
              },
            ].map((social, index) => (
              <Button
                key={index}
                size="sm"
                variant="ghost"
                className="hover:bg-green-500/20 hover:text-green-400 transition-all duration-300 group"
                aria-label={social.label}
                asChild
              >
                <a
                  href={social.href}
                  target={social.href.startsWith("http") ? "_blank" : undefined}
                  rel={
                    social.href.startsWith("http")
                      ? "noopener noreferrer"
                      : undefined
                  }
                >
                  <social.icon className="h-5 w-5 group-hover:scale-110 transition-transform duration-300" />
                </a>
              </Button>
            ))}
          </div>

          {/* Quick Links - CORRIGÉ avec nouvelles URLs SEO */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8 max-w-4xl mx-auto">
            {/* Colonne 1: App */}
            <div>
              <h4 className="text-green-400 font-semibold mb-3">{t("application")}</h4>
              <div className="space-y-2">
                <Link
                  href="/telecharger"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("download")}
                </Link>
                <Link
                  href="/fonctionnalites"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("features")}
                </Link>
                <Link
                  href="/comparaison-applications-courses"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("comparison")}
                </Link>
              </div>
            </div>

            {/* Colonne 2: Support */}
            <div>
              <h4 className="text-blue-400 font-semibold mb-3">{t("support")}</h4>
              <div className="space-y-2">
                <Link
                  href="/aide"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("helpCenter")}
                </Link>
                <Link
                  href="/contact"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("contactUs")}
                </Link>
                <a
                  href="mailto:support@epilist.app"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("emailSupport")}
                </a>
              </div>
            </div>

            {/* Colonne 3: Entreprise */}
            <div>
              <h4 className="text-purple-400 font-semibold mb-3">{t("company")}</h4>
              <div className="space-y-2">
                <Link
                  href="/a-propos"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("about")}
                </Link>
                <span className="block text-gray-400 text-sm">
                  {t("newBrunswick")}
                </span>
                <span className="block text-gray-400 text-sm">
                  {t("madeInCanada")}
                </span>
              </div>
            </div>

            {/* Colonne 4: Légal */}
            <div>
              <h4 className="text-orange-400 font-semibold mb-3">{t("legal")}</h4>
              <div className="space-y-2">
                <Link
                  href="/politique-confidentialite"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("privacy")}
                </Link>
                <Link
                  href="/conditions-utilisation"
                  className="block text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm"
                >
                  {t("terms")}
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Newsletter Section */}
        <div className="border-t border-gray-800 pt-8 mb-8">
          <div className="bg-gradient-to-r from-green-500/10 to-blue-500/10 rounded-2xl p-8 text-center max-w-2xl mx-auto border border-white/10">
            <h3 className="text-2xl font-bold mb-4">{t("stayInformed")}</h3>
            <p className="text-gray-400 mb-6">
              {t("newsletterDescription")}
            </p>
            <div className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
              <input
                type="email"
                placeholder={t("emailPlaceholder")}
                className="flex-1 px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:border-green-500 focus:ring-2 focus:ring-green-500/20 transition-all duration-300"
              />
              <Button className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white px-6 py-3 shadow-lg hover:shadow-xl transition-all duration-300">
                {t("subscribe")}
              </Button>
            </div>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="text-center border-t border-gray-800 pt-8">
          <div className="flex flex-col sm:flex-row justify-center items-center gap-4 text-gray-400 text-sm">
            <span>{t("copyright")}</span>
            <div className="flex items-center gap-2">
              <span>•</span>
              <span>{t("madeWith")}</span>
              <span className="text-red-500 animate-pulse">❤️</span>
              <span>{t("inNewBrunswick")}</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
