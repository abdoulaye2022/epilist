"use client";

// Tableau de bord admin : les chiffres clés en cartes.
import { useEffect, useState } from "react";
import {
  Users,
  UserPlus,
  ListChecks,
  ReceiptText,
  ShoppingBasket,
  AlertTriangle,
} from "lucide-react";
import { adminApi } from "@/lib/admin-api";

interface Overview {
  users_total: number;
  users_active_7d: number;
  users_new_30d: number;
  lists_total: number;
  items_total: number;
  receipts_total: number;
  receipts_scanned: number;
  purchases_30d: number;
  errors_24h: number;
  errors_7d: number;
}

export default function AdminDashboardPage() {
  const [data, setData] = useState<Overview | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    adminApi
      .get<{ data: Overview }>("/admin/overview")
      .then((res) => setData(res.data))
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <p className="text-sm text-red-600">{error}</p>;
  if (!data) return <p className="text-sm text-gray-500">Chargement…</p>;

  const cards = [
    { icon: Users, label: "Utilisateurs", value: data.users_total, sub: `${data.users_active_7d} actifs (7 j)` },
    { icon: UserPlus, label: "Nouveaux (30 j)", value: data.users_new_30d, sub: "inscriptions" },
    { icon: ListChecks, label: "Listes", value: data.lists_total, sub: `${data.items_total} articles` },
    { icon: ReceiptText, label: "Reçus", value: data.receipts_total, sub: `${data.receipts_scanned} scannés` },
    { icon: ShoppingBasket, label: "Achats (30 j)", value: data.purchases_30d, sub: "articles achetés" },
    {
      icon: AlertTriangle,
      label: "Erreurs API",
      value: data.errors_24h,
      sub: `${data.errors_7d} sur 7 jours`,
      alert: data.errors_24h > 0,
    },
  ];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Tableau de bord</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {cards.map((card) => (
          <div
            key={card.label}
            className="rounded-2xl border border-gray-200 bg-white p-5"
          >
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-500">
                {card.label}
              </span>
              <card.icon
                className={`h-5 w-5 ${
                  card.alert ? "text-red-500" : "text-green-600"
                }`}
              />
            </div>
            <div
              className={`mt-2 text-3xl font-bold ${
                card.alert ? "text-red-600" : "text-gray-900"
              }`}
            >
              {card.value}
            </div>
            <div className="mt-1 text-xs text-gray-500">{card.sub}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
