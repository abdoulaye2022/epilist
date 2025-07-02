// components/ShareErrorFallback.tsx - COMPOSANT POUR LES ERREURS DE PARTAGE

import { Card } from "./ui/Card";

interface ShareErrorFallbackProps {
  type: "expired" | "invalid" | "error";
  listName?: string;
  ownerName?: string;
  message?: string;
}

export function ShareErrorFallback({
  type,
  listName,
  ownerName,
  message,
}: ShareErrorFallbackProps) {
  const getContent = () => {
    switch (type) {
      case "expired":
        return {
          icon: "⏰",
          title: "Invitation expirée",
          description: `Cette invitation pour la liste "${listName}" a expiré.`,
          help: `Contactez ${ownerName} pour recevoir une nouvelle invitation.`,
        };
      case "invalid":
        return {
          icon: "❌",
          title: "Invitation invalide",
          description:
            message || "Cette invitation n'existe pas ou n'est plus valide.",
          help: "Vérifiez le lien reçu ou contactez la personne qui vous a invité.",
        };
      default:
        return {
          icon: "⚠️",
          title: "Erreur",
          description:
            message ||
            "Une erreur s'est produite lors du chargement de l'invitation.",
          help: "Veuillez réessayer plus tard.",
        };
    }
  };

  const content = getContent();

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="max-w-md w-full text-center">
        <div className="text-6xl mb-4">{content.icon}</div>
        <h1 className="text-2xl font-bold text-gray-800 mb-2">
          {content.title}
        </h1>
        <p className="text-gray-600 mb-4">{content.description}</p>
        {content.help && (
          <p className="text-sm text-gray-500">{content.help}</p>
        )}
      </Card>
    </div>
  );
}
