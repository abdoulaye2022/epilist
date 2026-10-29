"use client";

// Témoignages — vide, et c'est voulu.
//
// Cette section affichait cinq témoignages qui n'ont jamais existé :
// cinq noms français génériques répartis sur cinq villes du
// Nouveau-Brunswick, un par segment démographique (mère, père,
// étudiante, retraité, professeure), sans photo, sans date, sans source,
// dont un qui annonçait « 200 $ d'économies par mois ». Aucune trace
// d'aucun d'eux dans la base.
//
// Ils sont supprimés. La structure reste, prête pour de vrais retours.
//
// POUR AJOUTER UN VRAI TÉMOIGNAGE :
//   1. obtenir un accord ÉCRIT de la personne, pour la citation exacte
//      et pour la façon dont elle sera nommée ;
//   2. remplir une entrée de TEMOIGNAGES ci-dessous, `accordLe` portant
//      la date de cet accord (c'est la trace, gardez le courriel) ;
//   3. mettre NEXT_PUBLIC_TESTIMONIALS_ENABLED=true au déploiement.
//
// Tant que la liste est vide, la section ne s'affiche pas — même avec
// l'interrupteur à vrai. Pas de carte fantôme, pas de « bientôt ».
import { Quote } from "lucide-react";
import { useLanguage } from "@/hooks/useLanguage";
import { TESTIMONIALS_ENABLED } from "@/lib/config";

interface Temoignage {
  /** La citation, dans chaque langue. Jamais traduite à la machine. */
  citation: { fr: string; en: string };
  /** Le nom tel que la personne accepte d'être nommée. */
  nom: string;
  /** Rôle ou ville, si la personne l'accepte. */
  role?: { fr: string; en: string };
  /** Date de l'accord écrit (AAAA-MM-JJ). Obligatoire. */
  accordLe: string;
}

const TEMOIGNAGES: Temoignage[] = [];

export default function TestimonialsSection() {
  const { t, language } = useLanguage();

  if (!TESTIMONIALS_ENABLED || TEMOIGNAGES.length === 0) {
    return null;
  }

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
          {TEMOIGNAGES.map((temoignage) => (
            <figure
              key={temoignage.nom + temoignage.accordLe}
              className="flex flex-col rounded-2xl border border-gray-200 bg-white p-6"
            >
              <Quote className="h-6 w-6 text-green-200 mb-4" aria-hidden="true" />
              <blockquote className="flex-1 text-sm leading-relaxed text-gray-700">
                « {temoignage.citation[language]} »
              </blockquote>
              <figcaption className="mt-5 flex items-center gap-3 border-t border-gray-100 pt-4">
                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-green-50 text-sm font-bold text-epilist-green">
                  {temoignage.nom.charAt(0)}
                </div>
                <div>
                  <div className="text-sm font-semibold text-gray-900">
                    {temoignage.nom}
                  </div>
                  {temoignage.role && (
                    <div className="text-xs text-gray-500">
                      {temoignage.role[language]}
                    </div>
                  )}
                </div>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
