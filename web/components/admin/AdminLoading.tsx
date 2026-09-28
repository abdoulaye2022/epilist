"use client";

// Indicateur de chargement commun aux pages admin : les requêtes
// d'agrégation peuvent être lentes, l'utilisateur doit le voir.
import { Loader2 } from "lucide-react";

export default function AdminLoading({ label = "Chargement des données…" }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-24 text-gray-500">
      <Loader2 className="h-8 w-8 animate-spin text-green-600" />
      <p className="text-sm">{label}</p>
    </div>
  );
}
