<?php
// app/Services/ReceiptExportService.php

namespace App\Services;

use App\Models\ListReceipt;
use App\Models\ShoppingList;
use App\Models\User;
use Carbon\Carbon;

class ReceiptExportService
{
    /**
     * ✅ Générer un export PDF des factures
     */
    public static function exportToPDF(int $listId, User $user): string
    {
        $list = ShoppingList::with(['receipts' => function($query) {
            $query->orderBy('purchase_date', 'desc');
        }])->findOrFail($listId);

        $receipts = $list->receipts;
        $currency = $user->getPreferredCurrency();

        // Calculer les totaux
        $totalAmount = $receipts->sum('total_amount');
        $receiptCount = $receipts->count();

        // Grouper par magasin
        $byStore = $receipts->groupBy('store_name');

        $html = self::generatePDFHTML($list, $receipts, $user, $currency, [
            'total_amount' => $totalAmount,
            'receipt_count' => $receiptCount,
            'by_store' => $byStore
        ]);

        return $html;
    }

    /**
     * ✅ Générer un export CSV des factures
     */
    public static function exportToCSV(int $listId, User $user): string
    {
        $list = ShoppingList::with(['receipts' => function($query) {
            $query->orderBy('purchase_date', 'desc');
        }])->findOrFail($listId);

        $receipts = $list->receipts;
        $currency = $user->getPreferredCurrency();

        $csv = [];

        // En-têtes
        $csv[] = [
            'Store Name',
            'Purchase Date',
            'Amount',
            'Currency',
            'Notes',
            'Created At'
        ];

        // Données
        foreach ($receipts as $receipt) {
            $csv[] = [
                $receipt->store_name ?? '',
                $receipt->purchase_date ? $receipt->purchase_date->format('Y-m-d') : '',
                number_format($receipt->total_amount, 2, '.', ''),
                $currency->code,
                $receipt->notes ?? '',
                $receipt->created_at->format('Y-m-d H:i:s')
            ];
        }

        return self::arrayToCSV($csv);
    }

    /**
     * ✅ Générer le HTML pour le PDF
     */
    private static function generatePDFHTML(
        ShoppingList $list,
        $receipts,
        User $user,
        $currency,
        array $stats
    ): string {
        $listName = htmlspecialchars($list->name);
        $userName = htmlspecialchars($user->name);
        $date = Carbon::now()->format('Y-m-d');

        $receiptsHTML = '';
        foreach ($receipts as $receipt) {
            $storeName = htmlspecialchars($receipt->store_name ?? 'N/A');
            $purchaseDate = $receipt->purchase_date ? $receipt->purchase_date->format('Y-m-d') : 'N/A';
            $amount = $currency->formatAmount($receipt->total_amount);
            $notes = $receipt->notes ? '<br><small style="color: #6b7280;">' . htmlspecialchars($receipt->notes) . '</small>' : '';

            $receiptsHTML .= "
            <tr>
                <td style='padding: 12px; border-bottom: 1px solid #e5e7eb;'>{$storeName}</td>
                <td style='padding: 12px; border-bottom: 1px solid #e5e7eb;'>{$purchaseDate}</td>
                <td style='padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: right; font-weight: 600;'>{$amount}</td>
            </tr>";

            if ($receipt->notes) {
                $receiptsHTML .= "
                <tr>
                    <td colspan='3' style='padding: 0 12px 12px 12px; border-bottom: 1px solid #e5e7eb;'>
                        <small style='color: #6b7280;'>📝 " . htmlspecialchars($receipt->notes) . "</small>
                    </td>
                </tr>";
            }
        }

        $storesHTML = '';
        foreach ($stats['by_store'] as $storeName => $storeReceipts) {
            $storeTotal = $storeReceipts->sum('total_amount');
            $storeCount = $storeReceipts->count();
            $formattedTotal = $currency->formatAmount($storeTotal);

            $storesHTML .= "
            <tr>
                <td style='padding: 8px 12px; border-bottom: 1px solid #e5e7eb;'>" . htmlspecialchars($storeName) . "</td>
                <td style='padding: 8px 12px; border-bottom: 1px solid #e5e7eb; text-align: center;'>{$storeCount}</td>
                <td style='padding: 8px 12px; border-bottom: 1px solid #e5e7eb; text-align: right; font-weight: 600;'>{$formattedTotal}</td>
            </tr>";
        }

        $totalFormatted = $currency->formatAmount($stats['total_amount']);

        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <title>Receipt Export - {$listName}</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 40px;
                    color: #1f2937;
                }
                .header {
                    border-bottom: 3px solid #3b82f6;
                    padding-bottom: 20px;
                    margin-bottom: 30px;
                }
                .header h1 {
                    margin: 0 0 10px 0;
                    color: #1f2937;
                    font-size: 28px;
                }
                .header .meta {
                    color: #6b7280;
                    font-size: 14px;
                }
                .summary {
                    background: #f3f4f6;
                    padding: 20px;
                    border-radius: 8px;
                    margin-bottom: 30px;
                }
                .summary-grid {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 20px;
                }
                .summary-item {
                    text-align: center;
                }
                .summary-item .label {
                    font-size: 12px;
                    color: #6b7280;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 5px;
                }
                .summary-item .value {
                    font-size: 24px;
                    font-weight: 700;
                    color: #1f2937;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-bottom: 30px;
                }
                th {
                    background: #f9fafb;
                    padding: 12px;
                    text-align: left;
                    font-weight: 600;
                    font-size: 14px;
                    color: #374151;
                    border-bottom: 2px solid #e5e7eb;
                }
                .section-title {
                    font-size: 20px;
                    font-weight: 600;
                    margin: 30px 0 15px 0;
                    color: #1f2937;
                }
                .footer {
                    margin-top: 50px;
                    padding-top: 20px;
                    border-top: 1px solid #e5e7eb;
                    text-align: center;
                    color: #6b7280;
                    font-size: 12px;
                }
            </style>
        </head>
        <body>
            <div class='header'>
                <h1>📄 Receipt Export</h1>
                <div class='meta'>
                    <strong>List:</strong> {$listName} |
                    <strong>User:</strong> {$userName} |
                    <strong>Generated:</strong> {$date}
                </div>
            </div>

            <div class='summary'>
                <div class='summary-grid'>
                    <div class='summary-item'>
                        <div class='label'>Total Receipts</div>
                        <div class='value'>{$stats['receipt_count']}</div>
                    </div>
                    <div class='summary-item'>
                        <div class='label'>Total Amount</div>
                        <div class='value'>{$totalFormatted}</div>
                    </div>
                    <div class='summary-item'>
                        <div class='label'>Stores</div>
                        <div class='value'>" . count($stats['by_store']) . "</div>
                    </div>
                </div>
            </div>

            <h2 class='section-title'>All Receipts</h2>
            <table>
                <thead>
                    <tr>
                        <th>Store Name</th>
                        <th>Purchase Date</th>
                        <th style='text-align: right;'>Amount</th>
                    </tr>
                </thead>
                <tbody>
                    {$receiptsHTML}
                </tbody>
            </table>

            <h2 class='section-title'>Summary by Store</h2>
            <table>
                <thead>
                    <tr>
                        <th>Store</th>
                        <th style='text-align: center;'>Receipts</th>
                        <th style='text-align: right;'>Total</th>
                    </tr>
                </thead>
                <tbody>
                    {$storesHTML}
                </tbody>
            </table>

            <div class='footer'>
                <p>Generated by EpiList - Smart Shopping List Management<br>
                © " . date('Y') . " EpiList. All rights reserved.</p>
            </div>
        </body>
        </html>";
    }

    /**
     * ✅ Convertir un tableau en CSV
     */
    private static function arrayToCSV(array $data): string
    {
        $output = fopen('php://temp', 'r+');

        foreach ($data as $row) {
            fputcsv($output, $row);
        }

        rewind($output);
        $csv = stream_get_contents($output);
        fclose($output);

        return $csv;
    }
}
