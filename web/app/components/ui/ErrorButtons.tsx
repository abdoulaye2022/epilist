// components/ErrorButtons.tsx - COMPOSANT CLIENT POUR LES BOUTONS D'ERREUR
"use client";

import { Button } from "./Button";

interface ErrorButtonsProps {
  onReset: () => void;
}

export function ErrorButtons({ onReset }: ErrorButtonsProps) {
  const goHome = () => {
    window.location.href = "/";
  };

  return (
    <div className="space-y-2">
      <Button onClick={onReset} className="w-full">
        Réessayer
      </Button>
      <Button variant="outline" onClick={goHome} className="w-full">
        Retour à l'accueil
      </Button>
    </div>
  );
}
