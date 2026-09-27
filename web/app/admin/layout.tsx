import type { Metadata } from "next";
import AdminShell from "@/components/admin/AdminShell";

// Espace privé : jamais indexé.
export const metadata: Metadata = {
  title: "Administration — EpiList",
  robots: { index: false, follow: false },
};

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AdminShell>{children}</AdminShell>;
}
