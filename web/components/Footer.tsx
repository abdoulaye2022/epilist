"use client";

// Pied de page compact : logo + description courte, trois colonnes de
// liens bilingues, copyright. Pas de réseaux sociaux fantômes ni de
// newsletter factice.
import Image from "next/image";
import Link from "next/link";
import { Mail } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import { href, type RouteKey } from "@/lib/routes";

export default function Footer() {
  const { t, language } = useLanguage();
  const year = new Date().getFullYear();

  const columns: { title: string; links: { key: RouteKey; label: string }[] }[] = [
    {
      title: t("product"),
      links: [
        { key: "features", label: t("features") },
        { key: "download", label: t("download") },
        { key: "comparison", label: t("comparison") },
      ],
    },
    {
      title: t("navigation"),
      links: [
        { key: "help", label: t("help") },
        { key: "contact", label: t("contact") },
        { key: "about", label: t("about") },
      ],
    },
    {
      title: t("legal"),
      links: [
        { key: "privacy", label: t("privacyPolicy") },
        { key: "terms", label: t("termsOfService") },
      ],
    },
  ];

  return (
    <footer className="bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-14">
        <div className="grid gap-10 md:grid-cols-5">
          {/* Marque */}
          <div className="md:col-span-2">
            <Link href={href("home", language)} className="flex items-center gap-2.5">
              <div className="relative w-8 h-8">
                <Image
                  src="/app_logo.png"
                  alt="EpiList"
                  fill
                  className="object-contain"
                  sizes="32px"
                />
              </div>
              <span className="text-xl font-bold">EpiList</span>
            </Link>
            <p className="mt-4 max-w-sm text-sm leading-relaxed text-gray-400">
              {t("footerTagline")}
            </p>
            <Link
              href={href("contact", language)}
              className="mt-4 inline-flex items-center gap-2 text-sm text-gray-400 hover:text-green-400 transition-colors"
            >
              <Mail className="h-4 w-4" />
              {t("contactUs")}
            </Link>
          </div>

          {/* Colonnes de liens */}
          {columns.map((column) => (
            <div key={column.title}>
              <h3 className="text-sm font-semibold uppercase tracking-wider text-gray-300 mb-4">
                {column.title}
              </h3>
              <ul className="space-y-2.5">
                {column.links.map((link) => (
                  <li key={link.key}>
                    <Link
                      href={href(link.key, language)}
                      className="text-sm text-gray-400 hover:text-green-400 transition-colors"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 border-t border-white/10 pt-6 text-center">
          <p className="text-xs text-gray-500">
            © {year} EpiList · M2atech Solutions Inc. ·{" "}
            {language === "fr"
              ? "Nouveau-Brunswick, Canada"
              : "New Brunswick, Canada"}
          </p>
        </div>
      </div>
    </footer>
  );
}
