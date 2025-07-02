// app/share/[token]/page.tsx - PAGE DE PARTAGE CORRIGÉE
import { Metadata } from "next";
import { notFound } from "next/navigation";
import type { InvitationData } from "@/types";
import { getInvitationData } from "@/app/lib/api";
import ShareRedirect from "@/app/components/ShareRedirect";
import { ShareErrorFallback } from "@/app/components/ShareErrorFallback";

interface SharePageProps {
  params: {
    token: string;
  };
}

// ✅ Génération dynamique des métadonnées (inchangée)
export async function generateMetadata({
  params,
}: SharePageProps): Promise<Metadata> {
  const { token } = params;

  try {
    const invitationData = await getInvitationData(token);

    const title = `Invitation EpiList - ${invitationData.listName}`;
    const description = `${invitationData.ownerName} vous invite à collaborer sur la liste "${invitationData.listName}"`;
    const url = `https://epilist.app/share/${token}`;

    return {
      title,
      description,
      openGraph: {
        title,
        description,
        type: "website",
        url,
        images: [
          {
            url: "/logo.png",
            width: 1200,
            height: 630,
            alt: `Invitation EpiList - ${invitationData.listName}`,
          },
        ],
      },
      twitter: {
        card: "summary_large_image",
        title,
        description,
        images: ["/logo.png"],
      },
      alternates: {
        canonical: url,
      },
      robots: {
        index: false,
        follow: false,
      },
    };
  } catch (error) {
    return {
      title: "Invitation EpiList",
      description: "Invitation à collaborer sur une liste de courses",
      robots: {
        index: false,
        follow: false,
      },
    };
  }
}

// ✅ Server Component qui gère les données et passe au Client Component
export default async function SharePage({ params }: SharePageProps) {
  const { token } = params;

  // Validation basique du token
  if (!token || token.length < 8) {
    notFound();
  }

  try {
    // ✅ Récupération des données côté serveur
    const invitationData = await getInvitationData(token);

    // Vérification de l'expiration côté serveur
    if (invitationData.isExpired) {
      return (
        <ShareErrorFallback
          type="expired"
          listName={invitationData.listName}
          ownerName={invitationData.ownerName}
        />
      );
    }

    // ✅ Passer les données au composant client
    return <ShareRedirect token={token} invitationData={invitationData} />;
  } catch (error) {
    console.error("Erreur lors de la récupération de l'invitation:", error);

    // ✅ Fallback vers le composant client avec gestion d'erreur
    return <ShareRedirect token={token} invitationData={null} />;
  }
}

export const dynamic = "force-dynamic";
export const revalidate = 0;
