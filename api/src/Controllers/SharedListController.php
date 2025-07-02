<?php
// app/Http/Controllers/SharedListController.php - VERSION CORRIGÉE

namespace App\Controllers;

use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\User;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Valitron\Validator;
use Carbon\Carbon;

class SharedListController
{
    // ✅ VOTRE DOMAINE RÉEL
    private const CUSTOM_DOMAIN = 'epilist.app'; // ✅ Changé pour votre domaine
    private const APP_SCHEME = 'epilist';
    
    // URLs des stores
    private const ANDROID_STORE_URL = 'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
    private const IOS_STORE_URL = 'https://apps.apple.com/app/epilist/id123456789';

    /**
     * Créer un lien de partage pour une liste
     */
    public function createShareLink(Request $request, Response $response, array $args): Response
    {
        $data = $request->getParsedBody();
        
        $validator = new Validator($data);
        $validator->rule('required', 'permission')->message('Permission requise');
        $validator->rule('in', 'permission', ['readOnly', 'edit', 'admin'])->message('Permission invalide');
        $validator->rule('integer', 'expiration_days')->message('Durée d\'expiration invalide');
        $validator->rule('min', 'expiration_days', 1)->message('Durée minimum 1 jour');
        $validator->rule('max', 'expiration_days', 365)->message('Durée maximum 365 jours');
        
        if (!$validator->validate()) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'errors' => $validator->errors()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        try {
            $user_id = $request->getAttribute('auth_id');
            $list_id = $args['id'];
            
            // Vérifier que l'utilisateur possède la liste
            $list = ShoppingList::where('user_id', $user_id)->findOrFail($list_id);
            
            // Générer un token sécurisé
            $shareToken = $this->generateShareToken();
            $expirationDays = $data['expiration_days'] ?? 30;
            $expiresAt = Carbon::now()->addDays($expirationDays);
            
            // Créer le partage
            SharedList::create([
                'list_id' => $list_id,
                'owner_id' => $user_id,
                'share_token' => $shareToken,
                'permission' => $data['permission'],
                'expires_at' => $expiresAt,
                'is_active' => true,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            // Récupérer les informations de l'utilisateur
            $owner = User::find($user_id);
            $ownerName = $owner->name ?? $owner->email;

            // ✅ Générer l'URL web comme lien principal
            $shareUrl = $this->generateWebUrl($shareToken);

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => [
                    'share_token' => $shareToken,
                    'share_url' => $shareUrl, // https://epilist.app/share/token
                    'list_name' => $list->name,
                    'owner_name' => $ownerName,
                    'permission' => $data['permission'],
                    'expires_at' => $expiresAt->toISOString(),
                    'expires_in_days' => $expirationDays,
                    
                    // URLs alternatives
                    'app_url' => $this->generateAppUrl($shareToken),
                    'store_urls' => [
                        'android' => self::ANDROID_STORE_URL,
                        'ios' => self::IOS_STORE_URL
                    ],
                    
                    // Message de partage optimisé pour le web
                    'share_message' => $this->generateWebShareMessage($shareToken, $list->name, $ownerName, $shareUrl)
                ],
                'message' => 'Lien de partage créé avec succès'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la création du lien de partage',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * Obtenir les informations d'une invitation
     */
    public function getShareInvitation(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            // Vérifier que le token est valide et actif
            $sharedList = SharedList::with(['shoppingList.items', 'owner'])
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            // Préparer les données d'invitation
            $invitation = [
                'token' => $shareToken,
                'list_name' => $sharedList->shoppingList->name,
                'owner_name' => $sharedList->owner->name ?? $sharedList->owner->email,
                'owner_email' => $sharedList->owner->email,
                'permission' => $sharedList->permission,
                'permission_display_name' => $this->getPermissionDisplayName($sharedList->permission),
                'expires_at' => $sharedList->expires_at->toISOString(),
                'is_expired' => $sharedList->expires_at->isPast(),
                'created_at' => $sharedList->created_at->toISOString(),
                
                // Informations sur la liste
                'shopping_list' => [
                    'id' => $sharedList->shoppingList->id,
                    'name' => $sharedList->shoppingList->name,
                    'items_count' => $sharedList->shoppingList->items->count(),
                    'purchased_items_count' => $sharedList->shoppingList->items->where('is_purchased', true)->count(),
                    'total_price' => $sharedList->shoppingList->items->sum(function($item) {
                        return ($item->price ?? 0) * $item->quantity;
                    }),
                    'created_at' => $sharedList->shoppingList->created_at->toISOString()
                ],
                
                // URLs de partage
                'share_urls' => [
                    'web' => $this->generateWebUrl($shareToken),
                    'app' => $this->generateAppUrl($shareToken),
                    'android_store' => self::ANDROID_STORE_URL,
                    'ios_store' => self::IOS_STORE_URL
                ]
            ];

            $response->getBody()->write(json_encode([
                'success' => true,
                'data' => $invitation
            ]));
            return $response->withHeader('Content-Type', 'application/json');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Invitation invalide ou expirée'
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'invitation',
                'error' => $e->getMessage()
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(500);
        }
    }

    /**
     * ✅ ENDPOINT POUR SERVIR LA PAGE DE REDIRECTION
     */
    public function showSharePage(Request $request, Response $response, array $args): Response
    {
        try {
            $shareToken = $args['token'];
            
            // Vérifier que le token est valide
            $sharedList = SharedList::with(['shoppingList', 'owner'])
                ->where('share_token', $shareToken)
                ->where('is_active', true)
                ->where('expires_at', '>', Carbon::now())
                ->firstOrFail();

            $listName = $sharedList->shoppingList->name;
            $ownerName = $sharedList->owner->name ?? $sharedList->owner->email;
            
            // Générer la page HTML de redirection
            $html = $this->generateRedirectPageHtml($shareToken, $listName, $ownerName);
            
            $response->getBody()->write($html);
            return $response->withHeader('Content-Type', 'text/html');
            
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            // Page d'erreur si le token n'existe pas
            $html = $this->generateErrorPageHtml('Invitation invalide ou expirée');
            $response->getBody()->write($html);
            return $response->withHeader('Content-Type', 'text/html')->withStatus(404);
        } catch (\Exception $e) {
            $html = $this->generateErrorPageHtml('Erreur lors du chargement de l\'invitation');
            $response->getBody()->write($html);
            return $response->withHeader('Content-Type', 'text/html')->withStatus(500);
        }
    }

    // ✅ Accepter une invitation (inchangé)
    public function acceptShareInvitation(Request $request, Response $response, array $args): Response
    {
        // ... votre code existant pour accepter l'invitation
    }

    // ✅ Refuser une invitation (inchangé)  
    public function declineShareInvitation(Request $request, Response $response, array $args): Response
    {
        // ... votre code existant pour refuser l'invitation
    }

    // ✅ MÉTHODES UTILITAIRES

    /**
     * Générer un token de partage sécurisé
     */
    private function generateShareToken(): string
    {
        $token = substr(bin2hex(random_bytes(6)), 0, 12);
        
        while (SharedList::where('share_token', $token)->exists()) {
            $token = substr(bin2hex(random_bytes(6)), 0, 12);
        }
        
        return $token;
    }

    /**
     * ✅ Générer l'URL web avec epilist.app
     */
    private function generateWebUrl(string $token): string
    {
        return "https://" . self::CUSTOM_DOMAIN . "/share/{$token}";
    }

    /**
     * Générer l'URL app avec schéma personnalisé
     */
    private function generateAppUrl(string $token): string
    {
        return self::APP_SCHEME . "://share/{$token}";
    }

    /**
     * Générer un message de partage optimisé pour le web
     */
    private function generateWebShareMessage(string $token, string $listName, string $ownerName, string $webUrl): string
    {
        return "{$ownerName} vous invite à collaborer sur la liste d'épicerie \"{$listName}\".\n\n" .
               "🔗 Cliquez sur ce lien pour ouvrir l'app ou la télécharger :\n{$webUrl}\n\n" .
               "📱 EpiList - Vos listes de courses partagées";
    }

    /**
     * ✅ Générer la page HTML de redirection
     */
    private function generateRedirectPageHtml(string $token, string $listName, string $ownerName): string
    {
        $appUrl = $this->generateAppUrl($token);
        
        return '<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invitation EpiList - ' . htmlspecialchars($listName) . '</title>
    <meta name="description" content="' . htmlspecialchars($ownerName) . ' vous invite à collaborer sur la liste ' . htmlspecialchars($listName) . '">
    
    <!-- Open Graph pour partage social -->
    <meta property="og:title" content="Invitation EpiList - ' . htmlspecialchars($listName) . '">
    <meta property="og:description" content="' . htmlspecialchars($ownerName) . ' vous invite à collaborer sur cette liste d\'épicerie">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://' . self::CUSTOM_DOMAIN . '/share/' . $token . '">
    
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 400px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        
        .logo {
            width: 80px;
            height: 80px;
            background: #4CAF50;
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 40px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 24px;
        }
        
        .invite-text {
            color: #666;
            margin-bottom: 30px;
            line-height: 1.5;
        }
        
        .app-button {
            display: block;
            width: 100%;
            padding: 15px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            font-size: 16px;
            margin-bottom: 15px;
            transition: background 0.3s;
        }
        
        .app-button:hover { background: #45a049; }
        
        .store-button { background: #2196F3; }
        .store-button:hover { background: #1976D2; }
        
        .divider {
            margin: 20px 0;
            color: #999;
            font-size: 14px;
        }
        
        .help-text {
            font-size: 12px;
            color: #999;
            margin-top: 20px;
        }
        
        @media (max-width: 480px) {
            .container { padding: 30px 20px; }
        }
    </style>
    
    <script>
        const isAndroid = /Android/i.test(navigator.userAgent);
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
        const isMobile = isAndroid || isIOS;
        
        const appUrl = "' . $appUrl . '";
        const androidStoreUrl = "' . self::ANDROID_STORE_URL . '";
        const iosStoreUrl = "' . self::IOS_STORE_URL . '";
        
        function tryOpenApp() {
            if (!isMobile) return;
            
            const iframe = document.createElement("iframe");
            iframe.style.display = "none";
            iframe.src = appUrl;
            document.body.appendChild(iframe);
            
            setTimeout(() => {
                document.body.removeChild(iframe);
            }, 2000);
        }
        
        function openApp() {
            tryOpenApp();
        }
        
        function openStore() {
            const storeUrl = isIOS ? iosStoreUrl : androidStoreUrl;
            window.open(storeUrl, "_blank");
        }
        
        if (isMobile) {
            setTimeout(tryOpenApp, 1000);
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="logo">📱</div>
        
        <h1>Invitation EpiList</h1>
        
        <div class="invite-text">
            <strong>' . htmlspecialchars($ownerName) . '</strong> vous invite à collaborer sur la liste d\'épicerie 
            <strong>"' . htmlspecialchars($listName) . '"</strong>
        </div>
        
        <a href="' . $appUrl . '" class="app-button" onclick="openApp()">
            📱 Ouvrir EpiList
        </a>
        
        <div class="divider">ou télécharger l\'application</div>
        
        <a href="' . self::ANDROID_STORE_URL . '" class="app-button store-button" target="_blank">
            📲 Play Store (Android)
        </a>
        
        <a href="' . self::IOS_STORE_URL . '" class="app-button store-button" target="_blank">
            🍎 App Store (iOS)
        </a>
        
        <div class="help-text">
            Si vous avez déjà l\'application, elle devrait s\'ouvrir automatiquement.
            <br>Sinon, téléchargez-la et cliquez sur "Ouvrir EpiList".
        </div>
    </div>
</body>
</html>';
    }

    /**
     * Générer une page d'erreur
     */
    private function generateErrorPageHtml(string $errorMessage): string
    {
        return '<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Erreur - EpiList</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
        }
        .error-container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            text-align: center;
            max-width: 400px;
        }
        .error-icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        h1 {
            color: #e74c3c;
            margin-bottom: 10px;
        }
        p {
            color: #666;
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon">❌</div>
        <h1>Erreur</h1>
        <p>' . htmlspecialchars($errorMessage) . '</p>
    </div>
</body>
</html>';
    }

    /**
     * Obtenir le nom d'affichage d'une permission
     */
    private function getPermissionDisplayName(string $permission): string
    {
        return match ($permission) {
            'readOnly' => 'Lecture seule',
            'edit' => 'Modification',
            'admin' => 'Administration',
            default => 'Inconnu'
        };
    }
}