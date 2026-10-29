"use client";

// Ce qui décide si un traceur a le droit d'exister dans la page.
//
// La différence tient en un mot : les scripts ne sont pas MASQUÉS tant
// qu'il n'y a pas de consentement, ils ne sont pas MONTÉS. Un script
// tiers qui s'exécute a déjà vu l'adresse IP, l'agent utilisateur, et
// posé ce qu'il voulait poser — le désactiver après coup ne rattrape
// rien.
//
// Trois portes, de la plus large à la plus étroite :
//
//   - jamais sous /admin, quel que soit le consentement : le jeton
//     d'administration vit dans le navigateur, et Hotjar enregistrerait
//     des écrans pleins de données d'utilisateurs ;
//   - jamais avant que la personne ait choisi ;
//   - ensuite, chacun selon sa catégorie.
import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import {
  CategorieConsentement,
  Consentement,
  EVENEMENT_CHANGEMENT,
  lireConsentement,
} from "@/lib/consent";

export default function ConsentGate({
  categorie,
  children,
}: {
  categorie: CategorieConsentement;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [choix, setChoix] = useState<Consentement | null>(null);
  const [monte, setMonte] = useState(false);

  useEffect(() => {
    setChoix(lireConsentement());
    setMonte(true);

    const surChangement = (e: Event) => {
      setChoix((e as CustomEvent).detail as Consentement | null);
    };

    window.addEventListener(EVENEMENT_CHANGEMENT, surChangement);
    return () => window.removeEventListener(EVENEMENT_CHANGEMENT, surChangement);
  }, []);

  // Le rendu serveur ne connaît pas le choix : on ne monte rien tant
  // qu'on n'est pas côté navigateur, sinon le script partirait dans le
  // HTML initial — c'est-à-dire avant toute décision.
  if (!monte) return null;

  if (pathname?.startsWith("/admin")) return null;

  if (!choix || !choix[categorie]) return null;

  return <>{children}</>;
}
