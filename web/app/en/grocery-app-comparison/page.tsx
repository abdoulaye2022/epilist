import type { Metadata } from "next";
import ComparisonContent from "@/components/ComparisonContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("comparison", "en");

export default function GroceryAppComparisonPageEn() {
  return <ComparisonContent />;
}
