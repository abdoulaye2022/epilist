"use client";

// Centre d'aide : FAQ accordéon entièrement traduite (fr/en), sans emoji.
import { useState } from "react";
import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { ChevronDown, ChevronRight, Mail, Clock, LifeBuoy } from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";

export default function HelpContent() {
  const [openFAQ, setOpenFAQ] = useState<number | null>(0);
  const { t, language } = useLanguage();

  const faqs = [1, 2, 3, 4, 5, 6] as const;

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="pt-32 pb-20">
        <div className="container mx-auto px-4">
          <div className="mx-auto max-w-2xl text-center mb-14">
            <h1 className="text-4xl md:text-5xl font-bold text-gray-900 tracking-tight mb-5">
              {t("helpPageTitle")}
            </h1>
            <p className="text-lg text-gray-600">{t("helpPageSubtitle")}</p>
          </div>

          {/* FAQ */}
          <div className="mx-auto max-w-3xl">
            <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">
              {t("helpFaqTitle")}
            </h2>
            <div className="space-y-3">
              {faqs.map((n, index) => (
                <Card
                  key={n}
                  className="overflow-hidden border border-gray-200 shadow-none"
                >
                  <CardContent className="p-0">
                    <button
                      onClick={() =>
                        setOpenFAQ(openFAQ === index ? null : index)
                      }
                      className="flex w-full items-center justify-between p-5 text-left transition-colors hover:bg-gray-50"
                    >
                      <h3 className="pr-4 text-base font-semibold text-gray-900">
                        {t(`helpFaq${n}Q` as any)}
                      </h3>
                      {openFAQ === index ? (
                        <ChevronDown className="h-5 w-5 flex-shrink-0 text-epilist-green" />
                      ) : (
                        <ChevronRight className="h-5 w-5 flex-shrink-0 text-gray-400" />
                      )}
                    </button>
                    {openFAQ === index && (
                      <div className="px-5 pb-5">
                        <p className="text-sm leading-relaxed text-gray-600">
                          {t(`helpFaq${n}A` as any)}
                        </p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* Contact */}
          <div className="mt-14 text-center">
            <Card className="mx-auto max-w-xl border border-gray-200 shadow-sm">
              <CardContent className="p-8">
                <div className="mx-auto mb-4 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-green-50 text-epilist-green">
                  <LifeBuoy className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  {t("helpContactTitle")}
                </h3>
                <p className="mb-5 text-gray-600">{t("helpContactText")}</p>
                <div className="flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-6 text-sm font-medium">
                  <Link
                    href={href("contact", language)}
                    className="inline-flex items-center gap-2 text-epilist-green hover:text-green-700"
                  >
                    <Mail className="h-4 w-4" />
                    {t("contactUs")}
                  </Link>
                  <span className="inline-flex items-center gap-2 text-gray-600">
                    <Clock className="h-4 w-4" />
                    {t("helpResponseTime")}
                  </span>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
