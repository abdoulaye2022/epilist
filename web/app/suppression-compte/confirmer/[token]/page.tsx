// Page d'arrivee du lien recu par courriel. Hors sitemap et hors index :
// elle n'a de sens que pour un jeton donne, une seule fois.
import type { Metadata } from "next";
import AccountDeletionConfirm from "@/components/AccountDeletionConfirm";

export const metadata: Metadata = {
  title: "Confirmer la suppression — EpiList",
  robots: { index: false, follow: false },
};

// Next 15 : `params` arrive en promesse, la page l'attend.
export default async function ConfirmerSuppressionPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  return <AccountDeletionConfirm token={token} />;
}
