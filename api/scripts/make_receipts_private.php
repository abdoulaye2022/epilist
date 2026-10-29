<?php
// scripts/make_receipts_private.php — retire l'acces public des photos
// de recus DEJA televersees.
//
// La migration 015 range la cle de l'objet en base. Elle ne touche a
// aucun fichier : les recus d'avant restent lisibles par quiconque
// connait leur URL tant que ce script n'a pas tourne.
//
//   php scripts/make_receipts_private.php              # dry-run (defaut)
//   php scripts/make_receipts_private.php --apply      # agit vraiment
//   php scripts/make_receipts_private.php --apply --limit=50
//
// Le mode par defaut n'ecrit RIEN, ni en base ni dans le stockage : il
// liste, compte et dit ce qu'il ferait. Rien ne part sans --apply.
//
// Il verifie aussi la REGION du bucket et la compare a
// GCS_BUCKET_LOCATION : le site promet que les donnees restent au
// Canada, et cette promesse se verifie ici, pas dans un texte.
declare(strict_types=1);

$racine = dirname(__DIR__);
require $racine . '/vendor/autoload.php';

use App\Models\ListReceipt;
use App\Services\ImageStorageService;

\App\Config\Config::load();
\App\Config\Database::connect();

// ---------------------------------------------------------------- args
$appliquer = in_array('--apply', $argv, true);
$limite = 0;
foreach ($argv as $a) {
    if (str_starts_with($a, '--limit=')) {
        $limite = max(0, (int) substr($a, 8));
    }
}

$mode = $appliquer ? 'APPLY' : 'DRY-RUN';
echo "=== Recus prives — mode {$mode} ===\n\n";
if (!$appliquer) {
    echo "Rien ne sera modifie. Relancer avec --apply pour agir.\n\n";
}

$stockage = new ImageStorageService();

// ------------------------------------------------------------- region
$attendue = $stockage->regionAttendue();
$reelle = $stockage->regionReelle();
echo "Bucket           : " . $stockage->nomDuBucket() . "\n";
echo "Region attendue  : {$attendue}\n";
if ($reelle === null) {
    echo "Region reelle    : illisible (le compte de service n'a pas storage.buckets.get)\n";
    echo "                   -> a verifier a la main dans la console Google Cloud.\n";
} else {
    $memeRegion = strcasecmp($reelle, $attendue) === 0;
    $canadienne = in_array(strtolower($reelle), ImageStorageService::LOCATIONS_CANADIENNES, true);
    echo "Region reelle    : {$reelle} " . ($memeRegion ? '(conforme)' : '(DIFFERENTE de l attendue)') . "\n";
    if (!$canadienne) {
        echo "\n  ATTENTION : cette region n'est pas canadienne. Tant qu'elle ne\n";
        echo "  l'est pas, la phrase « vos donnees restent au Canada » du site\n";
        echo "  est fausse et doit rester masquee.\n";
    }
}
echo "\n";

// ------------------------------------------------------------- recus
$requete = ListReceipt::withTrashed()
    ->where(function ($q) {
        $q->whereNotNull('image_path')->where('image_path', '<>', '')
          ->orWhere(function ($q2) {
              $q2->whereNotNull('image_url')->where('image_url', '<>', '');
          });
    })
    ->orderBy('id');

if ($limite > 0) {
    $requete->limit($limite);
}

$recus = $requete->get();
echo "Recus avec une photo : " . $recus->count() . "\n\n";

$prives = 0;
$deja = 0;
$echecs = 0;
$sansCle = 0;
$uniforme = false;

foreach ($recus as $recu) {
    $cle = $recu->cleDeLImage($stockage);
    if ($cle === null) {
        $sansCle++;
        echo "  [#{$recu->id}] valeur illisible, ignoree\n";
        continue;
    }

    // La colonne image_path peut manquer si la migration 015 n'a pas
    // tourne : on la remplit au passage, c'est le meme travail.
    $cleManquante = trim((string) $recu->image_path) === '';

    if (!$appliquer) {
        echo "  [#{$recu->id}] {$cle}"
            . ($cleManquante ? '  (+ image_path a remplir)' : '')
            . "\n";
        $prives++;
        continue;
    }

    try {
        $stockage->rendrePrive($cle);
        $prives++;

        $recu->image_path = $cle;
        // L'URL publique ne mene plus nulle part : la laisser ferait
        // afficher une image cassee aux applications d'avant, au lieu
        // de « pas de photo ».
        $recu->image_url = null;
        $recu->save();

        echo "  [#{$recu->id}] prive\n";
    } catch (\RuntimeException $e) {
        // Bucket en acces uniforme : inutile d'insister objet par objet.
        $uniforme = true;
        echo "\n  " . $e->getMessage() . "\n";
        break;
    } catch (\Throwable $e) {
        $echecs++;
        echo "  [#{$recu->id}] ECHEC : " . $e->getMessage() . "\n";
    }
}

echo "\n=== Resume ===\n";
echo ($appliquer ? "Rendus prives    : " : "A rendre prives  : ") . $prives . "\n";
echo "Deja prives      : {$deja}\n";
echo "Valeurs illisibles: {$sansCle}\n";
echo "Echecs           : {$echecs}\n";

if ($uniforme) {
    echo "\nLe bucket est en ACCES UNIFORME : il n'y a pas d'ACL par objet.\n";
    echo "La lecture publique vient du bucket lui-meme. A faire a la main,\n";
    echo "dans la console Google Cloud ou avec gcloud :\n\n";
    echo "  gcloud storage buckets remove-iam-policy-binding gs://"
        . $stockage->nomDuBucket() . " \\\n";
    echo "    --member=allUsers --role=roles/storage.objectViewer\n\n";
    echo "ATTENTION : cela rend AUSSI prives les avatars et les photos de\n";
    echo "produits, qui sont servis par URL publique. Ne le faire qu'apres\n";
    echo "avoir decide de leur sort (voir le resume de la phase 1).\n";
    exit(1);
}

if (!$appliquer) {
    echo "\nRelancer avec --apply pour agir.\n";
}
exit($echecs > 0 ? 1 : 0);
