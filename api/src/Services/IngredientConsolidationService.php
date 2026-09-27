<?php
// src/Services/IngredientConsolidationService.php
//
// Fusion des ingrédients de plusieurs recettes (§18) :
//  - 500 g riz + 1 kg riz -> 1.5 kg riz ;
//  - unités compatibles : g/kg (masse), ml/L (volume), un (pièces) ;
//  - unités incompatibles pour un même produit -> lignes séparées ;
//  - les quantités sont mises à l'échelle des portions demandées.

namespace App\Services;

class IngredientConsolidationService
{
    /** Unité canonique et facteur de conversion vers celle-ci. */
    private const CANONICAL = [
        'kg' => ['kg', 1],
        'g' => ['kg', 0.001],
        'l' => ['L', 1],
        'ml' => ['L', 0.001],
        'un' => ['un', 1],
        '' => ['un', 1],
    ];

    /**
     * @param array $ingredients chacun : name, normalized_name, quantity,
     *   unit (kg|g|L|ml|un|null), optional (bool)
     * @return array fusionnés : name, normalized_name, quantity, unit, optional
     */
    public function consolidate(array $ingredients): array
    {
        $merged = [];
        foreach ($ingredients as $ing) {
            $unitKey = strtolower(trim((string) ($ing['unit'] ?? '')));
            [$canonUnit, $factor] = self::CANONICAL[$unitKey] ?? [null, null];

            // Unité inconnue : conservée telle quelle, sans fusion inter-unités
            $canonUnit ??= $ing['unit'];
            $factor ??= 1;

            $key = $ing['normalized_name'] . '|' . $canonUnit;
            $qty = (float) ($ing['quantity'] ?? 1) * $factor;

            if (isset($merged[$key])) {
                $merged[$key]['quantity'] += $qty;
                $merged[$key]['optional'] = $merged[$key]['optional'] && !empty($ing['optional']);
            } else {
                $merged[$key] = [
                    'name' => $ing['name'],
                    'normalized_name' => $ing['normalized_name'],
                    'quantity' => $qty,
                    'unit' => $canonUnit,
                    'optional' => !empty($ing['optional']),
                ];
            }
        }

        return array_map(function ($m) {
            $m['quantity'] = round($m['quantity'], 3);
            return $m;
        }, array_values($merged));
    }
}
