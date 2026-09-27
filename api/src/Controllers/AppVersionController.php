<?php
// src/Controllers/AppVersionController.php
//
// Versions de l'app mobile : l'app demande au serveur ce qu'il pense de
// sa propre version, le serveur répond par deux booléens.
//  - update_available : une fenêtre s'ouvre, avec « Plus tard » ;
//  - update_required  : la même fenêtre, sans échappatoire.
// Deux façons de bloquer, cumulables : minimum_version (seuil durable)
// et force_update (interrupteur : toute mise à jour devient obligatoire).
// Les URL des magasins sont servies ici (corrigeables sans republier).
//
// Publics (AVANT l'authentification : une app bloquée doit pouvoir
// apprendre qu'elle est périmée même si la connexion ne passe plus) :
//   GET  /app/version-check?platform=ios&version=1.0.0
//   POST /app/version-stat { platform, action: updated|dismissed }
// Admin (JwtMiddleware + AdminMiddleware) :
//   GET  /admin/app-versions
//   PUT  /admin/app-versions/{platform}
//   POST /admin/app-versions/{platform}/reset-stats

namespace App\Controllers;

use App\Models\AppVersion;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AppVersionController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** GET /app/version-check — public. */
    public function check(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $platform = $params['platform'] ?? '';
        $version = trim((string) ($params['version'] ?? ''));

        $silence = [
            'update_available' => false,
            'update_required' => false,
        ];
        if (!in_array($platform, ['ios', 'android'], true) || $version === '') {
            return $this->json($response, $silence);
        }

        $config = AppVersion::where('platform', $platform)->first();

        // Trois raisons de ne rien dire : pas de ligne, inactive, pas de
        // version publiée renseignée.
        if (!$config || !$config->active || !$config->current_version) {
            return $this->json($response, $silence);
        }

        // version_compare, jamais une comparaison de chaînes :
        // '1.1.9' < '1.1.10' doit être vrai.
        $updateAvailable = version_compare($version, $config->current_version, '<');
        $belowMinimum = $config->minimum_version
            ? version_compare($version, $config->minimum_version, '<')
            : false;

        return $this->json($response, [
            'update_available' => $updateAvailable,
            'update_required' => $belowMinimum || ($updateAvailable && (bool) $config->force_update),
            'current_version' => $config->current_version,
            'message_fr' => $config->message_fr,
            'message_en' => $config->message_en,
            'store_url' => $config->store_url,
        ]);
    }

    /** POST /app/version-stat — public, purement indicatif. */
    public function stat(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody() ?? [];
        $platform = $data['platform'] ?? '';
        $action = $data['action'] ?? '';

        if (in_array($platform, ['ios', 'android'], true) &&
            in_array($action, ['updated', 'dismissed'], true)) {
            AppVersion::where('platform', $platform)
                ->increment($action === 'updated' ? 'stats_updated' : 'stats_dismissed');
        }
        // Toujours 200 : ces compteurs ne pilotent rien.
        return $this->json($response, ['success' => true]);
    }

    // --- Admin ---------------------------------------------------------

    /** GET /admin/app-versions */
    public function index(Request $request, Response $response): Response
    {
        return $this->json($response, [
            'success' => true,
            'data' => ['versions' => AppVersion::orderBy('platform')->get()],
        ]);
    }

    /** PUT /admin/app-versions/{platform} */
    public function update(Request $request, Response $response, array $args): Response
    {
        $platform = $args['platform'] ?? '';
        $config = AppVersion::where('platform', $platform)->first();
        if (!$config) {
            return $this->json($response, ['success' => false, 'message' => 'Plateforme inconnue'], 404);
        }

        $data = $request->getParsedBody() ?? [];
        $current = array_key_exists('current_version', $data)
            ? (trim((string) $data['current_version']) ?: null)
            : $config->current_version;
        $minimum = array_key_exists('minimum_version', $data)
            ? (trim((string) $data['minimum_version']) ?: null)
            : $config->minimum_version;

        // Garde-fou : minimum_version > current_version bloquerait tout le
        // monde sans issue (la fenêtre exigerait une version que le magasin
        // ne propose pas). Refusé à la saisie.
        if ($current !== null && $minimum !== null &&
            version_compare($minimum, $current, '>')) {
            return $this->json($response, [
                'success' => false,
                'code' => 'MINIMUM_ABOVE_CURRENT',
                'message' => 'La version minimum ne peut pas dépasser la version publiée : cela bloquerait tous les utilisateurs sans issue.',
            ], 422);
        }

        $config->fill([
            'current_version' => $current,
            'minimum_version' => $minimum,
            'message_fr' => array_key_exists('message_fr', $data)
                ? ($data['message_fr'] ?: null) : $config->message_fr,
            'message_en' => array_key_exists('message_en', $data)
                ? ($data['message_en'] ?: null) : $config->message_en,
            'store_url' => array_key_exists('store_url', $data)
                ? (trim((string) $data['store_url']) ?: null) : $config->store_url,
            'force_update' => isset($data['force_update'])
                ? (bool) $data['force_update'] : $config->force_update,
            'active' => isset($data['active'])
                ? (bool) $data['active'] : $config->active,
        ]);
        $config->save();

        return $this->json($response, [
            'success' => true,
            'data' => ['version' => $config->fresh()],
            'message' => 'Configuration enregistrée',
        ]);
    }

    /** POST /admin/app-versions/{platform}/reset-stats */
    public function resetStats(Request $request, Response $response, array $args): Response
    {
        $updated = AppVersion::where('platform', $args['platform'] ?? '')
            ->update(['stats_updated' => 0, 'stats_dismissed' => 0]);
        if (!$updated) {
            return $this->json($response, ['success' => false, 'message' => 'Plateforme inconnue'], 404);
        }
        return $this->json($response, ['success' => true, 'message' => 'Compteurs remis à zéro']);
    }
}
