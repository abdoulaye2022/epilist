import { Card } from "./components/ui/Card";
import { HomeButtons } from "./components/ui/HomeButtons";

export default function HomePage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-lg w-full text-center">
        <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-green-600 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-6 shadow-lg">
          📱
        </div>

        <h1 className="text-3xl font-bold text-gray-800 mb-4">EpiList</h1>

        <p className="text-gray-600 mb-8">
          Vos listes de courses partagées en famille ou entre amis
        </p>

        <HomeButtons />

        <div className="mt-8 pt-6 border-t border-gray-200">
          <p className="text-sm text-gray-500">
            Vous avez reçu une invitation ? Elle s'ouvrira automatiquement dans
            l'application.
          </p>
        </div>
      </Card>
    </div>
  );
}
