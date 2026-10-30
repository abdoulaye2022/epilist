// Page d'arrivée d'un lien de partage. Hors index : une invitation ne
// se référence pas, elle se transmet.
import type { Metadata } from "next";
import ShareLanding from "@/components/ShareLanding";

export const metadata: Metadata = {
  title: "Invitation — EpiList",
  robots: { index: false, follow: false },
};

// Next 15 : `params` arrive en promesse, la page l'attend.
export default async function SharePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  return <ShareLanding token={token} />;
}
