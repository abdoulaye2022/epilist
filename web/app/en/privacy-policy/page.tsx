import type { Metadata } from "next";
import PrivacyContent from "@/components/PrivacyContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("privacy", "en");

export default function PrivacyPolicyPageEn() {
  return <PrivacyContent />;
}
