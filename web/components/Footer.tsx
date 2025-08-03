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
              {/* Logo Image sans background */}
              <div className="relative w-8 h-8 group-hover:scale-105 transition-transform duration-300">
                <Image
                  src="/app_logo.png" // Votre logo
                  alt="EpiList Logo"
                  fill
                  className="object-contain"
                  sizes="32px"
                />
              </div>

              {/* Fallback avec icône si l'image ne charge pas */}
              {/* Vous pouvez décommenter ceci si besoin de fallback :
              <Smartphone className="h-8 w-8 text-green-400 group-hover:scale-105 transition-transform duration-300" />
              */}
            </div>

            <div>
              <span className="text-3xl font-bold bg-gradient-to-r from-green-400 to-blue-400 bg-clip-text text-transparent group-hover:from-green-300 group-hover:to-blue-300 transition-all duration-300">
                EpiList
              </span>
              <div className="text-gray-400 text-sm">
                {t("language") === "fr"
                  ? "Simplifiez vos courses"
                  : "Simplify your shopping"}
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
                href: "mailto:contact@epilist.app",
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

          {/* Quick Links */}
          <div className="flex flex-wrap justify-center gap-6 mb-8">
            {[
              { text: t("privacyPolicy"), href: "/privacy" },
              { text: t("termsOfService"), href: "/terms" },
              { text: t("contact"), href: "/contact" },
            ].map((link, index) => (
              <Link
                key={index}
                href={link.href}
                className="text-gray-400 hover:text-green-400 transition-colors duration-300 text-sm hover:underline underline-offset-4"
              >
                {link.text}
              </Link>
            ))}
          </div>
        </div>

        {/* Newsletter Section */}
        <div className="border-t border-gray-800 pt-8 mb-8">
          <div className="bg-gradient-to-r from-green-500/10 to-blue-500/10 rounded-2xl p-8 text-center max-w-2xl mx-auto border border-white/10">
            <h3 className="text-2xl font-bold mb-4">{t("footerNewsletter")}</h3>
            <p className="text-gray-400 mb-6">{t("footerNewsletterDesc")}</p>
            <div className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
              <input
                type="email"
                placeholder={t("footerNewsletterPlaceholder")}
                className="flex-1 px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:border-green-500 focus:ring-2 focus:ring-green-500/20 transition-all duration-300"
              />
              <Button className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white px-6 py-3 shadow-lg hover:shadow-xl transition-all duration-300">
                {t("footerNewsletterButton")}
              </Button>
            </div>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="text-center border-t border-gray-800 pt-8">
          <div className="flex flex-col sm:flex-row justify-center items-center gap-4 text-gray-400 text-sm">
            <span>{t("footerCopyright")}</span>
            <div className="flex items-center gap-2">
              <span>•</span>
              <span>Made with</span>
              <span className="text-red-500 animate-pulse">❤️</span>
              <span>in New Brunswick</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
