// app/not-found.tsx - PAGE 404 CORRIGÉE

import { NotFoundButton } from "./components/NotFoundButton";
import { Card } from "./components/ui/Card";

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-md w-full text-center">
        <div className="text-6xl mb-4">🔍</div>
        <h1 className="text-2xl font-bold text-gray-800 mb-2">
          Page non trouvée
        </h1>
        <p className="text-gray-600 mb-6">
          La page que vous recherchez n'existe pas ou a été déplacée.
        </p>

        <NotFoundButton />
      </Card>
    </div>
  );
}
