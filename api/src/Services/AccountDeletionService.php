<?php
// src/Services/AccountDeletionService.php — supprimer un compte pour de bon.
//
// Avant ce service, « supprimer mon compte » posait is_active = 0 et
// deleted_at, puis l'API repondait « Compte supprime avec succes ». La
// ligne users restait entiere — courriel, prenom, nom, empreinte du mot
// de passe — avec les listes, les recus, les budgets et les images. Ce
// n'etait pas une suppression, c'etait une desactivation.
//
// Ce que fait ce service, en une seule transaction :
//
//   1. il rend les listes et les espaces PARTAGES a ceux qui restent ;
//   2. il detruit ce que personne d'autre n'utilise ;
//   3. il re-attribue les messages de clavardage a « Utilisateur
//      supprime », pour ne pas trouer la conversation des autres ;
//   4. il vide la ligne users de tout ce qui identifie la personne ;
//   5. il efface ses images du stockage (recus, photos d'articles,
//      avatar), une fois la transaction validee.
//
// DEUX PRINCIPES guident les cas ambigus :
//
//   - ce qui est a la personne part avec elle. Historique d'achats,
//     habitudes, preferences, appareils, jetons : detruits, sans
//     condition, meme dans un espace partage.
//
//   - ce qui est au groupe reste au groupe. Une liste de foyer, un
//     inventaire, un budget d'espace : repris par un membre qui a le
//     droit de l'administrer, sinon detruit. Jamais laisse sans
//     proprietaire : plusieurs cles etrangeres sont en ON DELETE
//     CASCADE depuis users, donc une ligne encore rattachee a la
//     personne disparaitrait a la purge des trente jours, en emportant
//     le travail des autres.
//
// Un repreneur est le membre ACTIF le plus ANCIEN qui peut administrer
// la chose. L'anciennete plutot que le hasard : c'est le membre le plus
// susceptible d'etre encore la, et le choix est explicable a quiconque
// le demande.

namespace App\Services;

use App\Models\SharedList;
use App\Models\ShoppingList;
use App\Models\Space;
use App\Models\SpaceMember;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Capsule\Manager as DB;

class AccountDeletionService
{
    /**
     * Tables rattachees a un espace : la ligne appartient au groupe, pas
     * a la personne. Elle survit si l'espace survit, et change alors de
     * main. Valeur = colonnes qui pointent vers un utilisateur ; la
     * PREMIERE est la colonne de propriete (celle qui decide d'une
     * suppression), les suivantes ne sont que de l'attribution.
     */
    private const TABLES_DE_GROUPE = [
        'budgets'         => ['user_id', 'created_by_user_id'],
        'home_inventory'  => ['user_id', 'created_by_user_id'],
        'meal_plans'      => ['user_id', 'created_by_user_id'],
        'recurring_lists' => ['user_id', 'created_by_user_id'],
        'stores'          => ['user_id', 'created_by_user_id'],
        'recipes'         => ['user_id', 'created_by_user_id'],
        'product_aliases' => ['user_id'],
        'price_alerts'    => ['created_by_user_id'],
        'suppliers'       => ['created_by_user_id'],
    ];

    /**
     * Tables purement personnelles : detruites sans condition. Ce sont
     * les habitudes, les preferences et les moyens de connexion ; rien
     * la-dedans n'a de sens pour quelqu'un d'autre, et tout y est
     * identifiant.
     */
    private const TABLES_PERSONNELLES = [
        'purchase_history'          => 'user_id',
        'user_purchase_patterns'    => 'user_id',
        'product_prediction_prefs'  => 'user_id',
        'product_suggestions'       => 'user_id',
        'suggestion_feedback'       => 'user_id',
        'recipe_favorites'          => 'user_id',
        'store_favorites'           => 'user_id',
        'categories'                => 'user_id',
        'email_preferences'         => 'user_id',
        'user_devices'              => 'user_id',
        'refresh_tokens'            => 'user_id',
        'user_sso_links'            => 'user_id',
        'message_read_status'       => 'user_id',
        'space_activities'          => 'user_id',
        'space_invitations'         => 'invited_by',
    ];

    private ?ImageStorageService $stockage;

    /**
     * @param ImageStorageService|null $stockage injectable pour les tests ;
     *        sans lui, le service en construit un a la demande. Une
     *        configuration de stockage absente n'empeche PAS la
     *        suppression : les cles d'images sont alors rendues dans le
     *        rapport sous « images_non_supprimees », a reprendre avec
     *        scripts/backfill_deleted_accounts.php.
     */
    public function __construct(?ImageStorageService $stockage = null)
    {
        $this->stockage = $stockage;
    }

    /**
     * Supprime un compte. Idempotent : un compte deja anonymise est
     * rendu tel quel, sans rien retoucher.
     *
     * @param string $origine 'app' ou 'web' — trace dans le journal.
     * @return array rapport chiffre (ce qui a ete transfere, detruit,
     *               re-attribue, et ce qui a resiste)
     */
    public function supprimer(User $user, string $origine = 'app'): array
    {
        if ($user->estReserve()) {
            throw new \RuntimeException('La ligne reservee « Utilisateur supprime » ne se supprime pas.');
        }

        if ($user->estAnonymise()) {
            return $this->rapportVide(['deja_anonymise' => true, 'user_id' => $user->id]);
        }

        $reserveId = User::reserve()->id;
        $rapport = $this->rapportVide(['user_id' => $user->id, 'origine' => $origine]);
        $images = [];

        DB::connection()->transaction(function () use ($user, $reserveId, &$rapport, &$images) {
            $this->traiterEspaces($user, $rapport, $images);
            $this->traiterListes($user, $rapport, $images);
            $this->traiterTablesDeGroupe($user, $reserveId, $rapport);
            $this->traiterTablesPersonnelles($user, $rapport);
            $this->reattribuerContributions($user, $reserveId, $rapport);

            $avatar = $user->avatar_url;
            if (is_string($avatar) && $avatar !== '') {
                $images[] = $avatar;
            }

            $user->anonymizeData();

            // Un compte deja marque supprime garde SA date : un
            // rattrapage ne doit pas relancer le delai de trente jours
            // pour quelqu'un qui est parti il y a six mois.
            if ($user->deleted_at === null) {
                $user->delete(); // soft delete : la ligne part a la purge
            }
        });

        $rapport['images_vues'] = count($images);
        $rapport = $this->effacerImages($images, $rapport);

        error_log(sprintf(
            '[AccountDeletion] compte #%d supprime (origine %s) : %d liste(s) detruite(s), %d transferee(s), %d espace(s) transfere(s), %d message(s) re-attribue(s), %d image(s) effacee(s)',
            $rapport['user_id'],
            $origine,
            $rapport['listes_supprimees'],
            $rapport['listes_transferees'],
            $rapport['espaces_transferes'],
            $rapport['messages_reattribues'],
            $rapport['images_supprimees']
        ));

        return $rapport;
    }

    // ===================== ESPACES =====================

    /**
     * Les espaces dont la personne est proprietaire.
     *
     * spaces.owner_user_id est en ON DELETE CASCADE : laisser l'espace a
     * son nom le ferait disparaitre a la purge, avec les listes et
     * l'inventaire de tout le foyer. Il change donc de main maintenant,
     * ou il est detruit s'il ne reste personne.
     */
    private function traiterEspaces(User $user, array &$rapport, array &$images): void
    {
        foreach (Space::where('owner_user_id', $user->id)->get() as $espace) {
            $successeur = $this->successeurDEspace((int) $espace->id, (int) $user->id);

            if ($successeur === null) {
                // L'espace part, mais PAS ses listes d'un bloc : une
                // liste rangee dans un espace vide peut tres bien etre
                // partagee, par shared_list, avec quelqu'un qui n'est
                // pas de l'espace. Les detruire ici lui retirerait ses
                // courses sans le prevenir. Chaque liste est donc
                // examinee une par une juste apres, par traiterListes(),
                // qui regarde d'abord les partages.
                //
                // Les tables rattachees a l'espace tombent avec lui :
                // space_members, space_activities, space_invitations,
                // purchase_requests et suppliers sont en CASCADE ; les
                // autres sont reprises par la passe « tables de
                // groupe » (espace non survivant = suppression).
                $espace->delete();
                $rapport['espaces_supprimes']++;
                continue;
            }

            DB::table('spaces')->where('id', $espace->id)
                ->update(['owner_user_id' => $successeur, 'updated_at' => Carbon::now()]);

            DB::table('space_members')
                ->where('space_id', $espace->id)
                ->where('user_id', $successeur)
                ->update(['role' => SpaceMember::ROLE_OWNER, 'updated_at' => Carbon::now()]);

            $rapport['espaces_transferes']++;
            $rapport['successeurs'][(int) $espace->id] = $successeur;
        }

        // Ses propres appartenances : ce sont ses liens, ils partent.
        $rapport['appartenances_retirees'] = DB::table('space_members')
            ->where('user_id', $user->id)->delete();
    }

    /**
     * Le membre actif le plus ancien qui peut administrer l'espace.
     *
     * Ordre des roles : admin, puis manager, puis member. Un « viewer »
     * n'est jamais promu : il n'a pas demande a gerer un foyer, et le
     * promouvoir lui donnerait acces a des budgets qu'il ne voyait pas.
     */
    private function successeurDEspace(int $spaceId, int $sortantId): ?int
    {
        $roles = [SpaceMember::ROLE_ADMIN, SpaceMember::ROLE_MANAGER, SpaceMember::ROLE_MEMBER];

        foreach ($roles as $role) {
            $candidat = DB::table('space_members')
                ->where('space_id', $spaceId)
                ->where('status', SpaceMember::STATUS_ACTIVE)
                ->where('user_id', '<>', $sortantId)
                ->where('role', $role)
                ->whereIn('user_id', $this->idsDeComptesVivants())
                ->orderByRaw('COALESCE(joined_at, created_at) ASC')
                ->value('user_id');

            if ($candidat !== null) {
                return (int) $candidat;
            }
        }

        return null;
    }

    // ===================== LISTES =====================

    /**
     * Les listes dont la personne est proprietaire, une par une.
     *
     * Partagee et reprenable : elle change de main. Sinon : detruite.
     * Une liste dont les seuls autres membres sont en lecture seule est
     * donc detruite, et c'est le choix volontaire — personne ne peut
     * l'entretenir, et la garder reviendrait a conserver les courses
     * d'une personne partie au nom de spectateurs.
     */
    private function traiterListes(User $user, array &$rapport, array &$images): void
    {
        foreach (ShoppingList::withTrashed()->where('user_id', $user->id)->get() as $liste) {
            $repreneur = $this->repreneurDeListe($liste, (int) $user->id, $rapport);

            if ($repreneur === null) {
                $this->collecterImagesDeLaListe((int) $liste->id, $images);
                $this->detruireListe((int) $liste->id);
                $rapport['listes_supprimees']++;
                continue;
            }

            $maj = [
                'user_id' => $repreneur,
                'created_by_user_id' => $repreneur,
                'updated_at' => Carbon::now(),
            ];

            // Une liste rangee dans un espace n'est atteignable QUE par
            // les membres de cet espace : ListAccessService::
            // checkSharedSpace refuse l'acces, sans repli vers la regle
            // du proprietaire, des que l'espace a disparu ou que la
            // personne n'en est pas membre. Transferer la liste sans y
            // regarder la rendait donc invisible pour tout le monde, y
            // compris pour son nouveau proprietaire. Elle quitte
            // l'espace quand celui-ci ne peut plus lui servir de porte.
            if ($liste->space_id !== null && !$this->espaceOuvreLaPorte((int) $liste->space_id, $repreneur)) {
                $maj['space_id'] = null;
                $rapport['listes_detachees']++;
            }

            DB::table('shopping_lists')->where('id', $liste->id)->update($maj);

            // Le partage du repreneur n'a plus d'objet : il est chez lui.
            DB::table('shared_list')
                ->where('list_id', $liste->id)
                ->where('shared_with_user_id', $repreneur)
                ->delete();

            DB::table('shared_list')->where('list_id', $liste->id)
                ->update(['owner_id' => $repreneur, 'updated_at' => Carbon::now()]);

            // Un budget attache a cette liste suit la liste, sinon le
            // nouveau proprietaire herite d'une liste sans son budget.
            $rapport['budgets_transferes'] += DB::table('budgets')
                ->where('list_id', $liste->id)
                ->where('user_id', $user->id)
                ->update([
                    'user_id' => $repreneur,
                    'created_by_user_id' => $repreneur,
                    'updated_at' => Carbon::now(),
                ]);

            $rapport['listes_transferees']++;
        }

        // Les listes des AUTRES partagees avec lui : seul son lien part.
        $rapport['partages_retires'] = DB::table('shared_list')
            ->where('shared_with_user_id', $user->id)->delete();
    }

    /**
     * Qui peut reprendre cette liste ?
     *
     * D'abord un partage accepte avec droit d'ecriture (admin, puis
     * edit), le plus ancien. Ensuite, si la liste vit dans un espace,
     * le successeur de cet espace.
     */
    private function repreneurDeListe(ShoppingList $liste, int $sortantId, array $rapport): ?int
    {
        foreach ([SharedList::PERMISSION_ADMIN, SharedList::PERMISSION_EDIT] as $permission) {
            $candidat = DB::table('shared_list')
                ->where('list_id', $liste->id)
                ->where('status', SharedList::STATUS_ACCEPTED)
                ->where('shared_with_user_id', '<>', $sortantId)
                ->where('permission', $permission)
                ->whereNull('deleted_at')
                ->whereIn('shared_with_user_id', $this->idsDeComptesVivants())
                ->orderByRaw('COALESCE(accepted_at, created_at) ASC')
                ->value('shared_with_user_id');

            if ($candidat !== null) {
                return (int) $candidat;
            }
        }

        if ($liste->space_id !== null) {
            return $rapport['successeurs'][(int) $liste->space_id]
                ?? $this->successeurDEspace((int) $liste->space_id, $sortantId);
        }

        return null;
    }

    /**
     * L'espace existe-t-il encore, et ce membre y est-il actif ?
     *
     * Les deux conditions comptent : un espace supprime ne donne acces a
     * rien, et un repreneur venu d'un simple partage de liste n'est pas
     * membre de l'espace.
     */
    private function espaceOuvreLaPorte(int $spaceId, int $userId): bool
    {
        $vivant = DB::table('spaces')
            ->where('id', $spaceId)
            ->whereNull('deleted_at')
            ->exists();

        if (!$vivant) {
            return false;
        }

        return DB::table('space_members')
            ->where('space_id', $spaceId)
            ->where('user_id', $userId)
            ->where('status', SpaceMember::STATUS_ACTIVE)
            ->exists();
    }

    /**
     * Detruit une liste et tout ce qui pend dessous.
     *
     * list_items n'a pas de cascade (NO ACTION) : il part a la main,
     * avant la liste. list_messages, list_receipts et receipt_items
     * suivent par cascade ; purchase_history.list_id passe a NULL.
     * shared_list et budgets n'ont pas de contrainte : explicitement.
     */
    private function detruireListe(int $listId): void
    {
        DB::table('budgets')->where('list_id', $listId)->delete();
        DB::table('shared_list')->where('list_id', $listId)->delete();
        DB::table('list_items')->where('list_id', $listId)->delete();
        DB::table('shopping_lists')->where('id', $listId)->delete();
    }

    /** Les cles ou URL d'images portees par une liste. */
    private function collecterImagesDeLaListe(int $listId, array &$images): void
    {
        $recus = DB::table('list_receipts')->where('list_id', $listId)
            ->select('image_path', 'image_url')->get();

        foreach ($recus as $recu) {
            $cle = $recu->image_path ?: $recu->image_url;
            if (is_string($cle) && $cle !== '') {
                $images[] = $cle;
            }
        }

        $articles = DB::table('list_items')->where('list_id', $listId)
            ->whereNotNull('image_url')->pluck('image_url');

        foreach ($articles as $url) {
            if (is_string($url) && $url !== '') {
                $images[] = $url;
            }
        }
    }

    // ===================== LE RESTE DES DONNEES =====================

    /**
     * Tables de groupe : reprise par le successeur quand l'espace
     * survit, destruction sinon.
     */
    private function traiterTablesDeGroupe(User $user, int $reserveId, array &$rapport): void
    {
        foreach ($rapport['successeurs'] as $spaceId => $successeur) {
            foreach (self::TABLES_DE_GROUPE as $table => $colonnes) {
                foreach ($colonnes as $colonne) {
                    $rapport['lignes_transferees'] += DB::table($table)
                        ->where('space_id', $spaceId)
                        ->where($colonne, $user->id)
                        ->update([$colonne => $successeur]);
                }
            }
        }

        // Ce qui reste a son nom n'est dans aucun espace survivant.
        foreach (self::TABLES_DE_GROUPE as $table => $colonnes) {
            $proprietaire = $colonnes[0];
            $rapport['lignes_supprimees'] += DB::table($table)
                ->where($proprietaire, $user->id)->delete();
        }

        // Des lignes creees par lui dans les affaires des autres :
        // l'attribution passe a « Utilisateur supprime », la ligne reste.
        foreach (self::TABLES_DE_GROUPE as $table => $colonnes) {
            foreach (array_slice($colonnes, 1) as $colonne) {
                $rapport['lignes_reattribuees'] += DB::table($table)
                    ->where($colonne, $user->id)->update([$colonne => $reserveId]);
            }
        }
    }

    /** Ses habitudes, ses preferences, ses appareils, ses jetons. */
    private function traiterTablesPersonnelles(User $user, array &$rapport): void
    {
        foreach (self::TABLES_PERSONNELLES as $table => $colonne) {
            $rapport['lignes_personnelles_supprimees'] += DB::table($table)
                ->where($colonne, $user->id)->delete();
        }
    }

    /**
     * Les traces laissees chez les autres.
     *
     * Les messages de clavardage ne sont pas effaces : ils appartiennent
     * a la conversation d'une liste, et les retirer trouerait
     * l'historique de ceux qui restent (« a qui je reponds ? »). Leur
     * AUTEUR devient « Utilisateur supprime ». Le reste — qui a cree,
     * qui a achete — passe au meme auteur, sinon la purge des trente
     * jours emporterait des lignes par cascade.
     */
    private function reattribuerContributions(User $user, int $reserveId, array &$rapport): void
    {
        $rapport['messages_reattribues'] = DB::table('list_messages')
            ->where('user_id', $user->id)->update(['user_id' => $reserveId]);

        foreach (['created_by_user_id', 'purchased_by_user_id'] as $colonne) {
            $rapport['articles_reattribues'] += DB::table('list_items')
                ->where($colonne, $user->id)->update([$colonne => $reserveId]);
        }

        $rapport['lignes_reattribuees'] += DB::table('shopping_lists')
            ->where('created_by_user_id', $user->id)->update(['created_by_user_id' => $reserveId]);

        $rapport['lignes_reattribuees'] += DB::table('purchase_request_events')
            ->where('user_id', $user->id)->update(['user_id' => $reserveId]);

        $rapport['lignes_reattribuees'] += DB::table('product_images')
            ->where('created_by_user_id', $user->id)->update(['created_by_user_id' => $reserveId]);

        // Les journaux d'erreurs techniques perdent le lien, pas la ligne :
        // ils servent a diagnostiquer, pas a identifier.
        $rapport['journaux_anonymises'] = DB::table('api_error_logs')
            ->where('user_id', $user->id)->update(['user_id' => null]);
    }

    // ===================== IMAGES =====================

    /**
     * Efface les objets du stockage, apres la transaction.
     *
     * Dans cet ordre, et pas l'inverse : si le stockage repond mal, des
     * objets survivent a leurs lignes (recuperables par un script), ce
     * qui vaut mieux que des lignes pointant vers des images effacees.
     */
    private function effacerImages(array $images, array $rapport): array
    {
        if ($images === []) {
            return $rapport;
        }

        try {
            $stockage = $this->stockage ?? new ImageStorageService();
        } catch (\Throwable $e) {
            $rapport['images_non_supprimees'] = array_values(array_unique($images));
            error_log('[AccountDeletion] stockage indisponible : ' . $e->getMessage());
            return $rapport;
        }

        foreach (array_unique($images) as $cle) {
            try {
                $stockage->deleteByUrl($cle);
                $rapport['images_supprimees']++;
            } catch (\Throwable $e) {
                $rapport['images_non_supprimees'][] = $cle;
                error_log('[AccountDeletion] image non supprimee (' . $cle . ') : ' . $e->getMessage());
            }
        }

        return $rapport;
    }

    // ===================== OUTILS =====================

    /**
     * Les comptes encore utilisables. Un repreneur doit pouvoir se
     * connecter : transferer une liste a un compte lui-meme supprime la
     * ferait disparaitre au prochain passage.
     */
    private function idsDeComptesVivants(): \Illuminate\Database\Query\Builder
    {
        return DB::table('users')
            ->select('id')
            ->whereNull('deleted_at')
            ->whereNull('anonymized_at')
            ->where('is_active', 1);
    }

    private function rapportVide(array $base = []): array
    {
        return array_merge([
            'user_id' => 0,
            'origine' => 'app',
            'deja_anonymise' => false,
            'espaces_transferes' => 0,
            'espaces_supprimes' => 0,
            'appartenances_retirees' => 0,
            'listes_transferees' => 0,
            'listes_detachees' => 0,
            'listes_supprimees' => 0,
            'partages_retires' => 0,
            'budgets_transferes' => 0,
            'lignes_transferees' => 0,
            'lignes_supprimees' => 0,
            'lignes_reattribuees' => 0,
            'lignes_personnelles_supprimees' => 0,
            'messages_reattribues' => 0,
            'articles_reattribues' => 0,
            'journaux_anonymises' => 0,
            'images_vues' => 0,
            'images_supprimees' => 0,
            'images_non_supprimees' => [],
            'successeurs' => [],
            'apple' => self::etatRevocationApple(),
        ], $base);
    }

    /**
     * Revocation Sign in with Apple : pas possible avec la configuration
     * actuelle, et le dire est plus utile que de faire semblant.
     *
     * Apple demande POST https://appleid.apple.com/auth/revoke avec un
     * client_secret (JWT signe par une cle .p8) ET un jeton de
     * rafraichissement obtenu a la connexion. Or l'application envoie
     * son authorizationCode a Firebase, jamais a cette API : aucun jeton
     * de rafraichissement n'existe de notre cote. Voir README.md,
     * section « Revocation Apple ».
     */
    public static function etatRevocationApple(): string
    {
        return 'non_configure';
    }
}
