// components/NotFoundButton.tsx - COMPOSANT CLIENT POUR BOUTON 404
"use client";

import { Button } from "./ui/Button";

export function NotFoundButton() {
  const goHome = () => {
    window.location.href = "/";
  };

  return (
    <Button onClick={goHome} className="w-full">
      Retour à l'accueil
    </Button>
  );
}
