<?php
// src/Controllers/AdminController.php
//
// Espace administrateur (JwtMiddleware + AdminMiddleware) :
//  - GET /admin/overview          chiffres du tableau de bord
//  - GET /admin/users             liste + recherche + pagination
//  - PUT /admin/users/{id}        activer/désactiver, rôle
//  - GET /admin/stats             séries temporelles (12 derniers mois)
//  - GET /admin/errors            journal d'erreurs API (monitoring)
//  - DELETE /admin/errors         purge des entrées > 30 jours

namespace App\Controllers;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class AdminController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    /** GET /admin/overview — les chiffres clés du tableau de bord. */
    public function overview(Request $request, Response $response): Response
    {
        $now = Carbon::now();
        $t = fn(string $table) => DB::table($table);

        $data = [
            'users_total' => $t('users')->count(),
            'users_active_7d' => $t('purchase_history')
                ->where('purchased_at', '>=', $now->copy()->subDays(7))
                ->distinct()->count('user_id'),
            'users_new_30d' => $t('users')
                ->where('created_at', '>=', $now->copy()->subDays(30))->count(),
            'lists_total' => $t('shopping_lists')->whereNull('deleted_at')->count(),
            'items_total' => $t('list_items')->whereNull('deleted_at')->count(),
            'receipts_total' => $t('list_receipts')->whereNull('deleted_at')->count(),
            'receipts_scanned' => $t('list_receipts')
                ->where('source', 'receipt_ocr')->whereNull('deleted_at')->count(),
            'purchases_30d' => $t('purchase_history')
                ->where('purchased_at', '>=', $now->copy()->subDays(30))->count(),
            'errors_24h' => $t('api_error_logs')
                ->where('created_at', '>=', $now->copy()->subDay())->count(),
            'errors_7d' => $t('api_error_logs')
                ->where('created_at', '>=', $now->copy()->subDays(7))->count(),
        ];

        return $this->json($response, ['success' => true, 'data' => $data]);
    }

    /** GET /admin/users?search=&page=1&per_page=25 */
    public function users(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $search = trim((string) ($params['search'] ?? ''));
        $page = max(1, (int) ($params['page'] ?? 1));
        $perPage = max(5, min(100, (int) ($params['per_page'] ?? 25)));

        $query = User::query();
        if ($search !== '') {
            $query->where(fn($q) => $q
                ->where('email', 'like', "%{$search}%")
                ->orWhere('first_name', 'like', "%{$search}%")
                ->orWhere('last_name', 'like', "%{$search}%"));
        }

        $total = $query->count();
        $users = $query->orderByDesc('created_at')
            ->skip(($page - 1) * $perPage)->take($perPage)
            ->get()
            ->map(fn($u) => [
                'id' => $u->id,
                'first_name' => $u->first_name,
                'last_name' => $u->last_name,
                'email' => $u->email,
                'role' => $u->role ?? 'user',
                'is_active' => (bool) $u->is_active,
                'email_verified' => (bool) $u->email_verified,
                'sso_provider' => $u->sso_provider,
                'language' => $u->language,
                'created_at' => $u->created_at?->toIso8601String(),
                'lists_count' => DB::table('shopping_lists')
                    ->where('user_id', $u->id)->whereNull('deleted_at')->count(),
            ])->values();

        return $this->json($response, [
            'success' => true,
            'data' => [
                'users' => $users,
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
            ],
        ]);
    }

    /** PUT /admin/users/{id} { is_active?, role? } */
    public function updateUser(Request $request, Response $response, array $args): Response
    {
        $adminId = (int) $request->getAttribute('auth_id');
        $userId = (int) $args['id'];
        $user = User::find($userId);
        if (!$user) {
            return $this->json($response, ['success' => false, 'message' => 'Utilisateur introuvable'], 404);
        }

        $data = $request->getParsedBody() ?? [];

        // Un admin ne peut pas se désactiver ni se rétrograder lui-même
        // (sinon plus personne pour rouvrir la porte).
        if ($userId === $adminId &&
            ((isset($data['is_active']) && !$data['is_active']) ||
             (isset($data['role']) && $data['role'] !== 'admin'))) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Impossible de désactiver ou rétrograder votre propre compte administrateur.',
            ], 422);
        }

        if (isset($data['is_active'])) {
            $user->is_active = (bool) $data['is_active'];
            // Désactivation = fin de toutes ses sessions (les refresh
            // tokens révoqués ne peuvent plus renouveler d'accès).
            if (!$user->is_active) {
                \App\Models\RefreshToken::revokeAllForUser($user->id);
            }
        }
        if (isset($data['role']) && in_array($data['role'], ['user', 'admin'], true)) {
            $user->role = $data['role'];
        }
        $user->save();

        return $this->json($response, [
            'success' => true,
            'message' => 'Utilisateur mis à jour',
            'data' => ['id' => $user->id, 'is_active' => (bool) $user->is_active, 'role' => $user->role],
        ]);
    }

    /** GET /admin/stats — séries mensuelles sur 12 mois. */
    public function stats(Request $request, Response $response): Response
    {
        $since = Carbon::now()->subMonths(11)->startOfMonth();

        $monthly = function (string $table, string $dateColumn) use ($since) {
            return DB::table($table)
                ->selectRaw("DATE_FORMAT($dateColumn, '%Y-%m') AS month, COUNT(*) AS count")
                ->where($dateColumn, '>=', $since)
                ->groupByRaw("DATE_FORMAT($dateColumn, '%Y-%m')")
                ->orderByRaw("DATE_FORMAT($dateColumn, '%Y-%m')")
                ->pluck('count', 'month');
        };

        // Axe complet (mois sans activité inclus)
        $months = [];
        for ($i = 0; $i < 12; $i++) {
            $months[] = $since->copy()->addMonths($i)->format('Y-m');
        }

        $signups = $monthly('users', 'created_at');
        $purchases = $monthly('purchase_history', 'purchased_at');
        $receipts = $monthly('list_receipts', 'created_at');
        $lists = $monthly('shopping_lists', 'created_at');

        $series = array_map(fn($m) => [
            'month' => $m,
            'signups' => (int) ($signups[$m] ?? 0),
            'purchases' => (int) ($purchases[$m] ?? 0),
            'receipts' => (int) ($receipts[$m] ?? 0),
            'lists' => (int) ($lists[$m] ?? 0),
        ], $months);

        // Communautés : le projet ne stocke pas le pays — la devise choisie
        // en tient lieu (CAD = Canada, etc.), complétée par la langue.
        $byCurrency = DB::table('users')
            ->leftJoin('currencies', 'currencies.id', '=', 'users.currency_id')
            ->selectRaw("COALESCE(currencies.code, 'CAD') AS code, COUNT(*) AS users")
            ->whereNull('users.deleted_at')
            ->groupByRaw("COALESCE(currencies.code, 'CAD')")
            ->orderByDesc('users')
            ->get();

        $byLanguage = DB::table('users')
            ->selectRaw("COALESCE(language, 'fr') AS language, COUNT(*) AS users")
            ->whereNull('deleted_at')
            ->groupByRaw("COALESCE(language, 'fr')")
            ->orderByDesc('users')
            ->get();

        $topProducts = DB::table('purchase_history')
            ->selectRaw('normalized_name, MAX(product_name) AS product_name, COUNT(*) AS purchases')
            ->where('purchased_at', '>=', Carbon::now()->subDays(90))
            ->groupBy('normalized_name')
            ->orderByDesc('purchases')
            ->limit(10)
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => [
                'monthly' => $series,
                'top_products' => $topProducts,
                'communities' => [
                    'by_currency' => $byCurrency,
                    'by_language' => $byLanguage,
                ],
            ],
        ]);
    }

    /** GET /admin/errors?page=1&per_page=50 */
    public function errors(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $page = max(1, (int) ($params['page'] ?? 1));
        $perPage = max(10, min(200, (int) ($params['per_page'] ?? 50)));

        $total = DB::table('api_error_logs')->count();
        $rows = DB::table('api_error_logs')
            ->orderByDesc('id')
            ->skip(($page - 1) * $perPage)->take($perPage)
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => [
                'errors' => $rows,
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
            ],
        ]);
    }

    /** DELETE /admin/errors — purge des entrées de plus de 30 jours. */
    public function purgeErrors(Request $request, Response $response): Response
    {
        $deleted = DB::table('api_error_logs')
            ->where('created_at', '<', Carbon::now()->subDays(30))
            ->delete();
        return $this->json($response, [
            'success' => true,
            'message' => "$deleted entrées purgées (plus de 30 jours)",
        ]);
    }
}
