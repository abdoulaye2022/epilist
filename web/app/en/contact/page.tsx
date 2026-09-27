import type { Metadata } from "next";
import ContactContent from "@/components/ContactContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("contact", "en");

export default function ContactPageEn() {
  return <ContactContent />;
}
