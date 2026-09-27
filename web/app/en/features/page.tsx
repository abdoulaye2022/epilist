import type { Metadata } from "next";
import FeaturesContent from "@/components/FeaturesContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("features", "en");

export default function FeaturesPageEn() {
  return <FeaturesContent />;
}
