<?php
// src/Controllers/StoreController.php — magasins et ordre des rayons (tri par rayon)

namespace App\Controllers;

use App\Models\Store;
use App\Models\StoreCategoryOrder;
use Illuminate\Database\Capsule\Manager as DB;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;

class StoreController
{
    /** Les kinds valides = ceux des 12 catégories par défaut. */
    private const VALID_KINDS = [
        'fruits_vegetables', 'meat_fish', 'dairy', 'bakery', 'drinks',
        'snacks', 'hygiene', 'household', 'baby', 'pets', 'health', 'other',
    ];

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function formatStore(Store $store, bool $withOrder = false): array
    {
        $out = [
            'id' => $store->id,
            'name' => $store->name,
            'slug' => $store->slug,
            'created_at' => $store->created_at?->toISOString(),
            'updated_at' => $store->updated_at?->toISOString(),
        ];
        if ($withOrder) {
            $out['category_order'] = $store->categoryOrders->pluck('category_kind')->values();
        }
        return $out;
    }

    /** Le magasin doit appartenir à l'utilisateur authentifié. */
    private function findOwnedStore(int $userId, int $storeId): ?Store
    {
        return Store::where('id', $storeId)->where('user_id', $userId)->first();
    }

    /** GET /stores — mes magasins, avec leur ordre de rayons */
    public function index(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');
            $stores = Store::with('categoryOrders')
                ->where('user_id', $userId)
                ->orderBy('name')
                ->get();

            return $this->json($response, [
                'success' => true,
                'data' => $stores->map(fn($s) => $this->formatStore($s, withOrder: true))->values(),
            ]);
        } catch (\Exception $e) {
            error_log("Erreur stores.index: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors du chargement des magasins'], 500);
        }
    }

    /** POST /stores {name} */
    public function store(Request $request, Response $response): Response
    {
        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', 'name')->message('Nom requis');
        $validator->rule('lengthMax', 'name', 120)->message('Nom trop long (max 120)');
        $validator->rule('lengthMin', 'name', 2)->message('Nom trop court (min 2)');
        if (!$validator->validate()) {
            return $this->json($response, ['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $userId = $request->getAttribute('auth_id');
            $name = trim($data['name']);
            $slug = Store::slugify($name);

            $existing = Store::withTrashed()
                ->where('user_id', $userId)
                ->where('slug', $slug)
                ->first();

            if ($existing) {
                if ($existing->trashed()) {
                    // Recréer un magasin supprimé = le restaurer
                    $existing->restore();
                    $existing->update(['name' => $name]);
                    return $this->json($response, [
                        'success' => true,
                        'data' => $this->formatStore($existing->fresh('categoryOrders'), withOrder: true),
                        'message' => 'Magasin restauré',
                    ], 201);
                }
                return $this->json($response, [
                    'success' => false,
                    'code' => 'STORE_ALREADY_EXISTS',
                    'message' => 'Ce magasin existe déjà',
                    'data' => $this->formatStore($existing),
                ], 409);
            }

            $created = Store::create(['user_id' => $userId, 'name' => $name, 'slug' => $slug]);

            return $this->json($response, [
                'success' => true,
                'data' => $this->formatStore($created),
                'message' => 'Magasin créé',
            ], 201);
        } catch (\Exception $e) {
            error_log("Erreur stores.store: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de la création du magasin'], 500);
        }
    }

    /** PUT /stores/{id} {name} — renommer */
    public function update(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();

        $validator = new Validator($data);
        $validator->rule('required', 'name')->message('Nom requis');
        $validator->rule('lengthMax', 'name', 120)->message('Nom trop long (max 120)');
        $validator->rule('lengthMin', 'name', 2)->message('Nom trop court (min 2)');
        if (!$validator->validate()) {
            return $this->json($response, ['success' => false, 'errors' => $validator->errors()], 422);
        }

        try {
            $userId = $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            $name = trim($data['name']);
            $slug = Store::slugify($name);

            $conflict = Store::where('user_id', $userId)
                ->where('slug', $slug)
                ->where('id', '!=', $store->id)
                ->exists();
            if ($conflict) {
                return $this->json($response, [
                    'success' => false,
                    'code' => 'STORE_ALREADY_EXISTS',
                    'message' => 'Un magasin porte déjà ce nom',
                ], 409);
            }

            $store->update(['name' => $name, 'slug' => $slug]);

            return $this->json($response, [
                'success' => true,
                'data' => $this->formatStore($store->fresh('categoryOrders'), withOrder: true),
                'message' => 'Magasin renommé',
            ]);
        } catch (\Exception $e) {
            error_log("Erreur stores.update: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors du renommage'], 500);
        }
    }

    /** DELETE /stores/{id} — suppression douce (l'ordre des rayons est conservé) */
    public function destroy(Request $request, Response $response, array $args): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            $store->delete();

            return $this->json($response, ['success' => true, 'message' => 'Magasin supprimé']);
        } catch (\Exception $e) {
            error_log("Erreur stores.destroy: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de la suppression'], 500);
        }
    }

    /** GET /stores/{id}/category-order */
    public function getCategoryOrder(Request $request, Response $response, array $args): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'store_id' => $store->id,
                    'category_order' => $store->categoryOrders->pluck('category_kind')->values(),
                ],
            ]);
        } catch (\Exception $e) {
            error_log("Erreur stores.getCategoryOrder: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors du chargement de l\'ordre'], 500);
        }
    }

    /**
     * PUT /stores/{id}/category-order {category_kinds: ["dairy", ...]}
     * REMPLACE tout l'ordre en une transaction : jamais de conflit sur une
     * position individuelle (last-write-wins sur l'ordre complet).
     */
    public function setCategoryOrder(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $kinds = $data['category_kinds'] ?? null;

        if (!is_array($kinds) || $kinds === []) {
            return $this->json($response, [
                'success' => false,
                'message' => 'category_kinds doit être une liste non vide',
            ], 422);
        }

        $kinds = array_values(array_unique(array_map('strval', $kinds)));
        $invalid = array_diff($kinds, self::VALID_KINDS);
        if ($invalid !== []) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Kinds invalides: ' . implode(', ', $invalid),
            ], 422);
        }

        try {
            $userId = $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            DB::connection()->transaction(function () use ($store, $kinds) {
                StoreCategoryOrder::where('store_id', $store->id)->delete();
                foreach ($kinds as $position => $kind) {
                    StoreCategoryOrder::create([
                        'store_id' => $store->id,
                        'category_kind' => $kind,
                        'position' => $position,
                    ]);
                }
            });

            return $this->json($response, [
                'success' => true,
                'data' => [
                    'store_id' => $store->id,
                    'category_order' => $kinds,
                ],
                'message' => 'Ordre des rayons enregistré',
            ]);
        } catch (\Exception $e) {
            error_log("Erreur stores.setCategoryOrder: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de l\'enregistrement de l\'ordre'], 500);
        }
    }
}
