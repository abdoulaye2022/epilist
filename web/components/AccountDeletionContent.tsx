"use client";

// Demander la suppression de son compte SANS l'application.
//
// Google Play et l'App Store l'exigent : quelqu'un qui a désinstallé
// l'application, changé de téléphone ou perdu son mot de passe doit
// pouvoir faire effacer son compte. Cette page est cette porte.
//
// Elle ne supprime rien. Elle envoie un courriel contenant un lien à
// jeton, valable une heure et une seule fois — le courriel est la seule
// preuve d'identité possible ici, puisque n'importe qui peut taper
// n'importe quelle adresse.
//
// Et la réponse est TOUJOURS la même, que l'adresse ait un compte ou
// non : sinon la page deviendrait un détecteur de comptes EpiList.
import { useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  AlertTriangle,
  ArrowLeft,
  CheckCircle,
  Clock,
  Mail,
  Send,
  Users,
} from "lucide-react";

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "https://m2atodev.com/api.epilist/public";

export default function AccountDeletionContent() {
  const { t, language } = useLanguage();
  const [email, setEmail] = useState("");
  const [envoi, setEnvoi] = useState(false);
  const [envoye, setEnvoye] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [erreur, setErreur] = useState<string | null>(null);

  const soumettre = async (e: React.FormEvent) => {
    e.preventDefault();
    setErreur(null);

    // Même règle que l'API, pour un message clair avant tout appel.
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setErreur(t("delInvalidEmail"));
      return;
    }

    setEnvoi(true);
    try {
      const res = await fetch(`${API_URL}/account-deletion/request`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email: email.trim(), language }),
      });

      const data = await res.json().catch(() => null);

      if (!res.ok || data?.success === false) {
        throw new Error(data?.message ?? `Erreur ${res.status}`);
      }

      setMessage(data?.message ?? null);
      setEnvoye(true);
    } catch (err) {
      const detail = err instanceof Error ? err.message : null;
      setErreur(detail && !detail.startsWith("Erreur ") ? detail : t("delFailed"));
    } finally {
      setEnvoi(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50 py-14">
      <div className="container mx-auto max-w-3xl px-4">
        <Link
          href={href("home", language)}
          className="mb-8 inline-flex items-center gap-2 text-sm text-gray-600 transition-colors hover:text-green-700"
        >
          <ArrowLeft className="h-4 w-4" />
          {t("delBackHome")}
        </Link>

        <h1 className="text-3xl font-bold text-gray-900 sm:text-4xl">
          {t("delTitle")}
        </h1>
        <p className="mt-4 text-base leading-relaxed text-gray-700">
          {t("delIntro")}
        </p>

        {/* Le formulaire, ou l'accusé de réception à sa place. */}
        <Card className="mt-8 border-gray-200">
          <CardContent className="p-6">
            {envoye ? (
              <div className="flex items-start gap-3">
                <CheckCircle className="mt-0.5 h-6 w-6 shrink-0 text-green-600" />
                <div>
                  <p className="font-semibold text-gray-900">
                    {t("delSentTitle")}
                  </p>
                  <p className="mt-1 text-sm leading-relaxed text-gray-700">
                    {message}
                  </p>
                </div>
              </div>
            ) : (
              <form onSubmit={soumettre} noValidate>
                <label
                  htmlFor="email"
                  className="block text-sm font-medium text-gray-900"
                >
                  {t("delEmailLabel")}
                </label>
                <div className="mt-2 flex flex-col gap-3 sm:flex-row">
                  <div className="relative flex-1">
                    <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                    <input
                      id="email"
                      name="email"
                      type="email"
                      autoComplete="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder={t("delEmailPlaceholder")}
                      className="w-full rounded-lg border border-gray-300 py-2.5 pl-9 pr-3 text-base text-gray-900 outline-none focus:border-green-600 focus:ring-2 focus:ring-green-600/20"
                    />
                  </div>
                  <Button
                    type="submit"
                    disabled={envoi}
                    className="bg-red-600 text-white hover:bg-red-700 sm:w-auto"
                  >
                    <Send className="mr-2 h-4 w-4" />
                    {envoi ? t("delSending") : t("delSubmit")}
                  </Button>
                </div>
                {erreur && (
                  <p className="mt-3 text-sm font-medium text-red-700">{erreur}</p>
                )}
              </form>
            )}
          </CardContent>
        </Card>

        {/* Ce qui part, ce qui reste, et quand : dit avant le clic. */}
        <div className="mt-8 grid gap-4 sm:grid-cols-2">
          <Card className="border-red-200 bg-red-50/60">
            <CardContent className="p-6">
              <h2 className="flex items-center gap-2 font-semibold text-red-800">
                <AlertTriangle className="h-5 w-5" />
                {t("delWhatTitle")}
              </h2>
              <ul className="mt-3 space-y-2 text-sm leading-relaxed text-red-900/90">
                <li>{t("delWhat1")}</li>
                <li>{t("delWhat2")}</li>
                <li>{t("delWhat3")}</li>
                <li>{t("delWhat4")}</li>
              </ul>
            </CardContent>
          </Card>

          <Card className="border-green-200 bg-green-50/60">
            <CardContent className="p-6">
              <h2 className="flex items-center gap-2 font-semibold text-green-800">
                <Users className="h-5 w-5" />
                {t("delKeptTitle")}
              </h2>
              <ul className="mt-3 space-y-2 text-sm leading-relaxed text-green-900/90">
                <li>{t("delKept1")}</li>
                <li>{t("delKept2")}</li>
              </ul>
            </CardContent>
          </Card>
        </div>

        <Card className="mt-4 border-gray-200">
          <CardContent className="p-6">
            <h2 className="flex items-center gap-2 font-semibold text-gray-900">
              <Clock className="h-5 w-5 text-gray-500" />
              {t("delDelayTitle")}
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-gray-700">
              {t("delDelayText")}
            </p>
          </CardContent>
        </Card>

        <p className="mt-8 text-sm text-gray-600">
          {t("delHelpText")}{" "}
          <Link
            href={href("contact", language)}
            className="font-semibold text-green-700 hover:underline"
          >
            {t("contact")}
          </Link>
        </p>
      </div>
    </main>
  );
}
