"use client";

// Monitoring : journal des erreurs 500 de l'API, avec purge > 30 jours.
import { useCallback, useEffect, useState } from "react";
import { RefreshCw, Trash2 } from "lucide-react";
import { adminApi } from "@/lib/admin-api";
import AdminLoading from "@/components/admin/AdminLoading";

interface ErrorRow {
  id: number;
  method: string;
  path: string;
  status: number;
  message: string | null;
  user_id: number | null;
  created_at: string;
}

export default function AdminMonitoringPage() {
  const [rows, setRows] = useState<ErrorRow[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const perPage = 50;

  const load = useCallback(() => {
    setLoading(true);
    adminApi
      .get<{ data: { errors: ErrorRow[]; total: number } }>(
        `/admin/errors?page=${page}&per_page=${perPage}`
      )
      .then((res) => {
        setRows(res.data.errors);
        setTotal(res.data.total);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load]);

  const purge = async () => {
    if (!confirm("Purger les erreurs de plus de 30 jours ?")) return;
    await adminApi.del("/admin/errors");
    load();
  };

  const purgeAll = async () => {
    if (!confirm("Supprimer TOUTES les erreurs du journal ?")) return;
    await adminApi.del("/admin/errors?all=1");
    load();
  };

  /// Retire une entrée une fois la correction appliquée.
  const remove = async (id: number) => {
    await adminApi.del(`/admin/errors/${id}`);
    load();
  };

  const pages = Math.max(1, Math.ceil(total / perPage));

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">
          Monitoring{" "}
          <span className="text-base font-normal text-gray-500">
            ({total} erreurs)
          </span>
        </h1>
        <div className="flex gap-2">
          <button
            onClick={load}
            className="flex items-center gap-2 rounded-lg border border-gray-300 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100"
          >
            <RefreshCw className="h-4 w-4" /> Actualiser
          </button>
          <button
            onClick={purge}
            className="flex items-center gap-2 rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50"
          >
            <Trash2 className="h-4 w-4" /> Purger &gt; 30 j
          </button>
          <button
            onClick={purgeAll}
            className="flex items-center gap-2 rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50"
          >
            <Trash2 className="h-4 w-4" /> Tout effacer
          </button>
        </div>
      </div>

      {error && <p className="mb-4 text-sm text-red-600">{error}</p>}

      {loading && rows.length === 0 && !error ? (
        <AdminLoading label="Chargement du journal…" />
      ) : rows.length === 0 ? (
        <div className="rounded-2xl border border-gray-200 bg-white p-10 text-center text-sm text-gray-500">
          Aucune erreur enregistrée. Tout roule.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
                <th className="px-4 py-3">Date</th>
                <th className="px-4 py-3">Requête</th>
                <th className="px-4 py-3">Utilisateur</th>
                <th className="px-4 py-3">Message</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id} className="border-b border-gray-100 align-top last:border-0">
                  <td className="whitespace-nowrap px-4 py-3 text-gray-500">
                    {new Date(row.created_at).toLocaleString("fr-CA")}
                  </td>
                  <td className="whitespace-nowrap px-4 py-3 font-mono text-xs">
                    <span className="rounded bg-red-50 px-1.5 py-0.5 font-semibold text-red-700">
                      {row.status}
                    </span>{" "}
                    {row.method} {row.path}
                  </td>
                  <td className="px-4 py-3 text-gray-500">
                    {row.user_id ?? "—"}
                  </td>
                  <td className="max-w-xl px-4 py-3 text-xs text-gray-700">
                    {row.message}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => remove(row.id)}
                      title="Supprimer (correction appliquée)"
                      className="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {pages > 1 && (
        <div className="mt-4 flex items-center gap-3 text-sm">
          <button
            disabled={page <= 1}
            onClick={() => setPage(page - 1)}
            className="rounded-lg border border-gray-300 px-3 py-1.5 disabled:opacity-40"
          >
            Précédent
          </button>
          <span className="text-gray-600">
            Page {page} / {pages}
          </span>
          <button
            disabled={page >= pages}
            onClick={() => setPage(page + 1)}
            className="rounded-lg border border-gray-300 px-3 py-1.5 disabled:opacity-40"
          >
            Suivant
          </button>
        </div>
      )}
    </div>
  );
}
