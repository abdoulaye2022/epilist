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

    private function formatStore(Store $store, bool $withOrder = false, ?int $userId = null): array
    {
        $out = [
            'id' => $store->id,
            'name' => $store->name,
            'slug' => $store->slug,
            // La planche montre l'adresse et les horaires sur la carte
            // d'un magasin. La DISTANCE n'est pas ici : elle se calcule
            // entre la position du telephone et ces coordonnees, et
            // l'enregistrer figerait une distance depuis un point qui
            // n'a pas de sens.
            'address' => $store->address,
            'city' => $store->city,
            'postal_code' => $store->postal_code,
            'latitude' => $store->latitude,
            'longitude' => $store->longitude,
            'opening_hours' => $store->opening_hours,
            'created_at' => $store->created_at?->toISOString(),
            'updated_at' => $store->updated_at?->toISOString(),
        ];
        if ($userId !== null) {
            $out['is_favorite'] = $store->isFavoriteFor($userId);
        }
        if ($withOrder) {
            $out['category_order'] = $store->categoryOrders->pluck('category_kind')->values();
        }
        return $out;
    }

    /** Les jours acceptes par opening_hours, dans l'ordre de la semaine. */
    private const JOURS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

    /**
     * Valide et normalise les heures d'ouverture recues.
     *
     * Forme attendue : {"mon":["08:00","21:00"], "sun":null}. Un jour
     * absent ou nul vaut « ferme ». Rend `null` si la forme est
     * invalide — le controleur repond alors 422 plutot que d'ecrire un
     * JSON que personne ne saura relire.
     */
    private function normalizeOpeningHours(mixed $brut): array|false|null
    {
        if ($brut === null || $brut === '') {
            return null;
        }
        if (is_string($brut)) {
            $brut = json_decode($brut, true);
        }
        if (!is_array($brut)) {
            return false;
        }

        $propre = [];
        foreach ($brut as $jour => $plage) {
            $jour = strtolower((string) $jour);
            if (!in_array($jour, self::JOURS, true)) {
                return false;
            }
            if ($plage === null) {
                $propre[$jour] = null;
                continue;
            }
            if (!is_array($plage) || count($plage) !== 2) {
                return false;
            }
            foreach ($plage as $heure) {
                if (!is_string($heure) || !preg_match('/^([01][0-9]|2[0-3]):[0-5][0-9]$/', $heure)) {
                    return false;
                }
            }
            // Une plage qui se ferme avant d'ouvrir est une faute de
            // saisie, pas un magasin ouvert la nuit : on la refuse.
            if ($plage[0] >= $plage[1]) {
                return false;
            }
            $propre[$jour] = array_values($plage);
        }
        return $propre;
    }

    /** Les champs de localisation, valides, prets a etre ecrits. */
    private function lieuDepuis(array $data): array|false
    {
        $champs = [];
        foreach (['address' => 255, 'city' => 120, 'postal_code' => 20] as $champ => $max) {
            if (!array_key_exists($champ, $data)) {
                continue;
            }
            $valeur = $data[$champ] === null ? null : trim((string) $data[$champ]);
            if ($valeur !== null && mb_strlen($valeur) > $max) {
                return false;
            }
            $champs[$champ] = ($valeur === '') ? null : $valeur;
        }
        foreach (['latitude' => 90, 'longitude' => 180] as $champ => $borne) {
            if (!array_key_exists($champ, $data)) {
                continue;
            }
            if ($data[$champ] === null || $data[$champ] === '') {
                $champs[$champ] = null;
                continue;
            }
            if (!is_numeric($data[$champ])) {
                return false;
            }
            $v = (float) $data[$champ];
            if ($v < -$borne || $v > $borne) {
                return false;
            }
            $champs[$champ] = $v;
        }
        if (array_key_exists('opening_hours', $data)) {
            $heures = $this->normalizeOpeningHours($data['opening_hours']);
            if ($heures === false) {
                return false;
            }
            $champs['opening_hours'] = $heures;
        }
        return $champs;
    }

    /** Le magasin doit appartenir à l'espace actif (Phase 2). */
    private function findOwnedStore(\Psr\Http\Message\ServerRequestInterface $request, int $userId, int $storeId): ?Store
    {
        $space = \App\Services\SpaceAccessService::resolveSpace($request, $userId);
        return \App\Services\SpaceAccessService::scopeQuery(
            Store::where('id', $storeId), $space, $userId)->first();
    }

    /** GET /stores — mes magasins, avec leur ordre de rayons */
    public function index(Request $request, Response $response): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');
            $space = \App\Services\SpaceAccessService::resolveSpace($request, (int) $userId);
            $stores = \App\Services\SpaceAccessService::scopeQuery(
                    Store::with(['categoryOrders', 'favorites']), $space, (int) $userId)
                ->orderBy('name')
                ->get();

            // Les favoris d'abord : la planche remonte les magasins
            // qu'on frequente en haut de la liste.
            $tries = $stores->sortByDesc(fn($s) => $s->isFavoriteFor((int) $userId) ? 1 : 0)->values();

            return $this->json($response, [
                'success' => true,
                'data' => $tries->map(
                    fn($s) => $this->formatStore($s, withOrder: true, userId: (int) $userId)
                )->values(),
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
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

            $space = \App\Services\SpaceAccessService::resolveSpace($request, (int) $userId);
            \App\Services\SpaceAccessService::assertWrite($space, (int) $userId, 'manage_lists');
            $existing = \App\Services\SpaceAccessService::scopeQuery(
                    Store::withTrashed(), $space, (int) $userId)
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

            $created = Store::create(['user_id' => $userId, 'space_id' => $space->id, 'created_by_user_id' => (int) $userId, 'name' => $name, 'slug' => $slug]);

            return $this->json($response, [
                'success' => true,
                'data' => $this->formatStore($created),
                'message' => 'Magasin créé',
            ], 201);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
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
            $store = $this->findOwnedStore($request, (int) $userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            $name = trim($data['name']);
            $slug = Store::slugify($name);

            $conflictSpace = \App\Services\SpaceAccessService::resolveSpace($request, (int) $userId);
            $conflict = \App\Services\SpaceAccessService::scopeQuery(
                    Store::query(), $conflictSpace, (int) $userId)
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

            $lieu = $this->lieuDepuis($data);
            if ($lieu === false) {
                return $this->json($response, [
                    'success' => false,
                    'code' => 'STORE_LOCATION_INVALID',
                    'message' => 'Adresse, coordonnées ou heures d\'ouverture invalides',
                ], 422);
            }

            $store->update(['name' => $name, 'slug' => $slug] + $lieu);

            return $this->json($response, [
                'success' => true,
                'data' => $this->formatStore(
                    $store->fresh(['categoryOrders', 'favorites']),
                    withOrder: true,
                    userId: (int) $userId
                ),
                'message' => 'Magasin enregistré',
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
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
            $store = $this->findOwnedStore($request, (int) $userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            $store->delete();

            return $this->json($response, ['success' => true, 'message' => 'Magasin supprimé']);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Exception $e) {
            error_log("Erreur stores.destroy: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de la suppression'], 500);
        }
    }

    /**
     * POST /stores/{id}/merge {target_store_id}
     * Fusionne le magasin {id} DANS la cible : la cible est conservée ;
     * si elle n'a pas d'ordre de rayons et que la source en a un, l'ordre
     * est transféré ; la source est supprimée (soft delete).
     */
    public function merge(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        $targetId = (int) ($data['target_store_id'] ?? 0);

        try {
            $userId = $request->getAttribute('auth_id');
            $source = $this->findOwnedStore($request, (int) $userId, (int) $args['id']);
            $target = $targetId > 0 ? $this->findOwnedStore($request, (int) $userId, $targetId) : null;

            if (!$source || !$target) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }
            if ($source->id === $target->id) {
                return $this->json($response, ['success' => false, 'message' => 'Impossible de fusionner un magasin avec lui-même'], 422);
            }

            DB::connection()->transaction(function () use ($source, $target) {
                $targetHasOrder = StoreCategoryOrder::where('store_id', $target->id)->exists();
                if (!$targetHasOrder) {
                    StoreCategoryOrder::where('store_id', $source->id)
                        ->update(['store_id' => $target->id]);
                }
                $source->delete();
            });

            return $this->json($response, [
                'success' => true,
                'data' => $this->formatStore($target->fresh('categoryOrders'), withOrder: true),
                'message' => 'Magasins fusionnés',
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Exception $e) {
            error_log("Erreur stores.merge: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de la fusion'], 500);
        }
    }

    /**
     * PUT /stores/{id}/favorite — met ce magasin en favori.
     *
     * Idempotent : appuyer deux fois sur l'etoile ne cree pas deux
     * lignes, et ne repond pas en erreur.
     */
    public function setFavorite(Request $request, Response $response, array $args): Response
    {
        try {
            $userId = (int) $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($request, $userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            \App\Models\StoreFavorite::firstOrCreate([
                'store_id' => $store->id,
                'user_id' => $userId,
            ]);

            return $this->json($response, [
                'success' => true,
                'data' => ['id' => $store->id, 'is_favorite' => true],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Exception $e) {
            error_log("Erreur stores.setFavorite: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de l\'enregistrement du favori'], 500);
        }
    }

    /** DELETE /stores/{id}/favorite — retire ce magasin des favoris. */
    public function unsetFavorite(Request $request, Response $response, array $args): Response
    {
        try {
            $userId = (int) $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($request, $userId, (int) $args['id']);
            if (!$store) {
                return $this->json($response, ['success' => false, 'message' => 'Magasin introuvable'], 404);
            }

            \App\Models\StoreFavorite::where('store_id', $store->id)
                ->where('user_id', $userId)
                ->delete();

            return $this->json($response, [
                'success' => true,
                'data' => ['id' => $store->id, 'is_favorite' => false],
            ]);
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Exception $e) {
            error_log("Erreur stores.unsetFavorite: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors du retrait du favori'], 500);
        }
    }

    /** GET /stores/{id}/category-order */
    public function getCategoryOrder(Request $request, Response $response, array $args): Response
    {
        try {
            $userId = $request->getAttribute('auth_id');
            $store = $this->findOwnedStore($request, (int) $userId, (int) $args['id']);
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
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
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
            $store = $this->findOwnedStore($request, (int) $userId, (int) $args['id']);
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
        } catch (\App\Services\SpaceAccessException $sae) {
            $response->getBody()->write(json_encode(['success' => false, 'code' => $sae->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus($sae->getStatus());
        } catch (\Exception $e) {
            error_log("Erreur stores.setCategoryOrder: " . $e->getMessage());
            return $this->json($response, ['success' => false, 'message' => 'Erreur lors de l\'enregistrement de l\'ordre'], 500);
        }
    }
}
