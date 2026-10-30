// Landing page for the link sent by email. Kept out of the sitemap and
// out of the index: it only means something for one token, once.
import type { Metadata } from "next";
import AccountDeletionConfirm from "@/components/AccountDeletionConfirm";

export const metadata: Metadata = {
  title: "Confirm deletion — EpiList",
  robots: { index: false, follow: false },
};

// Next 15: `params` is a promise now; the page awaits it.
export default async function ConfirmDeletionPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  return <AccountDeletionConfirm token={token} />;
}
