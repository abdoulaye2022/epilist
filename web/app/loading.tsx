// app/loading.tsx - PAGE DE CHARGEMENT GLOBALE

import { Spinner } from "./components/ui/Spinner";

export default function Loading() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <Spinner size="lg" className="mx-auto mb-4" />
        <p className="text-gray-600">Chargement...</p>
      </div>
    </div>
  );
}
