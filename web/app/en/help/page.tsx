import type { Metadata } from "next";
import HelpContent from "@/components/HelpContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("help", "en");

export default function HelpPageEn() {
  return <HelpContent />;
}
