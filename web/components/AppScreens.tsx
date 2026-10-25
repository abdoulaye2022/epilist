"use client";

// L'interface de l'application, telle qu'elle est AUJOURD'HUI.
//
// Les deux captures que le site montrait (app-fr.jpg, dash.png) datent
// de deux refontes : bandeau bleu « Bonjour Alex », bouton « + » central
// dans la barre du bas, « Mes Listes d'Épicerie » en majuscules. Rien de
// tout cela n'existe encore.
//
// Ces écrans sont REDESSINÉS en HTML, avec les jetons de couleur, les
// rayons et les tailles du thème de l'application (app/lib/theme/
// app_theme.dart). Pourquoi pas des captures : une capture vieillit en
// silence — c'est précisément ce qui vient d'arriver — alors qu'un écran
// redessiné se relit, se corrige, reste net sur tout écran et se traduit.
//
// Si vous préférez de vraies captures, elles se déposent dans public/ et
// remplacent <AppScreen /> : la mise en page du cadre ne change pas.
import { useLanguage } from "@/hooks/useLanguage";

/* --------------------------------------------------------------------
 * Les jetons du thème de l'application, repris tels quels.
 * ------------------------------------------------------------------ */
const T = {
  fond: "#FFFDF9",
  surface: "#FFFFFF",
  bordure: "#DCE8CE",
  encre: "#111827",
  encreDouce: "#4B5563",
  vert: "#15803D",
  vertFonce: "#166534",
  vertClair: "#DCFCE7",
  vertVif: "#22C55E",
  orange: "#F97316",
  surOrange: "#3B2200",
  orangeEncre: "#C2410C",
  rouge: "#B91C1C",
  violet: "#6D28D9",
  or: "#FACC15",
  orEncre: "#854D0E",
} as const;

/* --------------------------------------------------------------------
 * Les textes des maquettes, dans les deux langues.
 *
 * Ils vivent ICI et non dans lib/translations.ts : ce sont des libellés
 * d'illustration, pas des textes du site. Les garder a cote de l'ecran
 * qu'ils remplissent evite quarante clefs de plus dans le fichier
 * commun, et evite surtout qu'on les traduise sans voir ce qu'ils
 * illustrent.
 * ------------------------------------------------------------------ */
type Article = {
  nom: string;
  etat: string;
  couleur: string;
  qte: string;
  ligne: string;
};

type Zone = { nom: string; couleur: string; articles: Article[] };

type TextesAccueil = {
  titre: string;
  bonjour: string;
  pret: string;
  creer: string;
  tuiles: string[];
  budgetTitre: string;
  depense: string;
  sur: string;
  jauge: string;
  reste: string;
  rythme: string;
  nav: string[];
};

type TextesMaison = { titre: string; zones: Zone[]; ajouter: string };

type TextesMagasin = {
  titre: string;
  compte: string;
  phrase: string;
  total: string;
  budget: string;
  filtres: string[];
  rayon: string;
  articles: { nom: string; sous: string; coche: boolean; prix: string }[];
  panier: string;
  terminer: string;
};

type TextesEcrans = {
  titre: string;
  sous: string;
  legendes: string[];
  accueil: TextesAccueil;
  maison: TextesMaison;
  magasin: TextesMagasin;
};

const textes: Record<"fr" | "en", TextesEcrans> = {
  fr: {
    titre: "L'application, telle qu'elle est aujourd'hui",
    sous: "Trois écrans parmi dix. Rien n'y est décoratif : chaque état est écrit, chaque chiffre dessiné est doublé du même chiffre en toutes lettres.",
    legendes: [
      "Le tableau de bord : quatre gestes du quotidien, et le budget en orange, écrit.",
      "À la maison : vos provisions rangées par endroit, chacune avec son état et sa quantité.",
      "Au magasin : le prix s'entre l'étiquette sous les yeux, et le total suit.",
    ],
    accueil: {
      titre: "EpiList",
      bonjour: "Bonjour 👋",
      pret: "Prêt pour les prochaines courses ?",
      creer: "+ Créer une liste",
      tuiles: ["Dicter ma liste", "Scanner un reçu", "Planifier mes repas", "Mes magasins"],
      budgetTitre: "Budget du 1er au 31 octobre",
      depense: "127,45 $",
      sur: "/ 400,00 $",
      jauge: "32 pour cent utilisé",
      reste: "Encore 272,55 $",
      rythme: "À votre rythme actuel : ~310 $ · 8 jours restants",
      nav: ["Accueil", "Listes", "Avant", "Alertes", "Sections"],
    },
    maison: {
      titre: "À la maison",
      zones: [
        {
          nom: "Garde-manger (4)",
          couleur: T.or,
          articles: [
            { nom: "Riz basmati", etat: "Stock bas", couleur: T.orangeEncre, qte: "1 sac", ligne: "Quantité restante : 1 sac, pour un seuil de 1 sac." },
          ],
        },
        {
          nom: "Réfrigérateur (3)",
          couleur: T.vertVif,
          articles: [
            { nom: "Lait 2 %", etat: "À terminer dans 2 jours", couleur: T.violet, qte: "2 L", ligne: "Quantité restante : 2 L." },
            { nom: "Œufs", etat: "Disponible", couleur: T.vert, qte: "12", ligne: "Quantité restante : 12, pour un seuil de 6." },
          ],
        },
        {
          nom: "Congélateur (2)",
          couleur: "#2563EB",
          articles: [
            { nom: "Petits pois", etat: "Disponible", couleur: T.vert, qte: "2 sacs", ligne: "Quantité restante : 2 sacs, pour un seuil de 1 sac." },
          ],
        },
      ],
      ajouter: "Ajouter un produit ici",
    },
    magasin: {
      titre: "Metro Sainte-Catherine",
      compte: "14 / 17 dans le panier",
      phrase: "Vous avez déjà mis 14 articles dans le panier. Encore 3 articles et vos courses sont terminées.",
      total: "Total : 87,40 $",
      budget: "Reste dans le budget : 272,55 $",
      filtres: ["Tout", "À prendre (3)", "Dans le panier (14)"],
      rayon: "Fruits et légumes",
      articles: [
        { nom: "Pommes Gala", sous: "Quantité : 6", coche: true, prix: "4,99 $" },
        { nom: "Bœuf haché", sous: "Quantité : 1", coche: false, prix: "Prix" },
        { nom: "Bananes", sous: "Quantité : 1,2 kg", coche: true, prix: "2,18 $" },
      ],
      panier: "Dans le panier",
      terminer: "Terminer mes courses",
    },
  },
  en: {
    titre: "The app, as it is today",
    sous: "Three screens out of ten. Nothing here is decorative: every status is written out, and every figure drawn is doubled by the same figure in words.",
    legendes: [
      "The dashboard: four everyday actions, and the budget in orange, written out.",
      "At home: your supplies grouped by where they are kept, each with its status and quantity.",
      "At the store: the price goes in with the label in front of you, and the total follows.",
    ],
    accueil: {
      titre: "EpiList",
      bonjour: "Hello 👋",
      pret: "Ready for your next groceries?",
      creer: "+ Create a list",
      tuiles: ["Dictate my list", "Scan a receipt", "Plan my meals", "My stores"],
      budgetTitre: "Budget from 1 to 31 October",
      depense: "$127.45",
      sur: "/ $400.00",
      jauge: "32 per cent used",
      reste: "$272.55 left",
      rythme: "At your current pace: ~$310 · 8 days left",
      nav: ["Home", "Lists", "Before", "Alerts", "Sections"],
    },
    maison: {
      titre: "At home",
      zones: [
        {
          nom: "Pantry (4)",
          couleur: T.or,
          articles: [
            { nom: "Basmati rice", etat: "Low stock", couleur: T.orangeEncre, qte: "1 bag", ligne: "Quantity left: 1 bag, for a threshold of 1 bag." },
          ],
        },
        {
          nom: "Fridge (3)",
          couleur: T.vertVif,
          articles: [
            { nom: "Milk 2%", etat: "Finish within 2 days", couleur: T.violet, qte: "2 L", ligne: "Quantity left: 2 L." },
            { nom: "Eggs", etat: "Available", couleur: T.vert, qte: "12", ligne: "Quantity left: 12, for a threshold of 6." },
          ],
        },
        {
          nom: "Freezer (2)",
          couleur: "#2563EB",
          articles: [
            { nom: "Green peas", etat: "Available", couleur: T.vert, qte: "2 bags", ligne: "Quantity left: 2 bags, for a threshold of 1 bag." },
          ],
        },
      ],
      ajouter: "Add a product here",
    },
    magasin: {
      titre: "Metro Sainte-Catherine",
      compte: "14 / 17 in the basket",
      phrase: "You have already put 14 items in the basket. 3 more items and your shopping is done.",
      total: "Total: $87.40",
      budget: "Left in the budget: $272.55",
      filtres: ["All", "To get (3)", "In the basket (14)"],
      rayon: "Fruit and vegetables",
      articles: [
        { nom: "Gala apples", sous: "Quantity: 6", coche: true, prix: "$4.99" },
        { nom: "Ground beef", sous: "Quantity: 1", coche: false, prix: "Price" },
        { nom: "Bananas", sous: "Quantity: 1.2 kg", coche: true, prix: "$2.18" },
      ],
      panier: "In the basket",
      terminer: "Finish my shopping",
    },
  },
};

/* --------------------------------------------------------------------
 * Le cadre de téléphone. Il ne porte aucune marque : c'est l'écran
 * qu'on regarde, pas l'appareil.
 * ------------------------------------------------------------------ */
function Cadre({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="relative mx-auto w-full max-w-[280px] rounded-[2rem] border-[6px] border-gray-900/90 bg-gray-900 shadow-2xl"
      aria-hidden="true"
    >
      <div
        className="overflow-hidden rounded-[1.6rem]"
        style={{ backgroundColor: T.fond }}
      >
        {children}
      </div>
    </div>
  );
}

/* --------------------------------------------------------------------
 * Les icônes de l'application, au trait.
 *
 * Elles reprennent une a une celles de `AppIcons` (app/lib/theme/
 * app_icons.dart) et de la barre du bas : quatre carrés pour le tableau
 * de bord, une liste à coches, un bloc-notes vérifié, une étiquette de
 * prix, des étagères. Un carré vide ne disait rien ; une icône dit sa
 * section.
 * ------------------------------------------------------------------ */
const GLYPHES = {
  dashboard: "M3.5 3.5h6v8h-6zM14.5 3.5h6v5h-6zM14.5 11.5h6v9h-6zM3.5 14.5h6v6h-6z",
  listes: "M3 6.2l1.6 1.6L7.8 4.6M3 12.4l1.6 1.6 3.2-3.2M3 18.6l1.6 1.6 3.2-3.2M11.5 6.2H21M11.5 12.4H21M11.5 18.6H21",
  avant: "M4 4.5h16v15H4zM7.5 10.3l1.7 1.7 3-3M7.5 15.8h4.5M14.5 9.8H17M14.5 15.3H17",
  alertes: "M20.6 11.4l-8-8A2 2 0 0 0 11.2 3H5.4A2.4 2.4 0 0 0 3 5.4v5.8c0 .5.2 1 .6 1.4l8 8a2 2 0 0 0 2.8 0l6.2-6.2a2 2 0 0 0 0-3zM7.4 7.4h.01",
  provisions: "M4 3.5v17M20 3.5v17M4 3.5h16M4 9.5h16M4 15.5h16M4 20.5h16",
  micro: "M12 3.2a2.8 2.8 0 0 1 2.8 2.8v5.6a2.8 2.8 0 0 1-5.6 0V6A2.8 2.8 0 0 1 12 3.2zM5.4 11.2a6.6 6.6 0 0 0 13.2 0M12 17.8v3",
  appareil: "M3.2 7.6h3.9l1.8-2.2h6.2l1.8 2.2h3.9v11.8H3.2zM12 16.8a3.4 3.4 0 1 0 0-6.8 3.4 3.4 0 0 0 0 6.8z",
  calendrier: "M3.5 5.2h17v15.3h-17zM3.5 10h17M8.2 2.8v4.2M15.8 2.8v4.2",
  magasin: "M3 4.2h18l1.2 4.8a3.2 3.2 0 0 1-6.4 0 3.2 3.2 0 0 1-6.4 0 3.2 3.2 0 0 1-6.4 0zM4.6 10.5v9.3h14.8v-9.3M9.6 19.8v-5.6h4.8v5.6",
} as const;

function Glyphe({
  nom,
  taille,
}: {
  nom: keyof typeof GLYPHES;
  taille: number;
}) {
  return (
    <svg
      width={taille}
      height={taille}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d={GLYPHES[nom]} />
    </svg>
  );
}

function BarreDuBas({ onglets }: { onglets: string[] }) {
  return (
    <div
      className="flex items-center justify-between border-t-2 px-2 pb-2 pt-1.5"
      style={{ borderColor: T.bordure, backgroundColor: T.surface }}
    >
      {onglets.map((nom, i) => (
        <div key={nom} className="flex flex-1 flex-col items-center gap-0.5">
          <div
            className="flex h-6 w-6 items-center justify-center rounded-full"
            style={{
              backgroundColor: i === 0 ? T.vertClair : "transparent",
              color: i === 0 ? T.vertFonce : T.encreDouce,
            }}
          >
            <Glyphe
              nom={
                (["dashboard", "listes", "avant", "alertes", "provisions"] as const)[
                  i
                ]
              }
              taille={14}
            />
          </div>
          {i === 0 && (
            <span
              className="text-[7px] font-bold leading-none"
              style={{ color: T.vert }}
            >
              {nom}
            </span>
          )}
        </div>
      ))}
    </div>
  );
}

/* ------------------------------ 1. Accueil ------------------------- */
function EcranAccueil({ l }: { l: TextesAccueil }) {
  return (
    <div className="flex h-[480px] flex-col">
      <div
        className="flex-1 overflow-hidden px-3 pt-3"
        style={{
          background:
            "linear-gradient(170deg, #DCFCE7 0%, #ECFCCB 45%, #FEF9C3 100%)",
        }}
      >
        {/* L'ORDRE est celui de l'application : salutation, budget,
            projection, bouton de création, puis les quatre actions. */}
        <div className="mb-2 flex items-center gap-2">
          <span
            className="flex h-7 w-7 items-center justify-center rounded-full text-[9px] font-extrabold"
            style={{ backgroundColor: T.vertClair, color: T.vertFonce }}
          >
            AM
          </span>
          <span className="min-w-0 flex-1">
            <span
              className="block truncate text-[12px] font-extrabold"
              style={{ color: T.encre }}
            >
              {l.bonjour}
            </span>
            <span
              className="block truncate text-[8px]"
              style={{ color: T.encre }}
            >
              {l.pret}
            </span>
          </span>
          <span className="flex flex-col gap-[3px]">
            <span className="block h-[2px] w-3.5 rounded bg-gray-800" />
            <span className="block h-[2px] w-3.5 rounded bg-gray-800" />
            <span className="block h-[2px] w-3.5 rounded bg-gray-800" />
          </span>
        </div>

        {/* La carte budget : orange, encre sombre, et tout est écrit. */}
        <div
          className="rounded-2xl px-3 py-2.5"
          style={{ backgroundColor: T.orange }}
        >
          <div className="text-[9px] font-bold" style={{ color: T.surOrange }}>
            {l.budgetTitre}
          </div>
          <div className="mt-1 flex items-baseline gap-1">
            <span
              className="text-[17px] font-extrabold leading-none"
              style={{ color: T.surOrange }}
            >
              {l.depense}
            </span>
            <span
              className="text-[9px] font-semibold"
              style={{ color: T.surOrange, opacity: 0.75 }}
            >
              {l.sur}
            </span>
          </div>
          <div
            className="mt-1.5 h-2 w-full overflow-hidden rounded-full"
            style={{ backgroundColor: "rgba(59,34,0,0.22)" }}
          >
            <div
              className="h-full rounded-full"
              style={{ width: "32%", backgroundColor: T.vertVif }}
            />
          </div>
          <div
            className="mt-1 flex items-center justify-between text-[8px] font-semibold"
            style={{ color: T.surOrange }}
          >
            <span>{l.jauge}</span>
            <span>{l.reste}</span>
          </div>
        </div>

        <div
          className="mt-1.5 rounded-xl border px-2.5 py-1.5 text-[8px] leading-snug"
          style={{
            backgroundColor: T.surface,
            borderColor: T.bordure,
            color: T.encre,
          }}
        >
          {l.rythme}
        </div>

        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/chariot.svg"
          alt=""
          aria-hidden="true"
          className="mx-auto mt-1.5 h-[86px] w-auto"
        />

        <div
          className="mt-1 mb-2 rounded-full py-2 text-center text-[11px] font-extrabold"
          style={{ backgroundColor: T.vertVif, color: T.encre }}
        >
          {l.creer}
        </div>

        <div className="grid grid-cols-2 gap-1.5">
          {l.tuiles.map((nom, i) => (
            <div
              key={nom}
              className="rounded-xl border-2 px-2 py-2"
              style={{
                backgroundColor: T.surface,
                borderColor: [T.vertVif, "#2563EB", T.or, T.orange][i],
              }}
            >
              <div
                className="mb-1"
                style={{ color: [T.vert, "#1D4ED8", T.orEncre, T.orangeEncre][i] }}
              >
                <Glyphe
                  nom={
                    (["micro", "appareil", "calendrier", "magasin"] as const)[i]
                  }
                  taille={15}
                />
              </div>
              <div
                className="text-[8.5px] font-bold leading-tight"
                style={{ color: T.encre }}
              >
                {nom}
              </div>
            </div>
          ))}
        </div>
      </div>
      <BarreDuBas onglets={l.nav} />
    </div>
  );
}

/* ------------------------- 2. À la maison -------------------------- */
function Badge({ couleur }: { couleur: string }) {
  // La pastille PLEINE du thème : elle garde son propre fond, donc elle
  // reste lisible sur les fonds colorés des zones.
  return (
    <span
      className="inline-block h-3 w-3 shrink-0 rounded-full ring-2 ring-white"
      style={{ backgroundColor: couleur }}
    />
  );
}

function EcranMaison({ l }: { l: TextesMaison }) {
  return (
    <div className="flex h-[480px] flex-col">
      <div
        className="flex items-center gap-2 px-3 py-2.5"
        style={{ backgroundColor: T.surface }}
      >
        <span className="text-[13px] font-extrabold" style={{ color: T.encre }}>
          {l.titre}
        </span>
      </div>
      <div className="flex-1 space-y-2 overflow-hidden px-3 py-2">
        {l.zones.map((zone) => (
          <div
            key={zone.nom}
            className="rounded-2xl border-2 p-2.5"
            style={{
              backgroundColor: `${zone.couleur}1A`,
              borderColor: `${zone.couleur}59`,
            }}
          >
            <div
              className="mb-1.5 text-[10px] font-extrabold"
              style={{ color: T.encre }}
            >
              {zone.nom}
            </div>
            {zone.articles.map((a) => (
              <div key={a.nom} className="mb-1.5 last:mb-0">
                <div
                  className="text-[10px] font-bold"
                  style={{ color: T.encre }}
                >
                  {a.nom}
                </div>
                <div className="mt-0.5 flex items-center gap-1">
                  <Badge couleur={a.couleur} />
                  <span
                    className="text-[8.5px] font-bold"
                    style={{ color: a.couleur }}
                  >
                    {a.etat}
                  </span>
                </div>
                <div
                  className="mt-0.5 text-[8px]"
                  style={{ color: T.encreDouce }}
                >
                  {a.ligne}
                </div>
                <div className="mt-1 flex items-center gap-1.5">
                  {["−", "+"].map((signe) => (
                    <span
                      key={signe}
                      className="flex h-5 w-5 items-center justify-center rounded-full border text-[11px] font-bold"
                      style={{
                        borderColor: T.bordure,
                        backgroundColor: T.surface,
                        color: T.encre,
                      }}
                    >
                      {signe}
                    </span>
                  ))}
                  <span
                    className="text-[9px] font-extrabold"
                    style={{ color: T.encre }}
                  >
                    {a.qte}
                  </span>
                </div>
              </div>
            ))}
            <div
              className="mt-1.5 rounded-full border py-1 text-center text-[8px] font-bold"
              style={{ borderColor: T.vert, color: T.vert }}
            >
              {l.ajouter}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ------------------------ 3. Mode en magasin ----------------------- */
function EcranMagasin({ l }: { l: TextesMagasin }) {
  return (
    <div className="flex h-[480px] flex-col">
      <div
        className="px-3 py-2.5 text-[12px] font-extrabold"
        style={{ backgroundColor: T.surface, color: T.encre }}
      >
        {l.titre}
      </div>

      <div className="px-3 pt-2">
        <div
          className="rounded-2xl px-3 py-2.5"
          style={{ backgroundColor: T.or }}
        >
          <div
            className="text-[14px] font-extrabold leading-tight"
            style={{ color: T.surOrange }}
          >
            {l.compte}
          </div>
          <div
            className="mt-0.5 text-[8px] leading-snug"
            style={{ color: T.surOrange }}
          >
            {l.phrase}
          </div>
          <div
            className="mt-1.5 h-2 w-full overflow-hidden rounded-full"
            style={{ backgroundColor: "rgba(59,34,0,0.22)" }}
          >
            <div
              className="h-full rounded-full"
              style={{ width: "82%", backgroundColor: T.vert }}
            />
          </div>
        </div>

        <div
          className="mt-1.5 text-[9px] font-extrabold"
          style={{ color: T.encre }}
        >
          {l.total}
        </div>
        <div className="text-[8px]" style={{ color: T.encreDouce }}>
          {l.budget}
        </div>

        <div className="mt-1.5 flex gap-1">
          {l.filtres.map((f, i) => (
            <span
              key={f}
              className="rounded-full border px-1.5 py-[3px] text-[7.5px] font-bold"
              style={{
                borderColor: i === 0 ? T.vert : T.bordure,
                backgroundColor: i === 0 ? T.vertClair : T.surface,
                color: i === 0 ? T.vertFonce : T.encreDouce,
              }}
            >
              {f}
            </span>
          ))}
        </div>

        <div
          className="mt-2 text-[9px] font-extrabold"
          style={{ color: T.vert }}
        >
          {l.rayon}
        </div>

        {l.articles.map((a) => (
          <div
            key={a.nom}
            className="mt-1.5 flex items-center gap-2 rounded-xl border-2 px-2 py-2"
            style={{
              borderColor: a.coche ? T.vertVif : T.bordure,
              backgroundColor: a.coche ? `${T.vertVif}1A` : T.surface,
            }}
          >
            <span
              className="flex h-4 w-4 shrink-0 items-center justify-center rounded border-2 text-[9px] font-black"
              style={{
                borderColor: a.coche ? T.vert : T.encreDouce,
                backgroundColor: a.coche ? T.vert : "transparent",
                color: "#fff",
              }}
            >
              {a.coche ? "✓" : ""}
            </span>
            <span className="min-w-0 flex-1">
              <span
                className="block truncate text-[10px] font-bold"
                style={{ color: a.coche ? T.encreDouce : T.encre }}
              >
                {a.nom}
              </span>
              <span className="block text-[8px]" style={{ color: T.encreDouce }}>
                {a.sous}
              </span>
              {a.coche && (
                <span
                  className="block text-[8px] font-extrabold"
                  style={{ color: T.vert }}
                >
                  {l.panier}
                </span>
              )}
            </span>
            <span
              className="shrink-0 rounded-full border px-2 py-1 text-[8.5px] font-extrabold"
              style={{
                borderColor: T.bordure,
                color: a.coche ? T.vertFonce : T.encreDouce,
              }}
            >
              {a.prix}
            </span>
          </div>
        ))}

        <div
          className="mt-2 rounded-full py-1.5 text-center text-[9px] font-extrabold"
          style={{ backgroundColor: T.vert, color: "#fff" }}
        >
          {l.terminer}
        </div>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
export function AppScreenAccueil() {
  const { language } = useLanguage();
  const l = textes[language === "en" ? "en" : "fr"];
  return (
    <Cadre>
      <EcranAccueil l={l.accueil} />
    </Cadre>
  );
}

export default function AppScreens() {
  const { language } = useLanguage();
  const l = textes[language === "en" ? "en" : "fr"];

  const ecrans = [
    <EcranAccueil key="a" l={l.accueil} />,
    <EcranMaison key="m" l={l.maison} />,
    <EcranMagasin key="s" l={l.magasin} />,
  ];

  return (
    <section id="interface" className="bg-white py-20">
      <div className="container mx-auto px-4">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 md:text-4xl">
            {l.titre}
          </h2>
          <p className="mt-4 text-lg leading-relaxed text-gray-600">{l.sous}</p>
        </div>

        <div className="mt-14 grid gap-10 md:grid-cols-3">
          {ecrans.map((ecran, i) => (
            <figure key={i} className="flex flex-col items-center">
              <Cadre>{ecran}</Cadre>
              <figcaption className="mt-5 max-w-[17rem] text-center text-sm leading-relaxed text-gray-600">
                {l.legendes[i]}
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}
