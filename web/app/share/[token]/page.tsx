// Page d'arrivée d'un lien de partage. Hors index : une invitation ne
// se référence pas, elle se transmet.
import type { Metadata } from "next";
import ShareLanding from "@/components/ShareLanding";

export const metadata: Metadata = {
  title: "Invitation — EpiList",
  robots: { index: false, follow: false },
};

export default function SharePage({ params }: { params: { token: string } }) {
  return <ShareLanding token={params.token} />;
}
