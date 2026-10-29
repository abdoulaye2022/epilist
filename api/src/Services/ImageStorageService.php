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
//
// DEUX REGIMES DE VISIBILITE, et le choix n'est pas cosmetique :
//
//   - uploadSanitized()  -> objet PUBLIC, rend une URL permanente.
//     Pour ce qui est deja montre a tout le monde : avatars, photos de
//     produits.
//
//   - uploadPrivee()     -> objet PRIVE, rend la CLE de l'objet.
//     Pour les RECUS. Un recu porte le magasin, la date, les montants et
//     parfois les quatre derniers chiffres d'une carte. Il etait televerse
//     en 'publicRead' : quiconque connaissait l'URL le lisait, sans
//     compte, sans jeton, pour toujours. L'URL n'etait pas devinable,
//     mais elle fuit par un partage d'ecran, un presse-papier, un
//     journal de proxy. « Non devinable » n'est pas « prive ».
//
// Une cle d'objet ne s'affiche pas : elle se signe, a la demande et pour
// quinze minutes (urlSignee).

namespace App\Services;

use Google\Cloud\Storage\Bucket;
use Google\Cloud\Storage\StorageClient;

class ImageStorageService
{
    private const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];
    private const MAX_BYTES = 8 * 1024 * 1024;
    private const MAX_DIMENSION = 1280;
    private const JPEG_QUALITY = 82;

    /** Montreal. Le site promet que les donnees restent au Canada. */
    public const LOCATION_PAR_DEFAUT = 'northamerica-northeast1';

    /** Les deux seules regions canadiennes de Google Cloud Storage. */
    public const LOCATIONS_CANADIENNES = [
        'northamerica-northeast1', // Montreal
        'northamerica-northeast2', // Toronto
    ];

    /** Duree de vie d'une URL signee. Assez pour regarder, pas pour partager. */
    private const SIGNATURE_MINUTES = 15;

    private StorageClient $client;
    private string $bucketName;
    private string $bucketLocation;

    /**
     * Configuration par variables d'environnement :
     *   GCS_BUCKET           nom du bucket (ex. epilist-storage)
     *   GCS_BUCKET_LOCATION  region ATTENDUE du bucket. Le code ne peut pas
     *                        deplacer un bucket existant : cette valeur dit
     *                        ou il DOIT etre, et sert a verifier
     *                        (voir scripts/make_receipts_private.php).
     *                        Defaut : northamerica-northeast1 (Montreal).
     *   GCS_KEY_BASE64       cle de compte de service GCP, JSON encode en
     *                        base64 (projet dedie au stockage)
     * Repli : service-account.json Firebase si GCS_KEY_BASE64 est absent.
     */
    public function __construct()
    {
        $this->bucketName = \App\Config\Config::get('GCS_BUCKET', 'epilist-storage');
        $this->bucketLocation = (string) \App\Config\Config::get(
            'GCS_BUCKET_LOCATION',
            self::LOCATION_PAR_DEFAUT
        );

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
     * Valide, assainit (re-encode) et televerse une image PUBLIQUE.
     *
     * Reserve a ce qui est deja montre a tout le monde : avatars, photos
     * de produits. Pour un recu, voir uploadPrivee().
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
        $cle = $this->televerser($rawBytes, $folder, $maxDim, publique: true);
        return "https://storage.googleapis.com/{$this->bucketName}/{$cle}";
    }

    /**
     * Meme assainissement, mais l'objet reste PRIVE et c'est sa CLE qui
     * est rendue, pas une URL.
     *
     * La cle ne se met pas dans un <img> : elle se transforme en URL
     * signee de quinze minutes (urlSignee), et seulement apres que le
     * controleur a verifie que le demandeur a le droit de voir ce recu.
     *
     * @return string la cle de l'objet, ex. « prod/receipts/a1b2....jpg »
     */
    public function uploadPrivee(string $rawBytes, string $folder, int $maxDim = self::MAX_DIMENSION): string
    {
        return $this->televerser($rawBytes, $folder, $maxDim, publique: false);
    }

    /**
     * Assainit puis televerse. Rend la CLE de l'objet dans les deux cas :
     * c'est l'appelant qui decide d'en faire une URL publique ou non.
     */
    private function televerser(string $rawBytes, string $folder, int $maxDim, bool $publique): string
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

        // 5. Nom aleatoire + upload, prefixe par l'environnement :
        //    dev/... en local, prod/... en production (meme bucket).
        $envPrefix = \App\Config\Config::get('APP_ENV', 'production') === 'dev' ? 'dev' : 'prod';
        $name = $envPrefix . '/' . trim($folder, '/') . '/' . bin2hex(random_bytes(16)) . '.jpg';
        $bucket = $this->bucket();
        $options = [
            'name' => $name,
            'metadata' => [
                'contentType' => 'image/jpeg',
                'cacheControl' => 'public, max-age=31536000, immutable',
            ],
        ];
        if (!$publique) {
            // Aucune ACL demandee : l'objet herite des droits du bucket.
            // Et comme un recu n'est jamais relu par un navigateur sans
            // jeton, le cache public d'une annee n'a plus de sens — une
            // URL signee ne vit que quinze minutes.
            $options['metadata']['cacheControl'] = 'private, max-age=0, no-store';
            $bucket->upload($clean, $options);
            return $name;
        }

        try {
            // Bucket en acces "fine-grained" : ACL publique par objet
            $bucket->upload($clean, $options + ['predefinedAcl' => 'publicRead']);
        } catch (\Google\Cloud\Core\Exception\BadRequestException $e) {
            // Bucket en acces uniforme : pas d'ACL par objet — la lecture
            // publique doit etre accordee au niveau du bucket (allUsers =
            // Storage Object Viewer). On re-tente sans ACL.
            $bucket->upload($clean, $options);
        }

        return $name;
    }

    /**
     * URL signee V4 pour lire UN objet prive, valable quinze minutes.
     *
     * La signature se fait avec la cle privee du compte de service : elle
     * ne demande aucun appel reseau, et l'URL rendue ne porte aucun
     * jeton de l'utilisateur.
     *
     * @param string $cle cle de l'objet (ce que rend uploadPrivee)
     * @return array{url: string, expire_a: string} URL et expiration ISO 8601
     */
    public function urlSignee(string $cle, int $minutes = self::SIGNATURE_MINUTES): array
    {
        $expiration = new \DateTimeImmutable("+{$minutes} minutes");
        $url = $this->bucket()->object($cle)->signedUrl($expiration, [
            'version' => 'v4',
            'method' => 'GET',
        ]);

        return [
            'url' => (string) $url,
            'expire_a' => $expiration->format(\DateTimeInterface::ATOM),
        ];
    }

    /**
     * La cle d'un objet, qu'on lui passe une cle ou une vieille URL
     * publique. Rend null si la valeur ne designe pas un objet de NOTRE
     * bucket — on ne supprime jamais a l'aveugle.
     *
     * Les deux formes cohabitent le temps de la bascule : les lignes
     * d'avant la migration 015 portent une URL, les nouvelles une cle.
     */
    public function cleDeLObjet(?string $valeur): ?string
    {
        $valeur = trim((string) $valeur);
        if ($valeur === '') {
            return null;
        }

        foreach (["https://storage.googleapis.com/{$this->bucketName}/"] as $prefixe) {
            if (str_starts_with($valeur, $prefixe)) {
                return substr($valeur, strlen($prefixe)) ?: null;
            }
        }

        // Une cle ne commence jamais par un schema : sans quoi on
        // accepterait l'URL du bucket d'un tiers.
        if (str_contains($valeur, '://')) {
            return null;
        }
        return $valeur;
    }

    /** La region ou le bucket DOIT se trouver (voir GCS_BUCKET_LOCATION). */
    public function regionAttendue(): string
    {
        return $this->bucketLocation;
    }

    /** Le nom du bucket, pour les scripts de diagnostic. */
    public function nomDuBucket(): string
    {
        return $this->bucketName;
    }

    /**
     * La region REELLE du bucket, ou null si le compte de service n'a pas
     * le droit de la lire (storage.buckets.get). Jamais une exception :
     * un diagnostic ne doit pas tomber.
     */
    public function regionReelle(): ?string
    {
        try {
            return $this->bucket()->info()['location'] ?? null;
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Supprime une image precedemment televersee (best effort).
     *
     * Accepte indifferemment une URL publique (lignes d'avant la
     * migration 015) ou une cle d'objet (lignes d'apres) : pendant la
     * bascule, les deux formes vivent cote a cote en base.
     */
    public function deleteByUrl(?string $urlOuCle): void
    {
        $cle = $this->cleDeLObjet($urlOuCle);
        if ($cle === null) {
            return;
        }
        try {
            $this->bucket()->object($cle)->delete();
        } catch (\Throwable $e) {
            error_log('[ImageStorage] delete ignoree: ' . $e->getMessage());
        }
    }

    /**
     * Retire l'acces public d'un objet deja televerse.
     *
     * Rend true si l'objet n'est plus lisible par « allUsers », false si
     * l'operation a echoue. Sur un bucket en acces UNIFORME il n'y a pas
     * d'ACL par objet : la lecture publique vient du bucket, et c'est au
     * niveau du bucket qu'il faut la retirer — le script le dit alors
     * clairement plutot que de pretendre avoir agi.
     *
     * @throws \RuntimeException si le bucket est en acces uniforme
     */
    public function rendrePrive(string $cle): bool
    {
        $objet = $this->bucket()->object($cle);
        try {
            $objet->acl()->delete('allUsers');
            return true;
        } catch (\Google\Cloud\Core\Exception\NotFoundException $e) {
            // Pas d'ACL « allUsers » : l'objet etait deja prive.
            return true;
        } catch (\Google\Cloud\Core\Exception\BadRequestException $e) {
            throw new \RuntimeException(
                'Bucket en acces uniforme : la lecture publique se retire sur le BUCKET, pas sur l objet',
                0,
                $e
            );
        }
    }

    private function bucket(): Bucket
    {
        // Pas de test d'existence : il exigerait storage.buckets.get, alors
        // que le compte de service n'a besoin que des droits sur les OBJETS
        // (Storage Object Admin sur le bucket).
        return $this->client->bucket($this->bucketName);
    }
}
