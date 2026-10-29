<?php
// src/Services/NotificationTexts.php — le texte d'une notification,
// dans la langue de CELUI QUI LA RECOIT.
//
// Jusqu'ici, le corps du message etait ecrit en francais, en dur, dans
// le controleur : ListItemController posait
// « "Pain" a ete ajoute a la liste » et NotificationService le
// transmettait tel quel. Un membre anglophone d'un foyer bilingue
// recevait donc toutes ses notifications en francais, alors que toute
// l'application et tous les courriels sont traduits.
//
// La correction tient en un deplacement : le controleur ne compose plus
// de phrase, il nomme un EVENEMENT et ses parametres. La phrase est
// fabriquee au dernier moment, une fois par destinataire, dans sa
// langue a lui.
//
// Les cles sont stables : elles traversent le fichier d'attente des
// notifications groupees (storage/list_update_cooldowns). Changer un
// nom de cle casserait les regroupements en vol — ajouter une cle, non.

namespace App\Services;

class NotificationTexts
{
    /** Langue de repli quand celle du destinataire est inconnue. */
    public const LANGUE_PAR_DEFAUT = 'fr';

    /**
     * Un evenement par cle, deux langues par evenement.
     *
     * Les parametres sont ecrits {entre_accolades} et remplaces tels
     * quels : aucune logique de pluriel au-dela de ce que les textes
     * portent eux-memes.
     */
    private const TEXTES = [
        // Un seul changement, notifie tout de suite.
        'item_added' => [
            'fr' => '« {produit} » a été ajouté à la liste',
            'en' => '“{produit}” was added to the list',
        ],
        'item_purchased' => [
            'fr' => '« {produit} » a été acheté',
            'en' => '“{produit}” was bought',
        ],
        'all_purchased' => [
            'fr' => 'Tous les articles ont été achetés ✅',
            'en' => 'Everything has been bought ✅',
        ],

        // Plusieurs changements pendant la fenetre de regroupement.
        // Avant, ils etaient simplement PERDUS : le verrou de trois
        // minutes rendait « skipped » et personne n'apprenait rien.
        'group_items_added' => [
            'fr' => '{acteur} a ajouté {nombre} articles',
            'en' => '{acteur} added {nombre} items',
        ],
        'group_items_purchased' => [
            'fr' => '{acteur} a coché {nombre} articles',
            'en' => '{acteur} checked off {nombre} items',
        ],
        'group_changes' => [
            'fr' => '{nombre} changements sur cette liste',
            'en' => '{nombre} changes on this list',
        ],
        'group_changes_actor' => [
            'fr' => '{acteur} a fait {nombre} changements',
            'en' => '{acteur} made {nombre} changes',
        ],
    ];

    /**
     * La phrase d'un evenement, dans une langue donnee.
     *
     * Une cle inconnue rend une chaine vide plutot qu'une exception :
     * une notification ratee ne doit pas faire echouer l'ajout d'un
     * article. L'appelant verifie et renonce.
     */
    public static function rendre(string $cle, array $params = [], ?string $langue = null): string
    {
        $langue = self::langueValide($langue);
        $modele = self::TEXTES[$cle][$langue] ?? self::TEXTES[$cle][self::LANGUE_PAR_DEFAUT] ?? '';

        if ($modele === '') {
            error_log("[NotificationTexts] cle inconnue : {$cle}");
            return '';
        }

        foreach ($params as $nom => $valeur) {
            $modele = str_replace('{' . $nom . '}', (string) $valeur, $modele);
        }

        return $modele;
    }

    /** 'fr' ou 'en', rien d'autre. */
    public static function langueValide(?string $langue): string
    {
        return in_array($langue, ['fr', 'en'], true) ? $langue : self::LANGUE_PAR_DEFAUT;
    }

    /** Vrai si la cle existe — utile avant de mettre un evenement en attente. */
    public static function existe(string $cle): bool
    {
        return isset(self::TEXTES[$cle]);
    }
}
