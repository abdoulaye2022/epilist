import type { Metadata } from "next";
import TermsContent from "@/components/TermsContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("terms", "en");

export default function TermsOfUsePageEn() {
  return <TermsContent />;
}
