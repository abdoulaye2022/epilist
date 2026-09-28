"use client";

// Versions de l'app mobile : une carte par plateforme, sauvegarde
// explicite par plateforme (aucune sauvegarde automatique).
// version_courante = publiée sur le magasin ; version_minimum = en
// dessous, mise à jour obligatoire ; force_update = toute mise à jour
// devient obligatoire. L'API refuse minimum > publiée (blocage sans
// issue).
import { useEffect, useState } from "react";
import { Apple, Play, RotateCcw } from "lucide-react";
import { adminApi } from "@/lib/admin-api";
import AdminLoading from "@/components/admin/AdminLoading";

interface VersionConfig {
  platform: "ios" | "android";
  current_version: string | null;
  minimum_version: string | null;
  message_fr: string | null;
  message_en: string | null;
  store_url: string | null;
  force_update: boolean;
  active: boolean;
  stats_updated: number;
  stats_dismissed: number;
}

export default function AdminAppVersionsPage() {
  const [configs, setConfigs] = useState<VersionConfig[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = () => {
    adminApi
      .get<{ data: { versions: VersionConfig[] } }>("/admin/app-versions")
      .then((res) => setConfigs(res.data.versions))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  return (
    <div>
      <h1 className="mb-2 text-2xl font-bold text-gray-900">
        Versions de l&apos;app mobile
      </h1>
      <p className="mb-6 max-w-2xl text-sm text-gray-500">
        L&apos;app demande au serveur ce qu&apos;il pense de sa version.
        Renseignez la version publiée puis activez : tout se pilote ici, sans
        redéploiement.
      </p>

      {error && <p className="mb-4 text-sm text-red-600">{error}</p>}

      {loading && configs.length === 0 && !error ? (
        <AdminLoading label="Chargement des versions…" />
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          {configs.map((config) => (
            <PlatformCard key={config.platform} initial={config} onSaved={load} />
          ))}
        </div>
      )}
    </div>
  );
}

function PlatformCard({
  initial,
  onSaved,
}: {
  initial: VersionConfig;
  onSaved: () => void;
}) {
  const [form, setForm] = useState(initial);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const Icon = initial.platform === "ios" ? Apple : Play;

  const set = (changes: Partial<VersionConfig>) =>
    setForm((f) => ({ ...f, ...changes }));

  const save = async () => {
    setSaving(true);
    setMessage(null);
    setError(null);
    try {
      await adminApi.put(`/admin/app-versions/${form.platform}`, {
        current_version: form.current_version ?? "",
        minimum_version: form.minimum_version ?? "",
        message_fr: form.message_fr ?? "",
        message_en: form.message_en ?? "",
        store_url: form.store_url ?? "",
        force_update: form.force_update,
        active: form.active,
      });
      setMessage("Enregistré.");
      onSaved();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erreur");
    } finally {
      setSaving(false);
    }
  };

  const resetStats = async () => {
    if (!confirm("Remettre les compteurs à zéro ?")) return;
    await adminApi.post(`/admin/app-versions/${form.platform}/reset-stats`);
    set({ stats_updated: 0, stats_dismissed: 0 });
    onSaved();
  };

  const input =
    "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-green-500 focus:outline-none";
  const label = "mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500";

  return (
    <div className="rounded-2xl border border-gray-200 bg-white p-6">
      <div className="mb-5 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <Icon className="h-5 w-5 text-gray-700" />
          <h2 className="text-lg font-bold capitalize text-gray-900">
            {form.platform}
          </h2>
          <span
            className={`rounded-full px-2 py-0.5 text-xs font-medium ${
              form.active
                ? "bg-green-50 text-green-700"
                : "bg-gray-100 text-gray-500"
            }`}
          >
            {form.active ? "Actif" : "Inactif"}
          </span>
        </div>
        <label className="flex cursor-pointer items-center gap-2 text-sm text-gray-600">
          <input
            type="checkbox"
            checked={form.active}
            onChange={(e) => set({ active: e.target.checked })}
            className="h-4 w-4 accent-green-600"
          />
          Activé
        </label>
      </div>

      <div className="mb-4 grid grid-cols-2 gap-4">
        <div>
          <label className={label}>Version publiée</label>
          <input
            className={input}
            placeholder="2.2.0"
            value={form.current_version ?? ""}
            onChange={(e) => set({ current_version: e.target.value })}
          />
          <p className="mt-1 text-[11px] text-gray-400">
            Publiée sur le magasin
          </p>
        </div>
        <div>
          <label className={label}>Version minimum</label>
          <input
            className={input}
            placeholder="2.0.0"
            value={form.minimum_version ?? ""}
            onChange={(e) => set({ minimum_version: e.target.value })}
          />
          <p className="mt-1 text-[11px] text-gray-400">
            En dessous = mise à jour obligatoire
          </p>
        </div>
      </div>

      <div className="mb-4">
        <label className={label}>Message (français)</label>
        <textarea
          className={input}
          rows={2}
          value={form.message_fr ?? ""}
          onChange={(e) => set({ message_fr: e.target.value })}
        />
      </div>
      <div className="mb-4">
        <label className={label}>Message (anglais)</label>
        <textarea
          className={input}
          rows={2}
          value={form.message_en ?? ""}
          onChange={(e) => set({ message_en: e.target.value })}
        />
      </div>
      <div className="mb-4">
        <label className={label}>URL du magasin</label>
        <input
          className={input}
          value={form.store_url ?? ""}
          onChange={(e) => set({ store_url: e.target.value })}
        />
        <p className="mt-1 text-[11px] text-gray-400">
          Servie à l&apos;app par le serveur : corrigeable sans republier.
        </p>
      </div>

      <label className="mb-5 flex cursor-pointer items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={form.force_update}
          onChange={(e) => set({ force_update: e.target.checked })}
          className="h-4 w-4 accent-green-600"
        />
        Forcer la mise à jour (toute version en retard est bloquée)
      </label>

      <div className="flex items-center justify-between border-t border-gray-100 pt-4">
        <div className="text-xs text-gray-500">
          {form.stats_updated} mises à jour · {form.stats_dismissed} reportées
          <button
            onClick={resetStats}
            className="ml-2 inline-flex items-center gap-1 text-gray-400 hover:text-gray-600"
            title="Remettre à zéro"
          >
            <RotateCcw className="h-3 w-3" /> reset
          </button>
        </div>
        <button
          onClick={save}
          disabled={saving}
          className="rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60"
        >
          {saving ? "Enregistrement…" : "Enregistrer"}
        </button>
      </div>
      {message && <p className="mt-2 text-xs text-green-600">{message}</p>}
      {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}
