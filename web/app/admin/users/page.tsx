"use client";

// Gestion des utilisateurs : recherche, pagination, activer/désactiver,
// promotion admin.
import { useCallback, useEffect, useState } from "react";
import { Search, ShieldCheck } from "lucide-react";
import { adminApi } from "@/lib/admin-api";
import AdminLoading from "@/components/admin/AdminLoading";

interface AdminUser {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: string;
  is_active: boolean;
  email_verified: boolean;
  sso_provider: string | null;
  language: string | null;
  created_at: string | null;
  lists_count: number;
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const perPage = 25;

  const load = useCallback(() => {
    setLoading(true);
    adminApi
      .get<{ data: { users: AdminUser[]; total: number } }>(
        `/admin/users?search=${encodeURIComponent(search)}&page=${page}&per_page=${perPage}`
      )
      .then((res) => {
        setUsers(res.data.users);
        setTotal(res.data.total);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [search, page]);

  useEffect(() => {
    const timer = setTimeout(load, 250); // debounce de la recherche
    return () => clearTimeout(timer);
  }, [load]);

  const updateUser = async (
    user: AdminUser,
    changes: { is_active?: boolean; role?: string }
  ) => {
    try {
      await adminApi.put(`/admin/users/${user.id}`, changes);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Erreur");
    }
  };

  const pages = Math.max(1, Math.ceil(total / perPage));

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-gray-900">
        Utilisateurs <span className="text-base font-normal text-gray-500">({total})</span>
      </h1>

      <div className="relative mb-4 max-w-sm">
        <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
        <input
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          placeholder="Rechercher (nom, email)…"
          className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-3 text-sm focus:border-green-500 focus:outline-none"
        />
      </div>

      {error && <p className="mb-4 text-sm text-red-600">{error}</p>}

      {loading && users.length === 0 && !error ? (
        <AdminLoading label="Chargement des utilisateurs…" />
      ) : (
      <div className="overflow-x-auto rounded-2xl border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
              <th className="px-4 py-3">Utilisateur</th>
              <th className="px-4 py-3">Rôle</th>
              <th className="px-4 py-3">Listes</th>
              <th className="px-4 py-3">Inscrit le</th>
              <th className="px-4 py-3">Statut</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b border-gray-100 last:border-0">
                <td className="px-4 py-3">
                  <div className="font-medium text-gray-900">
                    {`${user.first_name} ${user.last_name}`.trim() || "—"}
                    {user.role === "admin" && (
                      <ShieldCheck className="ml-1 inline h-4 w-4 text-green-600" />
                    )}
                  </div>
                  <div className="text-xs text-gray-500">
                    {user.email}
                    {user.sso_provider ? ` · ${user.sso_provider}` : ""}
                    {user.language ? ` · ${user.language}` : ""}
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-700">{user.role}</td>
                <td className="px-4 py-3 text-gray-700">{user.lists_count}</td>
                <td className="px-4 py-3 text-gray-500">
                  {user.created_at
                    ? new Date(user.created_at).toLocaleDateString("fr-CA")
                    : "—"}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                      user.is_active
                        ? "bg-green-50 text-green-700"
                        : "bg-red-50 text-red-700"
                    }`}
                  >
                    {user.is_active ? "Actif" : "Désactivé"}
                  </span>
                </td>
                <td className="px-4 py-3 text-right">
                  <button
                    onClick={() =>
                      updateUser(user, { is_active: !user.is_active })
                    }
                    className="mr-2 text-xs font-medium text-gray-600 hover:text-gray-900"
                  >
                    {user.is_active ? "Désactiver" : "Réactiver"}
                  </button>
                  <button
                    onClick={() =>
                      updateUser(user, {
                        role: user.role === "admin" ? "user" : "admin",
                      })
                    }
                    className="text-xs font-medium text-green-700 hover:text-green-900"
                  >
                    {user.role === "admin" ? "Retirer admin" : "Rendre admin"}
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
