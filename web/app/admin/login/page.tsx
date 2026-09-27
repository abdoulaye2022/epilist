"use client";

// Connexion admin en deux étapes : email + mot de passe, puis code à
// 6 chiffres reçu par email (2FA).
import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { adminApi } from "@/lib/admin-api";

export default function AdminLoginPage() {
  const router = useRouter();
  const [step, setStep] = useState<"credentials" | "otp">("credentials");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submitCredentials = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await adminApi.requestOtp(email.trim(), password);
      setStep("otp");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Connexion refusée");
    } finally {
      setLoading(false);
    }
  };

  const submitCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await adminApi.verifyOtp(email.trim(), code.trim());
      router.replace("/admin");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Code invalide");
    } finally {
      setLoading(false);
    }
  };

  const inputClass =
    "mb-4 w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-green-500 focus:outline-none";

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <form
        onSubmit={step === "credentials" ? submitCredentials : submitCode}
        className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 shadow-sm"
      >
        <div className="mb-6 flex flex-col items-center gap-2">
          <div className="relative h-12 w-12">
            <Image src="/app_logo.png" alt="EpiList" fill className="object-contain" sizes="48px" />
          </div>
          <h1 className="text-lg font-bold text-gray-900">Administration</h1>
          <p className="text-sm text-gray-500">
            {step === "credentials"
              ? "Accès réservé"
              : `Code envoyé à ${email}`}
          </p>
        </div>

        {step === "credentials" ? (
          <>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={inputClass}
            />
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Mot de passe
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={inputClass}
            />
          </>
        ) : (
          <>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Code à 6 chiffres
            </label>
            <input
              inputMode="numeric"
              pattern="[0-9]{6}"
              maxLength={6}
              required
              autoFocus
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
              className={`${inputClass} text-center text-xl tracking-[0.4em]`}
              placeholder="••••••"
            />
            <p className="mb-4 text-xs text-gray-400">
              Le code expire dans 10 minutes.
            </p>
          </>
        )}

        {error && <p className="mb-4 text-sm text-red-600">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-green-600 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-green-700 disabled:opacity-60"
        >
          {loading
            ? "Un instant…"
            : step === "credentials"
              ? "Recevoir le code"
              : "Se connecter"}
        </button>

        {step === "otp" && (
          <button
            type="button"
            onClick={() => {
              setStep("credentials");
              setCode("");
              setError(null);
            }}
            className="mt-3 w-full text-center text-xs text-gray-500 hover:text-gray-700"
          >
            Revenir en arrière
          </button>
        )}
      </form>
    </div>
  );
}
