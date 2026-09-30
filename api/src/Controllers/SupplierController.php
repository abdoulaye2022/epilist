<?php
// src/Controllers/SupplierController.php - Fournisseurs (§22, Phase 3).
// Espace PARTAGÉ requis (le personnel n'a pas de fournisseurs).
// Lecture : tout membre. Écriture : permission manage_suppliers.
//  - GET    /suppliers
//  - POST   /suppliers
//  - PUT    /suppliers/{id}
//  - DELETE /suppliers/{id}   (soft delete)

namespace App\Controllers;

use App\Models\Space;
use App\Models\Supplier;
use App\Services\SpaceAccessService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

class SupplierController
{
    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    }

    private function format(Supplier $s): array
    {
        return [
            'id' => $s->id,
            'name' => $s->name,
            'contact_name' => $s->contact_name,
            'phone' => $s->phone,
            'email' => $s->email,
            'notes' => $s->notes,
            'is_active' => (bool) $s->is_active,
            'created_at' => $s->created_at?->toIso8601String(),
        ];
    }

    /** L'espace actif, qui doit être partagé (pas le personnel). */
    private function sharedSpace(Request $request, int $userId): ?Space
    {
        $space = SpaceAccessService::resolveSpace($request, $userId);
        return $space->type === Space::TYPE_PERSONAL ? null : $space;
    }

    public function index(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => true, 'data' => ['suppliers' => []]]);
        }

        $suppliers = Supplier::where('space_id', $space->id)
            ->orderByDesc('is_active')
            ->orderBy('name')
            ->get();

        return $this->json($response, [
            'success' => true,
            'data' => ['suppliers' => $suppliers->map(fn($s) => $this->format($s))->values()],
        ]);
    }

    public function store(Request $request, Response $response): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => false, 'code' => 'PERSONAL_SPACE_PROTECTED'], 422);
        }
        SpaceAccessService::assertPermission($space->id, $userId, 'manage_suppliers');

        $data = (array) $request->getParsedBody();
        $name = trim((string) ($data['name'] ?? ''));
        if ($name === '' || mb_strlen($name) > 150) {
            return $this->json($response, ['success' => false, 'code' => 'INVALID_NAME'], 422);
        }

        $supplier = Supplier::create([
            'space_id' => $space->id,
            'name' => $name,
            'contact_name' => self::opt($data, 'contact_name', 150),
            'phone' => self::opt($data, 'phone', 40),
            'email' => self::opt($data, 'email', 150),
            'notes' => self::opt($data, 'notes', 2000),
            'is_active' => true,
            'created_by_user_id' => $userId,
        ]);

        return $this->json($response, [
            'success' => true,
            'data' => ['supplier' => $this->format($supplier)],
        ], 201);
    }

    private static function opt(array $data, string $key, int $max): ?string
    {
        $v = trim((string) ($data[$key] ?? ''));
        return $v === '' ? null : mb_substr($v, 0, $max);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => false, 'code' => 'SUPPLIER_NOT_FOUND'], 404);
        }
        SpaceAccessService::assertPermission($space->id, $userId, 'manage_suppliers');

        $supplier = Supplier::where('space_id', $space->id)->where('id', (int) $args['id'])->first();
        if (!$supplier) {
            return $this->json($response, ['success' => false, 'code' => 'SUPPLIER_NOT_FOUND'], 404);
        }

        $data = (array) $request->getParsedBody();
        if (array_key_exists('name', $data)) {
            $name = trim((string) $data['name']);
            if ($name === '' || mb_strlen($name) > 150) {
                return $this->json($response, ['success' => false, 'code' => 'INVALID_NAME'], 422);
            }
            $supplier->name = $name;
        }
        foreach ([['contact_name', 150], ['phone', 40], ['email', 150], ['notes', 2000]] as [$key, $max]) {
            if (array_key_exists($key, $data)) {
                $supplier->{$key} = self::opt($data, $key, $max);
            }
        }
        if (array_key_exists('is_active', $data)) {
            $supplier->is_active = (bool) $data['is_active'];
        }
        $supplier->save();

        return $this->json($response, [
            'success' => true,
            'data' => ['supplier' => $this->format($supplier)],
        ]);
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        $userId = (int) $request->getAttribute('auth_id');
        $space = $this->sharedSpace($request, $userId);
        if (!$space) {
            return $this->json($response, ['success' => false, 'code' => 'SUPPLIER_NOT_FOUND'], 404);
        }
        SpaceAccessService::assertPermission($space->id, $userId, 'manage_suppliers');

        $supplier = Supplier::where('space_id', $space->id)->where('id', (int) $args['id'])->first();
        if (!$supplier) {
            return $this->json($response, ['success' => false, 'code' => 'SUPPLIER_NOT_FOUND'], 404);
        }
        $supplier->delete();

        return $this->json($response, ['success' => true]);
    }
}
