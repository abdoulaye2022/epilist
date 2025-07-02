"use client";

import { useEffect } from "react";
import { Card } from "./components/ui/Card";
import { ErrorButtons } from "./components/ui/ErrorButtons";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("Erreur globale:", error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-md w-full text-center">
        <div className="text-6xl mb-4">⚠️</div>
        <h1 className="text-2xl font-bold text-gray-800 mb-2">
          Une erreur s'est produite
        </h1>
        <p className="text-gray-600 mb-6">
          Désolé, quelque chose s'est mal passé. Veuillez réessayer.
        </p>

        <ErrorButtons onReset={reset} />
      </Card>
    </div>
  );
}
