<?php
// src/Controllers/AccountDeletionController.php — supprimer son compte
// SANS passer par l'application.
//
// Google Play et l'App Store exigent une procedure accessible depuis une
// URL publique : quelqu'un qui a desinstalle l'application, change de
// telephone ou perdu son mot de passe doit pouvoir faire effacer son
// compte. Le formulaire du site aboutit ici.
//
// Le courriel est la seule preuve d'identite possible a cette porte :
// n'importe qui peut taper n'importe quelle adresse. Donc
//
//   - la reponse au formulaire est TOUJOURS la meme, que l'adresse ait
//     un compte ou non : sinon la page devient un detecteur de comptes ;
//   - rien n'est supprime a ce stade. Une demande n'est qu'une ligne
//     dans account_deletion_requests et un courriel ;
//   - le lien recu porte un jeton aleatoire de 32 octets, valable une
//     heure et une seule fois, et la base n'en garde que l'empreinte.
//
// La suppression elle-meme est faite par le MEME service que dans
// l'application (AccountDeletionService) : un seul chemin, donc une
// seule chose a verifier.

namespace App\Controllers;

use App\Models\User;
use App\Services\AccountDeletionService;
use App\Services\EmailTemplates;
use App\Services\MailSender;
use App\Services\RateLimiter;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AccountDeletionController
{
    /** Un lien de suppression ne doit pas trainer dans une boite. */
    private const VALIDITE_MINUTES = 60;

    private RateLimiter $rateLimiter;

    public function __construct()
    {
        $this->rateLimiter = new RateLimiter();
    }

    /**
     * POST /account-deletion/request — { email, language }
     *
     * Rend toujours 200 avec le meme message.
     */
    public function requestFromWeb(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody() ?? [];
        $email = strtolower(trim((string) ($data['email'] ?? '')));
        $lang = ($data['language'] ?? '') === 'en' ? 'en' : 'fr';
        $ip = $this->clientIp($request);

        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->json($response, 400, [
                'success' => false,
                'code' => 'VALIDATION_ERROR',
                'message' => $lang === 'en'
                    ? 'Please enter a valid email address.'
                    : 'Veuillez saisir une adresse courriel valide.',
            ]);
        }

        if (!$this->rateLimiter->checkIPLimit('account_deletion_web', $ip)
            || !$this->rateLimiter->checkEmailLimit('account_deletion_web', $email)) {
            return $this->json($response, 429, [
                'success' => false,
                'code' => 'RATE_LIMIT_EXCEEDED',
                'message' => $lang === 'en'
                    ? 'Too many requests. Please try again later.'
                    : 'Trop de demandes. Réessayez plus tard.',
                'retry_after' => $this->rateLimiter->getRetryAfter('account_deletion_web', $ip),
            ]);
        }

        $this->rateLimiter->recordAttempt('account_deletion_web', $ip);
        $this->rateLimiter->recordAttempt('account_deletion_web', $email);

        $user = User::where('email', $email)->first();

        if ($user && !$user->estAnonymise() && !$user->estReserve()) {
            // Une seule demande vivante par adresse : la precedente
            // cesse de valoir des qu'une nouvelle est faite.
            DB::table('account_deletion_requests')
                ->where('email', $email)
                ->whereNull('confirmed_at')
                ->delete();

            $jeton = bin2hex(random_bytes(32));

            DB::table('account_deletion_requests')->insert([
                'email' => $email,
                'user_id' => $user->id,
                'token_hash' => hash('sha256', $jeton),
                'language' => $lang,
                'ip_address' => $ip,
                'expires_at' => Carbon::now()->addMinutes(self::VALIDITE_MINUTES),
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]);

            try {
                MailSender::sendMail(
                    EmailTemplates::getSubject('account_deletion_link', $lang),
                    [['email' => $email, 'name' => $user->first_name ?? '']],
                    EmailTemplates::accountDeletionLinkEmail($this->lienDeConfirmation($jeton, $lang), $lang)
                );
            } catch (\Exception $e) {
                error_log('[AccountDeletion] lien non envoyé: ' . $e->getMessage());
            }
        }

        return $this->json($response, 200, [
            'success' => true,
            'message' => $lang === 'en'
                ? 'If an EpiList account exists for this address, a confirmation email has just been sent. The link is valid for one hour.'
                : "Si un compte EpiList existe pour cette adresse, un courriel de confirmation vient d'être envoyé. Le lien est valable une heure.",
        ]);
    }

    /**
     * GET /account-deletion/confirm/{token}
     *
     * Rend du JSON si on le demande (la page du site), du HTML sinon
     * (clic direct depuis le courriel) — meme double regime que le
     * desabonnement.
     */
    public function confirmFromWeb(Request $request, Response $response, array $args): Response
    {
        $jeton = (string) ($args['token'] ?? '');
        $veutJson = str_contains($request->getHeaderLine('Accept'), 'application/json');

        $demande = $jeton === '' ? null : DB::table('account_deletion_requests')
            ->where('token_hash', hash('sha256', $jeton))
            ->first();

        $lang = ($demande->language ?? 'fr') === 'en' ? 'en' : 'fr';

        if (!$demande || $demande->confirmed_at !== null
            || Carbon::parse($demande->expires_at)->lt(Carbon::now())) {
            return $this->rendre($response, $veutJson, 400, $lang, false, $lang === 'en'
                ? 'This link is no longer valid. It may have expired, or already been used. You can request a new one.'
                : "Ce lien n'est plus valable. Il a peut-être expiré, ou déjà servi. Vous pouvez en demander un nouveau.");
        }

        $user = $demande->user_id ? User::find($demande->user_id) : null;

        if (!$user || $user->estAnonymise()) {
            DB::table('account_deletion_requests')->where('id', $demande->id)
                ->update(['confirmed_at' => Carbon::now(), 'updated_at' => Carbon::now()]);

            return $this->rendre($response, $veutJson, 200, $lang, true, $lang === 'en'
                ? 'This account is already deleted.'
                : 'Ce compte est déjà supprimé.');
        }

        $courriel = $user->email;
        $prenom = $user->first_name ?? '';

        try {
            (new AccountDeletionService())->supprimer($user, 'web');
        } catch (\Throwable $e) {
            error_log('[AccountDeletion] échec web: ' . $e->getMessage());

            return $this->rendre($response, $veutJson, 500, $lang, false, $lang === 'en'
                ? 'The deletion could not be completed. Please write to us and we will do it by hand.'
                : "La suppression n'a pas pu aboutir. Écrivez-nous et nous la ferons à la main.");
        }

        DB::table('account_deletion_requests')->where('id', $demande->id)
            ->update(['confirmed_at' => Carbon::now(), 'updated_at' => Carbon::now()]);

        try {
            MailSender::sendMail(
                EmailTemplates::getSubject('account_deletion_done', $lang),
                [['email' => $courriel, 'name' => $prenom]],
                EmailTemplates::accountDeletionDoneEmail($prenom, $lang)
            );
        } catch (\Exception $e) {
            error_log('[AccountDeletion] accusé non envoyé: ' . $e->getMessage());
        }

        return $this->rendre($response, $veutJson, 200, $lang, true, $lang === 'en'
            ? 'Your account is deleted. Your personal data has been erased, and the lists you shared were handed over to the people you shared them with.'
            : 'Votre compte est supprimé. Vos données personnelles ont été effacées, et les listes que vous partagiez ont été transmises aux personnes avec qui vous les partagiez.');
    }

    // ===================== OUTILS =====================

    /**
     * Le lien part vers le SITE, qui appelle ensuite cette API — meme
     * chemin que le desabonnement. Une adresse d'API dans un courriel
     * n'inspire rien a personne.
     */
    private function lienDeConfirmation(string $jeton, string $lang): string
    {
        $base = $_ENV['FRONTEND_URL'] ?? null;

        if (!$base) {
            $base = ($_ENV['APP_ENV'] ?? 'prod') === 'dev'
                ? 'http://localhost:3001'
                : 'https://epilist.app';
        }

        $chemin = $lang === 'en' ? '/en/delete-account/confirm/' : '/suppression-compte/confirmer/';

        return rtrim($base, '/') . $chemin . $jeton;
    }

    /** L'adresse de l'appelant, par le service qui sait a quel mandataire se fier. */
    private function clientIp(Request $request): string
    {
        return \App\Services\ClientIp::depuis($request);
    }

    private function json(Response $response, int $statut, array $corps): Response
    {
        $response->getBody()->write(json_encode($corps, JSON_UNESCAPED_UNICODE));

        return $response->withHeader('Content-Type', 'application/json')->withStatus($statut);
    }

    private function rendre(
        Response $response,
        bool $veutJson,
        int $statut,
        string $lang,
        bool $succes,
        string $message
    ): Response {
        if ($veutJson) {
            return $this->json($response, $statut, [
                'success' => $succes,
                'message' => $message,
            ]);
        }

        $response->getBody()->write($this->page($lang, $succes, $message));

        return $response->withHeader('Content-Type', 'text/html; charset=utf-8')->withStatus($statut);
    }

    /** Page autonome : elle doit s'afficher meme si le site est en panne. */
    private function page(string $lang, bool $succes, string $message): string
    {
        $titre = $succes
            ? ($lang === 'en' ? 'Account deleted' : 'Compte supprimé')
            : ($lang === 'en' ? 'Link no longer valid' : 'Lien plus valable');

        $couleur = $succes ? '#047857' : '#b91c1c';
        $retour = $lang === 'en' ? 'Back to epilist.app' : 'Retour à epilist.app';
        $titreSur = htmlspecialchars($titre, ENT_QUOTES, 'UTF-8');
        $messageSur = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');

        return <<<HTML
<!doctype html>
<html lang="{$lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>{$titreSur} — EpiList</title>
<style>
  body { margin:0; background:#f8faf9; color:#1f2937;
         font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
         display:flex; align-items:center; justify-content:center; min-height:100vh; padding:24px; }
  .carte { background:#fff; border:1px solid #e5e7eb; border-radius:16px; padding:32px;
           max-width:520px; box-shadow:0 1px 3px rgba(0,0,0,.06); }
  h1 { margin:0 0 16px; font-size:22px; color:{$couleur}; }
  p { margin:0 0 20px; font-size:16px; line-height:1.6; color:#374151; }
  a { color:#047857; font-weight:600; text-decoration:none; }
</style>
</head>
<body>
  <div class="carte">
    <h1>{$titreSur}</h1>
    <p>{$messageSur}</p>
    <p><a href="https://epilist.app">{$retour}</a></p>
  </div>
</body>
</html>
HTML;
    }
}
