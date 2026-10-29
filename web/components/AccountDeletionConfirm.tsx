"use client";

// La page d'arrivée du lien reçu par courriel.
//
// Le jeton est dans l'URL ; cette page appelle l'API, qui vérifie son
// empreinte, son échéance et son usage unique, puis supprime le compte
// par le même service que l'application. Rien n'est décidé ici.
//
// Un seul appel, et une seule fois : un double rendu React ne doit pas
// aboutir à deux tentatives (la seconde échouerait, le jeton étant déjà
// consommé, et afficherait « lien plus valable » sur une suppression
// réussie).
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useLanguage } from "@/hooks/useLanguage";
import { href } from "@/lib/routes";
import { Card, CardContent } from "@/components/ui/card";
import { AlertTriangle, CheckCircle, Loader2 } from "lucide-react";

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "https://m2atodev.com/api.epilist/public";

export default function AccountDeletionConfirm({ token }: { token: string }) {
  const { t, language } = useLanguage();
  const [etat, setEtat] = useState<"attente" | "ok" | "erreur">("attente");
  const [message, setMessage] = useState<string | null>(null);
  const dejaAppele = useRef(false);

  useEffect(() => {
    if (dejaAppele.current || !token) return;
    dejaAppele.current = true;

    (async () => {
      try {
        const res = await fetch(
          `${API_URL}/account-deletion/confirm/${encodeURIComponent(token)}`,
          { headers: { Accept: "application/json" } }
        );
        const data = await res.json().catch(() => null);

        if (res.ok && data?.success) {
          setMessage(data.message ?? null);
          setEtat("ok");
          return;
        }

        setMessage(data?.message ?? null);
        setEtat("erreur");
      } catch {
        setMessage(null);
        setEtat("erreur");
      }
    })();
  }, [token]);

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-16">
      <Card className="w-full max-w-lg border-gray-200">
        <CardContent className="p-8">
          {etat === "attente" && (
            <div className="flex items-center gap-3 text-gray-700">
              <Loader2 className="h-5 w-5 animate-spin text-green-600" />
              <p>{t("delConfirmChecking")}</p>
            </div>
          )}

          {etat !== "attente" && (
            <div className="flex items-start gap-3">
              {etat === "ok" ? (
                <CheckCircle className="mt-0.5 h-6 w-6 shrink-0 text-green-600" />
              ) : (
                <AlertTriangle className="mt-0.5 h-6 w-6 shrink-0 text-red-600" />
              )}
              <div>
                <h1
                  className={`text-xl font-bold ${
                    etat === "ok" ? "text-green-800" : "text-red-800"
                  }`}
                >
                  {etat === "ok"
                    ? t("delConfirmOkTitle")
                    : t("delConfirmErrorTitle")}
                </h1>
                {message && (
                  <p className="mt-2 text-sm leading-relaxed text-gray-700">
                    {message}
                  </p>
                )}
                <div className="mt-6 flex flex-wrap gap-4 text-sm font-semibold">
                  <Link
                    href={href("home", language)}
                    className="text-green-700 hover:underline"
                  >
                    {t("delBackHome")}
                  </Link>
                  {etat === "erreur" && (
                    <Link
                      href={href("accountDeletion", language)}
                      className="text-gray-600 hover:underline"
                    >
                      {t("delTitle")}
                    </Link>
                  )}
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </main>
  );
}
