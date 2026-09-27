import type { Metadata } from "next";
import PageContent from "@/components/PageContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("home", "en");

export default function HomePageEn() {
  return (
    <main id="main-content">
      <PageContent />
    </main>
  );
}
