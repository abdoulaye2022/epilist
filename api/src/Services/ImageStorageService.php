<?php
// src/Services/ImageStorageService.php
//
// Upload d'images vers Google Cloud Storage avec DEFENSE EN PROFONDEUR :
// un fichier envoye par un utilisateur est traite comme hostile.
//
//  1. Taille plafonnee (defaut 8 Mo).
//  2. Type verifie par les OCTETS (finfo), jamais par l'extension ni le
//     Content-Type annonces par le client. JPEG / PNG / WebP uniquement.
//  3. RE-ENCODAGE complet via GD (imagecreatefromstring -> nouveau JPEG) :
//     c'est la vraie barriere anti-malware pour une image. Un polyglotte
//     (image+PHP, image+script), une charge dans un chunk PNG ou dans les
//     metadonnees EXIF ne survit pas a une re-rasterisation pixel par
//     pixel. Les EXIF (dont la geolocalisation !) sont supprimes au passage.
//  4. Redimensionnement (defaut max 1280 px) : borne le cout stockage/reseau.
//  5. Nom de fichier ALEATOIRE cote serveur (jamais celui du client),
//     Content-Type force a image/jpeg, cache immuable.
//
// Le bucket est cree a la volee s'il n'existe pas (des que la facturation
// du projet Google est active).

namespace App\Services;

use Google\Cloud\Storage\Bucket;
use Google\Cloud\Storage\StorageClient;

class ImageStorageService
{
    private const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];
    private const MAX_BYTES = 8 * 1024 * 1024;
    private const MAX_DIMENSION = 1280;
    private const JPEG_QUALITY = 82;

    private StorageClient $client;
    private string $bucketName;

    /**
     * Configuration par variables d'environnement :
     *   GCS_BUCKET      nom du bucket (ex. epilist-storage)
     *   GCS_KEY_BASE64  cle de compte de service GCP, JSON encode en base64
     *                   (projet dedie au stockage, ex. fraischezvous)
     * Repli : service-account.json Firebase si GCS_KEY_BASE64 est absent.
     */
    public function __construct()
    {
        $this->bucketName = \App\Config\Config::get('GCS_BUCKET', 'epilist-storage');

        $keyB64 = \App\Config\Config::get('GCS_KEY_BASE64', '');
        if ($keyB64 !== '') {
            $key = json_decode((string) base64_decode($keyB64, true), true);
            if (!is_array($key) || empty($key['project_id'])) {
                throw new \RuntimeException('GCS_KEY_BASE64 invalide (doit etre le JSON de la cle encode en base64)');
            }
            $this->client = new StorageClient([
                'keyFile' => $key,
                'projectId' => $key['project_id'],
            ]);
            return;
        }

        $keyFile = dirname(__DIR__, 2) . '/service-account.json';
        $projectId = json_decode((string) file_get_contents($keyFile), true)['project_id'] ?? '';
        $this->client = new StorageClient([
            'keyFilePath' => $keyFile,
            'projectId' => $projectId,
        ]);
    }

    /**
     * Valide, assainit (re-encode) et televerse une image.
     *
     * @param string $rawBytes contenu brut envoye par le client
     * @param string $folder   prefixe GCS ('avatars' ou 'items')
     * @param int    $maxDim   cote max en pixels apres redimensionnement
     * @return string URL publique de l'image
     * @throws \InvalidArgumentException si le fichier est refuse (message sur pour le client)
     * @throws \RuntimeException si le stockage echoue (config/facturation)
     */
    public function uploadSanitized(string $rawBytes, string $folder, int $maxDim = self::MAX_DIMENSION): string
    {
        // 1. Taille
        if ($rawBytes === '' || strlen($rawBytes) > self::MAX_BYTES) {
            throw new \InvalidArgumentException('Image vide ou trop lourde (max 8 Mo)');
        }

        // 2. Type reel par les octets
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->buffer($rawBytes);
        if (!in_array($mime, self::ALLOWED_MIME, true)) {
            throw new \InvalidArgumentException('Format non supporté (JPEG, PNG ou WebP uniquement)');
        }

        // 3. Re-encodage : si GD ne peut pas rasteriser, le fichier est rejete.
        $src = @imagecreatefromstring($rawBytes);
        if ($src === false) {
            throw new \InvalidArgumentException('Image invalide ou corrompue');
        }

        $w = imagesx($src);
        $h = imagesy($src);
        if ($w < 8 || $h < 8) {
            imagedestroy($src);
            throw new \InvalidArgumentException('Image trop petite');
        }

        // 4. Redimensionnement proportionnel si necessaire
        $scale = min(1.0, $maxDim / max($w, $h));
        $nw = max(1, (int) round($w * $scale));
        $nh = max(1, (int) round($h * $scale));

        $dst = imagecreatetruecolor($nw, $nh);
        // fond blanc : les PNG/WebP transparents deviennent des JPEG propres
        $white = imagecolorallocate($dst, 255, 255, 255);
        imagefill($dst, 0, 0, $white);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        imagedestroy($src);

        ob_start();
        imagejpeg($dst, null, self::JPEG_QUALITY);
        $clean = (string) ob_get_clean();
        imagedestroy($dst);

        if ($clean === '') {
            throw new \RuntimeException('Echec du re-encodage');
        }

        // 5. Nom aleatoire + upload
        $name = trim($folder, '/') . '/' . bin2hex(random_bytes(16)) . '.jpg';
        $bucket = $this->bucket();
        $bucket->upload($clean, [
            'name' => $name,
            'predefinedAcl' => 'publicRead',
            'metadata' => [
                'contentType' => 'image/jpeg',
                'cacheControl' => 'public, max-age=31536000, immutable',
            ],
        ]);

        return "https://storage.googleapis.com/{$this->bucketName}/{$name}";
    }

    /** Supprime une image precedemment televersee (best effort). */
    public function deleteByUrl(?string $url): void
    {
        $prefix = "https://storage.googleapis.com/{$this->bucketName}/";
        if (!$url || !str_starts_with($url, $prefix)) {
            return;
        }
        try {
            $this->bucket()->object(substr($url, strlen($prefix)))->delete();
        } catch (\Throwable $e) {
            error_log('[ImageStorage] delete ignoree: ' . $e->getMessage());
        }
    }

    private function bucket(): Bucket
    {
        $bucket = $this->client->bucket($this->bucketName);
        if (!$bucket->exists()) {
            // Creation paresseuse : fonctionne des que la facturation Google
            // du projet est activee (plan Blaze).
            $bucket = $this->client->createBucket($this->bucketName, [
                'location' => 'NORTHAMERICA-NORTHEAST1',
                'storageClass' => 'STANDARD',
            ]);
        }
        return $bucket;
    }
}
