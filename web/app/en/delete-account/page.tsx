import type { Metadata } from "next";
import AccountDeletionContent from "@/components/AccountDeletionContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("accountDeletion", "en");

export default function DeleteAccountPage() {
  return <AccountDeletionContent />;
}
