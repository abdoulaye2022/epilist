// Page d'arrivee du lien recu par courriel. Hors sitemap et hors index :
// elle n'a de sens que pour un jeton donne, une seule fois.
import type { Metadata } from "next";
import AccountDeletionConfirm from "@/components/AccountDeletionConfirm";

export const metadata: Metadata = {
  title: "Confirmer la suppression — EpiList",
  robots: { index: false, follow: false },
};

export default function ConfirmerSuppressionPage({
  params,
}: {
  params: { token: string };
}) {
  return <AccountDeletionConfirm token={params.token} />;
}
