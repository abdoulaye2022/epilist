"use client";

// Coquille de l'espace admin : garde d'authentification (jeton +
// rôle admin), barre latérale sombre, contenu à droite.
import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  BarChart3,
  Activity,
  Smartphone,
  LogOut,
} from "lucide-react";
import { getAdminToken, setAdminToken } from "@/lib/admin-api";

const NAV = [
  { href: "/admin", label: "Tableau de bord", icon: LayoutDashboard },
  { href: "/admin/users", label: "Utilisateurs", icon: Users },
  { href: "/admin/stats", label: "Statistiques", icon: BarChart3 },
  { href: "/admin/monitoring", label: "Monitoring", icon: Activity },
  { href: "/admin/app-versions", label: "Versions de l'app", icon: Smartphone },
];

export default function AdminShell({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const isLogin = pathname === "/admin/login";

  useEffect(() => {
    if (isLogin) {
      setReady(true);
      return;
    }
    if (!getAdminToken()) {
      router.replace("/admin/login");
      return;
    }
    setReady(true);
  }, [isLogin, pathname, router]);

  if (isLogin) return <>{children}</>;
  if (!ready) return null;

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* Barre latérale */}
      <aside className="flex w-60 flex-col bg-gray-900 text-white">
        <div className="flex items-center gap-2.5 px-5 py-5 border-b border-white/10">
          <div className="relative h-7 w-7">
            <Image src="/app_logo.png" alt="" fill className="object-contain" sizes="28px" />
          </div>
          <div>
            <div className="text-sm font-bold leading-none">EpiList</div>
            <div className="text-[11px] text-gray-400">Administration</div>
          </div>
        </div>
        <nav className="flex-1 space-y-1 p-3">
          {NAV.map((item) => {
            const active =
              item.href === "/admin"
                ? pathname === "/admin"
                : pathname?.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                  active
                    ? "bg-green-600 text-white"
                    : "text-gray-300 hover:bg-white/10 hover:text-white"
                }`}
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <button
          onClick={() => {
            setAdminToken(null);
            router.replace("/admin/login");
          }}
          className="m-3 flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-red-300 transition-colors hover:bg-red-500/10"
        >
          <LogOut className="h-4 w-4" />
          Déconnexion
        </button>
      </aside>

      {/* Contenu */}
      <main className="flex-1 overflow-x-auto p-8">{children}</main>
    </div>
  );
}
