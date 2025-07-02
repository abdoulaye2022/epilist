// components/HomeButtons.tsx - COMPOSANT CLIENT POUR LES BOUTONS
"use client";

import { STORE_URLS } from "@/app/lib/constants";
import { Button } from "./Button";

export function HomeButtons() {
  const openAndroidStore = () => {
    window.open(STORE_URLS.android, "_blank");
  };

  const openIOSStore = () => {
    window.open(STORE_URLS.ios, "_blank");
  };

  return (
    <div className="space-y-3">
      <Button className="w-full" onClick={openAndroidStore}>
        📲 Télécharger sur Android
      </Button>

      <Button variant="outline" className="w-full" onClick={openIOSStore}>
        🍎 Télécharger sur iOS
      </Button>
    </div>
  );
}
