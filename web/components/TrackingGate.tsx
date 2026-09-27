"use client";

// Ne rend les scripts tiers (GA, pixel Facebook, Hotjar) nulle part sous
// /admin : le jeton admin vit en localStorage, et Hotjar enregistrerait
// des écrans contenant des données personnelles d'utilisateurs.
import { usePathname } from "next/navigation";

export default function TrackingGate({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  if (pathname?.startsWith("/admin")) {
    return null;
  }
  return <>{children}</>;
}
