import Link from "next/link";

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">404</h1>
        <h2 className="text-2xl font-semibold text-gray-700 mb-6">
          Page introuvable
        </h2>
        <p className="text-gray-600 mb-8">
          La page que vous cherchez n'existe pas ou a été déplacée.
        </p>
        <div className="space-y-4">
          <Link
            href="/"
            className="inline-block bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors"
          >
            Retour à l'accueil
          </Link>
          <div className="text-sm text-gray-500">
            <p>Pages populaires :</p>
            <div className="flex flex-wrap justify-center gap-4 mt-2">
              <Link
                href="/telecharger"
                className="text-green-600 hover:underline"
              >
                Télécharger
              </Link>
              <Link
                href="/fonctionnalites"
                className="text-green-600 hover:underline"
              >
                Fonctionnalités
              </Link>
              <Link href="/aide" className="text-green-600 hover:underline">
                Aide
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
