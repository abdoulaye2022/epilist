import type { Metadata } from "next";
import AboutContent from "@/components/AboutContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("about", "en");

export default function AboutPageEn() {
  return <AboutContent />;
}
