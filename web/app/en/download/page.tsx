import type { Metadata } from "next";
import DownloadContent from "@/components/DownloadContent";
import { pageMetadata } from "@/lib/seo";

export const metadata: Metadata = pageMetadata("download", "en");

export default function DownloadPageEn() {
  return <DownloadContent />;
}
