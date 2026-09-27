"use client";

// Témoignages : trois cartes statiques et lisibles (fini le carrousel
// autoplay et les compteurs).
import { Quote } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";

export default function TestimonialsSection() {
  const { t } = useLanguage();

  const testimonials = [1, 2, 3] as const;

  return (
    <section id="temoignages" className="bg-white py-20 lg:py-28">
      <div className="container mx-auto px-4">
        <div className="mx-auto max-w-2xl text-center mb-14">
          <h2 className="text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">
            {t("testimonialsTitle")}{" "}
            <span className="text-epilist-green">
              {t("testimonialsTitleHighlight")}
            </span>
          </h2>
          <p className="mt-4 text-lg text-gray-600">
            {t("testimonialsSubtitle")}
          </p>
        </div>

        <div className="grid gap-5 md:grid-cols-3">
          {testimonials.map((n) => (
            <figure
              key={n}
              className="flex flex-col rounded-2xl border border-gray-200 bg-white p-6"
            >
              <Quote className="h-6 w-6 text-green-200 mb-4" aria-hidden="true" />
              <blockquote className="flex-1 text-sm leading-relaxed text-gray-700">
                « {t(`testimonial${n}Content` as any)} »
              </blockquote>
              <figcaption className="mt-5 flex items-center gap-3 border-t border-gray-100 pt-4">
                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-green-50 text-sm font-bold text-epilist-green">
                  {t(`testimonial${n}Name` as any).charAt(0)}
                </div>
                <div>
                  <div className="text-sm font-semibold text-gray-900">
                    {t(`testimonial${n}Name` as any)}
                  </div>
                  <div className="text-xs text-gray-500">
                    {t(`testimonial${n}Role` as any)}
                  </div>
                </div>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
