# EpiList — ce qui a changé, et ce qu'il reste à faire

**Date :** 29 octobre 2026
**Point de départ :** `AUDIT_MARKETING_EPILIST.md`, commit `3de47fd`
**Six branches, une par phase**, aucune poussée :

| Branche | Phase |
|---|---|
| `fix/p1-recus-prives` | Photos de reçus privées |
| `fix/p2-suppression-compte` | Vraie suppression de compte |
| `fix/p3-site-confidentialite` | Nettoyage du site et de la politique |
| `fix/p4-boucle-invitation` | Boucle d'invitation |
| `fix/p5-onboarding-court` | Onboarding court |
| `fix/p6-mesure-consentement` | Mesure et consentement |

Chaque branche part de la précédente : **elles se fusionnent dans
l'ordre**, de 1 à 6.

---

## 1. Ce que chaque phase a changé

### Phase 1 — Les photos de reçus ne sont plus publiques

Un reçu porte le magasin, la date, les montants. Il était téléversé en
`predefinedAcl => publicRead` : l'URL suffisait à le lire, sans compte
et sans jeton. « Non devinable » n'est pas « privé » — une URL fuit par
un partage d'écran, un presse-papier, un journal de serveur mandataire.

Désormais : objet privé, la base garde la **clé** et non l'URL, et
l'application demande une **URL signée de quinze minutes** à qui a le
droit de voir la liste. Un étranger reçoit 403, et il le reçoit **avant**
toute vérification d'existence — sinon il apprendrait quels reçus
existent en comparant les codes.

*Avatars et photos de produits restent publics* : le choix vous
appartient, et les basculer demanderait une route signée de plus. Si le
bucket est en accès uniforme, les trois partiront ensemble ou pas du
tout (le script vous le dira).

### Phase 2 — « Supprimer mon compte » supprime le compte

Trois défauts empilés : la route de confirmation attendait `email` +
`confirmation_code` quand l'application envoie `deletion_code`, elle
lisait deux colonnes absentes de la base, et même si elle avait abouti
elle n'aurait fait qu'un `is_active = 0`. **Personne ne pouvait
supprimer son compte**, et l'API répondait « Compte supprimé avec
succès ».

Maintenant, à la confirmation : anonymisation immédiate, destruction des
données personnelles, **transfert** des listes et espaces partagés au
membre actif le plus ancien qui peut les administrer, messages de
clavardage signés « Utilisateur supprimé », images effacées du stockage.
La ligne vide part à la purge des trente jours. L'ancienne adresse
redevient disponible.

Une page publique `/suppression-compte` (et `/en/delete-account`) pour
qui n'a plus l'application — exigence des deux magasins.

**Révocation Sign in with Apple : pas faisable**, et `api/README.md` dit
exactement ce qui manque (clé `.p8`, Key ID, Team ID, et surtout un
jeton de rafraîchissement qu'on n'obtient jamais puisque
l'`authorizationCode` part chez Firebase et non chez nous).

### Phase 3 — Le site ne dit plus que ce qu'il peut prouver

Partis : « plus de 50 000 familles », « 70 % de temps économisé »,
« 30 % d'économies », « 100 % de synchronisation », « ∞ insights »,
« 24/7 », « AES-256 », « audits de sécurité réguliers », « 150+
devises », et **83 clés mortes**. Parti aussi l'`aggregateRating` du
JSON-LD — note 4,9 sur 1247 avis, envoyée à Google, qui interdit
précisément cela.

Les cinq témoignages étaient des personnages. La section reste, vide,
avec la place d'un vrai témoignage **et la date de l'accord écrit**.

« Synchronisation temps réel » devient « notifications instantanées »
partout : il n'y a aucun websocket dans ce dépôt.

Politique de confidentialité réécrite, douze sections, FR et EN, dans le
site **et** dans l'application — avec trois sections qui n'existaient
pas : les reçus, la suppression du compte, la mesure d'audience.

« EpiList Inc. » n'existe pas, y compris dans la clause de limitation de
responsabilité : c'est **M2atech Solutions Inc.**

### Phase 4 — Une invitation ramène enfin quelqu'un

`assetlinks.json` n'existait pas alors que le manifeste Android demande
`autoVerify` : **un lien de partage n'ouvrait jamais l'application sur
Android**. Le fichier existe, avec la vraie empreinte de votre clé
d'importation ; celle de la clé de signature Play **reste à remplir**.

Chaque partage porte un **code de six caractères** (sans 0, O, 1, I, L).
C'est le seul chemin qui survit au passage par le magasin. La page de
partage ne jette plus les ordinateurs vers l'App Store : deux magasins,
un QR code, et le code.

Côté application : le jeton tient sur le disque, le referrer de Google
Play est lu au premier lancement, et « J'ai un code d'invitation » est
sur l'écran de bienvenue et après l'inscription.

### Phase 5 — Cinq gestes au lieu de quatorze

Google et Apple passent devant ; le nom de famille et la confirmation du
mot de passe disparaissent ; **la vérification du courriel ne bloque
plus l'entrée** — elle se déplace là où une adresse non prouvée ferait
des dégâts (activer la 2FA, envoyer une invitation par courriel).

Un parcours de trois écrans, chacun avec « Passer », qui ne se montre
qu'une fois (drapeau **serveur**).

Et les notifications : chacun les reçoit **dans sa langue** (elles
partaient en français pour tout le monde), et le verrou de trois minutes
ne **jette** plus rien — les changements rapprochés sont résumés
(« Marie a ajouté 4 articles »).

### Phase 6 — Mesurer, avec consentement

L'application n'avait **aucun** outil de mesure. Elle en a un, qui
refuse tout contenu : un nom d'article, un montant, une adresse — le
paramètre est refusé et l'événement entier avec lui.

Le site chargeait GA, le pixel Meta et Hotjar **sans rien demander**,
pour un public canadien. Les traceurs ne sont plus montés avant le
choix, « Tout refuser » est à côté de « Tout accepter », et le choix se
change par « Gérer les témoins ».

`user_activity_days` donne enfin une vraie rétention — un identifiant et
une date, rien d'autre.

### Hors phases — deux choses trouvées en chemin

- **Les courriels de test partaient pour de vrai**, redirigés vers la
  boîte de développement mais bel et bien envoyés : chaque passage de la
  suite de tests consommait du quota. En développement, ils sont
  maintenant **écrits dans `api/storage/mails/`** et rien ne part.
- Le courriel de campagne pointait vers `app-fr.jpg`, image supprimée
  lors de la refonte du site : il montrait un cadre vide.

---

## 2. Les migrations, dans l'ordre

À coller **en entier** dans phpMyAdmin — les blocs `SET @c := … ;
PREPARE … EXECUTE` utilisent des variables de session et une exécution
ligne par ligne les perd. Toutes sont **idempotentes** (rejouables sans
risque) et portent leur bloc de retour en arrière en fin de fichier.

| Ordre | Fichier | Ce qu'elle fait | Vérification attendue |
|---|---|---|---|
| 1 | `015_recus_prives.sql` | `list_receipts.image_path`, conversion des URL en clés | `restent_a_convertir = 0`, `cles_mal_formees = 0` |
| 2 | `016_suppression_compte.sql` | `users.anonymized_at`, utilisateur réservé, `account_deletion_requests` | `reserve_conforme = 1` ; noter `comptes_a_rattraper` |
| 3 | `017_boucle_invitation.sql` | `shared_list.invite_code`, `users.signup_source` / `signup_share_id` | `index_unique = 1`, `colonnes_provenance = 2` |
| 4 | `018_onboarding.sql` | `users.onboarding_done_at`, exemption des comptes existants | `comptes_qui_verront_le_parcours = 0` |
| 5 | `019_jours_activite.sql` | table `user_activity_days` | `table_presente = 1`, `cle_etrangere = 1` |

> **La 016 est la seule qui mérite un coup d'œil au résultat** :
> `comptes_a_rattraper` vous dit combien de comptes « supprimés » sont
> restés entiers en base. C'est exactement ce que traite le script
> suivant.

---

## 3. Les scripts, dans l'ordre

**Tous sont en constat par défaut.** Ils listent, comptent, et n'écrivent
rien. Il faut `--apply` pour qu'ils agissent.

### a) Rendre les reçus déjà téléversés privés

```bash
cd api
php scripts/make_receipts_private.php            # constat
php scripts/make_receipts_private.php --apply    # agit
```

Il affiche aussi **la région réelle du bucket** et la compare à
`GCS_BUCKET_LOCATION`. S'il annonce un bucket en **accès uniforme**, il
s'arrête et donne la commande `gcloud` — mais attention, retirer la
lecture publique se fait alors au niveau du bucket et emporterait aussi
les avatars et les photos de produits. Dans ce cas, prévenez-moi avant.

### b) Rattraper les comptes supprimés d'avant

```bash
php scripts/backfill_deleted_accounts.php            # constat
php scripts/backfill_deleted_accounts.php --apply    # agit
```

À lancer **après** la migration 016. Il passe par le même service que
l'application : une seule logique de suppression à vérifier.

### c) La purge des trente jours

Elle vit dans `cron.php` (tâche 12), **en constat par défaut**. Pour
qu'elle efface vraiment :

```bash
# dans api/.env de production
PURGE_APPLY=true
```

Ou, pour un passage manuel :

```bash
php public/cron.php --purge-now            # constat
php public/cron.php --purge-now --apply    # efface
```

---

## 4. Les variables d'environnement

| Variable | Où | Valeur | Pourquoi |
|---|---|---|---|
| `GCS_BUCKET_LOCATION` | `api/.env` | `northamerica-northeast1` | région **attendue** du bucket ; sert à vérifier |
| `PURGE_APPLY` | `api/.env` | `true` | sans elle, la purge des trente jours ne fait que compter |
| `FRONTEND_URL` | `api/.env` | `https://epilist.app` | lien du courriel de suppression (retombe sur epilist.app sinon) |
| `MAIL_DEV_SEND` | `api/.env` **dev seulement** | absente | à `true`, les courriels de développement partent vraiment vers la boîte de test |
| `NEXT_PUBLIC_DATA_RESIDENCY_CANADA_CONFIRMED` | Vercel | `true` **une fois le bucket vérifié** | affiche « nos serveurs sont au Canada » |
| `NEXT_PUBLIC_TESTIMONIALS_ENABLED` | Vercel | `true` quand un vrai témoignage existe | rien ne s'affiche tant que la liste est vide |

---

## 5. Les actions manuelles — votre liste

### Console Google Cloud

1. **Vérifier la région du bucket `epilist-storage`.** Si elle n'est ni
   `northamerica-northeast1` ni `northamerica-northeast2`, la phrase
   « vos données restent au Canada » est fausse, et Google **ne déplace
   pas un bucket** : il faut en créer un autre et recopier. Tant que
   ce n'est pas vérifié, laissez le drapeau du site à `false`.
2. Vérifier que le compte de service a `storage.buckets.get` (sinon le
   script ne peut pas lire la région).

### Google Play Console

3. **Récupérer l'empreinte SHA-256 de la clé de signature de
   l'application** : *Test et publication → Intégrité de l'application →
   Certificat de la clé de signature de l'application*. La coller dans
   `web/public/.well-known/assetlinks.json`, à la place de
   `REMPLACER_PAR_...`. **Sans elle, les liens n'ouvrent toujours pas
   l'application.**
4. **Déclarer l'URL de suppression de compte** : *Contenu de l'app →
   Suppression du compte* → `https://epilist.app/suppression-compte`.
5. **Sécurité des données** : déclarer la collecte d'identifiants
   d'application (Firebase Analytics), **sans identifiant
   publicitaire**, avec possibilité de refus.
6. **Publier la version 2.2.1 (build 28)** qui cible déjà l'API 36 —
   échéance du **1er novembre**.

### App Store Connect

7. **Confidentialité de l'app** : « Données d'utilisation / Données de
   produit », **non liées à l'identité**, **non utilisées pour le
   suivi**. C'est cette dernière réponse qui vous dispense de l'ATT ; si
   elle change un jour, il faudra ajouter la fenêtre de permission.

### Google Analytics / Hotjar

8. **GA4 → Conservation des données → 14 mois** (2 mois par défaut, ce
   qui rend toute comparaison annuelle impossible).
9. **Hotjar → conservation → 12 mois**, et vérifier que la suppression
   du contenu des formulaires est active en plus de `data-hj-suppress`.

### Déploiement

10. **Le site doit partir AVANT l'application** (voir §7).
11. `cd web && vercel --prod` — à lancer vous-même : le classificateur
    me l'a refusé, et de toute façon le projet n'a jamais eu
    d'intégration Git (treize déploiements, tous manuels).

---

## 6. Les versions à publier

| Quoi | Version | Contient |
|---|---|---|
| Application iOS + Android | **2.2.1 (28)** — déjà construite | cible API 36, redesign Version B |
| Application iOS + Android | **2.3.0 (29)** — à construire | phases 1 à 6 : reçus privés, suppression réelle, invitations, onboarding, mesure |

La build 28 peut partir **tout de suite** (échéance Play du 1er
novembre). La build 29 demande que l'API et le site soient en ligne
d'abord.

> Deux greffons natifs ont été ajoutés (`play_install_referrer`,
> `firebase_analytics`) : la build 29 doit être **reconstruite**, pas
> ré-signée.

---

## 7. Ordre de déploiement, et pourquoi

**Le but : ne rien casser chez les gens qui ne mettront pas à jour.**
Beaucoup resteront des semaines sur la 2.2.1.

```
1. Migrations 015 → 019 (phpMyAdmin)
2. API (FTP master)
3. Site (vercel --prod)
4. Scripts : make_receipts_private, puis backfill_deleted_accounts
5. Application 2.3.0 (29) dans les magasins
```

### Ce qui protège les anciennes applications

| Changement | Pourquoi la 2.2.1 continue de marcher |
|---|---|
| Reçus privés | `list_receipts.image_url` **est conservée**. Les nouveaux reçus la mettent à `NULL` : une vieille application affiche « pas de photo », et non une image cassée. |
| Suppression de compte | La route accepte **les deux noms de champ** (`deletion_code` et `confirmation_code`). Avant, elle n'acceptait ni l'un ni l'autre correctement. |
| Code d'invitation | Les partages créés avant n'en ont pas ; leur **lien** fonctionne toujours. |
| Vérification non bloquante | Si l'API ne renvoie pas de jetons, l'application retombe sur l'ancien parcours. Et l'inverse : une 2.2.1 qui reçoit des jetons les ignore et demande le code, comme avant. |
| Parcours de départ | `onboarding_done` absent → l'application ne montre rien. |
| Notifications | La 2.2.1 affiche le corps envoyé par le serveur : elle recevra donc les nouveaux textes traduits, sans rien changer. |
| `last_name` facultatif | Les anciennes applications l'envoient encore ; l'API l'accepte toujours. |

**Le seul ordre qui compte vraiment** : le site **avant** l'application.
`assetlinks.json` n'est lu par Android qu'à l'installation ou à la mise
à jour — s'il n'est pas en ligne à ce moment-là, les liens de partage
resteront cassés jusqu'à la mise à jour suivante.

---

## 8. Ce que j'ai vérifié, et ce que je n'ai pas pu

### Vérifié

| | |
|---|---|
| Suites API | **280 vérifications**, 0 échec (10 suites) |
| Tests Flutter | **349**, tous verts |
| `flutter analyze` | aucun problème |
| `flutter build apk --debug` | réussi, avec les deux nouveaux greffons natifs |
| `npm run build` | réussi, 32 pages |
| Routes | 227, 0 cassée |
| Migrations | toutes jouées **deux fois** en local |
| `docs/metrics.sql` | les treize requêtes exécutées contre une vraie base |

### Pas pu

- **`make_receipts_private.php` n'a jamais tourné** : il lit le bucket de
  production, le classificateur l'a refusé, et vous avez dit que vous
  l'exécuteriez vous-même. Le téléversement privé n'est donc prouvé que
  par relecture de code — la signature V4, elle, est bien exercée par un
  test.
- **Aucun rattrapage de compte réel** : la base locale n'en contient
  aucun. Le chemin est éprouvé sur un compte fabriqué.
- **Rien n'a été validé sur un appareil réel.** C'est vous qui lancez
  l'application.
- **La révocation Apple** n'est pas faite, et ne peut pas l'être sans les
  éléments listés dans `api/README.md`.

---

## 9. Ce que je signale, sans l'avoir traité

1. **Les comptes jamais vérifiés** s'accumulent maintenant que la
   vérification ne bloque plus. Ils occupent une adresse que son
   propriétaire réel ne peut plus utiliser. Une purge après 30 jours
   sans vérification ni activité serait raisonnable — la mécanique
   existe déjà. **Je n'ai rien purgé de ma propre initiative.**
2. **« 150+ devises »** : la base locale en contient **25**. La requête
   de contrôle est dans `docs/metrics.sql` ; à lancer en production
   avant de réécrire un chiffre.
3. **La page de comparaison** affiche « 4,99 $/mois » pour les
   concurrents : invérifiable depuis le dépôt, et périssable.
4. **`npm run lint`** est cassé depuis avant ces phases
   (`Failed to load config "next/typescript"`). Le build reste le vrai
   garde-fou.
5. **`test_spaces_e2e.php`** échoue sur un mot de passe de fixture, déjà
   avant ces phases.
6. **La ligne réservée « Utilisateur supprimé »** compte comme un
   utilisateur dans la console d'administration (total décalé de 1).
7. **La fréquence du cron** décide du délai des résumés de
   notifications : toutes les 2 à 5 minutes serait le bon rythme.
