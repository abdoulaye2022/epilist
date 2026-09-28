"use client";

// Statistiques : séries mensuelles (12 mois) + top produits.
import { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  CartesianGrid,
} from "recharts";
import { adminApi } from "@/lib/admin-api";
import AdminLoading from "@/components/admin/AdminLoading";

interface MonthRow {
  month: string;
  signups: number;
  purchases: number;
  receipts: number;
  lists: number;
}
interface TopProduct {
  normalized_name: string;
  product_name: string;
  purchases: number;
}
interface CurrencyRow {
  code: string;
  users: number;
}
interface LanguageRow {
  language: string;
  users: number;
}

// Le pays n'est pas stocké : la devise choisie en tient lieu.
const CURRENCY_COUNTRY: Record<string, string> = {
  CAD: "Canada",
  USD: "États-Unis",
  EUR: "Zone euro",
  GBP: "Royaume-Uni",
  XOF: "Afrique de l'Ouest (CFA)",
  XAF: "Afrique centrale (CFA)",
  MAD: "Maroc",
  DZD: "Algérie",
  TND: "Tunisie",
  CHF: "Suisse",
  AUD: "Australie",
  NGN: "Nigéria",
  KES: "Kenya",
};
const LANGUAGE_LABEL: Record<string, string> = {
  fr: "Français",
  en: "Anglais",
};

export default function AdminStatsPage() {
  const [monthly, setMonthly] = useState<MonthRow[]>([]);
  const [top, setTop] = useState<TopProduct[]>([]);
  const [byCurrency, setByCurrency] = useState<CurrencyRow[]>([]);
  const [byLanguage, setByLanguage] = useState<LanguageRow[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi
      .get<{
        data: {
          monthly: MonthRow[];
          top_products: TopProduct[];
          communities: {
            by_currency: CurrencyRow[];
            by_language: LanguageRow[];
          };
        };
      }>("/admin/stats")
      .then((res) => {
        setMonthly(res.data.monthly);
        setTop(res.data.top_products);
        setByCurrency(res.data.communities?.by_currency ?? []);
        setByLanguage(res.data.communities?.by_language ?? []);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const totalUsers = byCurrency.reduce((s, r) => s + r.users, 0);

  if (error) return <p className="text-sm text-red-600">{error}</p>;
  if (loading) return <AdminLoading label="Chargement des statistiques…" />;

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">Statistiques</h1>

      <div className="mb-6 rounded-2xl border border-gray-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-gray-700">
          Activité des 12 derniers mois
        </h2>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthly}>
              <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
              <XAxis dataKey="month" fontSize={11} />
              <YAxis fontSize={11} allowDecimals={false} />
              <Tooltip />
              <Legend />
              <Bar dataKey="signups" name="Inscriptions" fill="#43A047" radius={[3, 3, 0, 0]} />
              <Bar dataKey="lists" name="Listes" fill="#2E7D32" radius={[3, 3, 0, 0]} />
              <Bar dataKey="purchases" name="Achats" fill="#81c784" radius={[3, 3, 0, 0]} />
              <Bar dataKey="receipts" name="Reçus" fill="#b0bec5" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Communautés : pays (via la devise choisie) et langue */}
      <div className="mb-6 grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-gray-200 bg-white p-5">
          <h2 className="mb-1 text-sm font-semibold text-gray-700">
            Communautés par pays
          </h2>
          <p className="mb-4 text-xs text-gray-400">
            D&apos;après la devise choisie par chaque utilisateur.
          </p>
          {byCurrency.length === 0 ? (
            <p className="text-sm text-gray-500">Aucune donnée.</p>
          ) : (
            <div className="space-y-3">
              {byCurrency.map((row) => {
                const pct = totalUsers ? (row.users / totalUsers) * 100 : 0;
                return (
                  <div key={row.code}>
                    <div className="mb-1 flex items-center justify-between text-sm">
                      <span className="font-medium text-gray-900">
                        {CURRENCY_COUNTRY[row.code] ?? row.code}
                        <span className="ml-1.5 text-xs text-gray-400">
                          {row.code}
                        </span>
                      </span>
                      <span className="text-gray-600">
                        {row.users} · {pct.toFixed(0)} %
                      </span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-gray-100">
                      <div
                        className="h-full rounded-full bg-green-600"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="rounded-2xl border border-gray-200 bg-white p-5">
          <h2 className="mb-1 text-sm font-semibold text-gray-700">
            Communautés par langue
          </h2>
          <p className="mb-4 text-xs text-gray-400">
            Langue de l&apos;application choisie par l&apos;utilisateur.
          </p>
          <div className="space-y-3">
            {byLanguage.map((row) => {
              const pct = totalUsers ? (row.users / totalUsers) * 100 : 0;
              return (
                <div key={row.language}>
                  <div className="mb-1 flex items-center justify-between text-sm">
                    <span className="font-medium text-gray-900">
                      {LANGUAGE_LABEL[row.language] ?? row.language}
                    </span>
                    <span className="text-gray-600">
                      {row.users} · {pct.toFixed(0)} %
                    </span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-gray-100">
                    <div
                      className="h-full rounded-full bg-green-700"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div className="rounded-2xl border border-gray-200 bg-white p-5">
        <h2 className="mb-4 text-sm font-semibold text-gray-700">
          Top produits (90 derniers jours)
        </h2>
        {top.length === 0 ? (
          <p className="text-sm text-gray-500">Aucune donnée.</p>
        ) : (
          <table className="w-full text-sm">
            <tbody>
              {top.map((product, i) => (
                <tr
                  key={product.normalized_name}
                  className="border-b border-gray-100 last:border-0"
                >
                  <td className="w-8 py-2 text-gray-400">{i + 1}.</td>
                  <td className="py-2 font-medium text-gray-900">
                    {product.product_name}
                  </td>
                  <td className="py-2 text-right text-gray-600">
                    {product.purchases} achats
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
