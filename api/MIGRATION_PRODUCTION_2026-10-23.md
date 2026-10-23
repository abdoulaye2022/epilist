# Mise en production — 23 octobre 2026

Migrations **013 et 014 (analyse du 23 octobre)** : sept colonnes,
quatre index, et une remise en cohérence des états d'inventaire déjà
enregistrés.

> **L'ordre n'est pas négociable.** Le code lit des colonnes que la base
> de production n'a pas encore. Si le code part avant le SQL, les écrans
> **À la maison**, **Budgets** et **Planifier mes repas** répondront 500,
> et le prix saisi en magasin ne s'enregistrera pas.

---

## Ce que la migration ajoute

| Table | Ajout | Pour quoi |
|---|---|---|
| `home_inventory` | `expires_at` | « À terminer dans 2 jours » |
| `home_inventory` | `level` | Plein / à moitié / presque vide, pour ce qui ne se compte pas |
| `list_items` | `price_is_estimate` | Le prix exact ou approximatif, saisi en magasin |
| `budgets` | `period_type` **+ `biweekly`** | La période de paie, aux deux semaines |
| `budgets` | `auto_renew`, `renewed_at` | Le budget qui se renouvelle tout seul |
| `email_preferences` | `price_alert_digest` | Un résumé hebdomadaire au lieu d'une alerte par produit |
| `recipes`, `recipe_ingredients` | 2 index | La recherche de recette par nom **ou par ingrédient** |
| `home_inventory` | `zone` *(014)* | Garde-manger, réfrigérateur, congélateur, entretien — le bloc où la provision s'affiche |

**Une seule écriture de données**, et elle corrige une incohérence :
quatre `UPDATE` remettent `home_inventory.status` d'accord avec la
quantité. C'est le cas de la capture — « Alerte rupture : il n'y en a
plus à la maison » affiché à côté de « Quantité restante : 2, pour un
seuil de 1 ». L'état était saisi à la main, la quantité aussi, et rien
ne les reliait.

Les `UPDATE` ne touchent **que** les lignes où une quantité existe, et
seulement celles que la quantité contredit. Un produit suivi sans
quantité garde l'état qu'on lui a donné.

**Durée** : moins d'une minute. **Risque** : faible.

---

## Étape 0 — Sauvegarder

- phpMyAdmin → onglet **Exporter** → méthode **personnalisée** →
  structure **et** données → compression gzip.

Sans cette sauvegarde, il n'y a pas de retour en arrière. Et cette
migration **écrit** dans `home_inventory` : c'est la première depuis
longtemps qui ne se contente pas d'ajouter des colonnes nulles.

---

## Étape 1 — Jouer les migrations

phpMyAdmin → base de production → onglet **SQL** → coller tout le
contenu de, **dans cet ordre** :

```
api/migrations/013_analyse_23_octobre.sql
api/migrations/014_zones_de_rangement.sql
```

Elle est **idempotente** : la rejouer ne casse rien et ne duplique
rien. Chaque ajout vérifie d'abord sa présence, et le `MODIFY` de
`period_type` ne s'exécute que si `biweekly` manque.

Attendu : 54 ordres pour la 013, 10 pour la 014, sans erreur. Les
lignes « déjà présente » sont normales sur une seconde exécution.

**Prérequis** : la migration 012 doit être passée (elle l'a été le
22 octobre). 013 n'y touche pas, mais le code qui suit en dépend.

---

## Étape 2 — Vérifier que tout est là (ne modifie rien)

Même onglet **SQL**, coller :

```
api/migrations/013_verification.sql
```

Que des `SELECT`. Lire la colonne **`verdict`** :

Ce fichier couvre **les deux** migrations : 45 lignes.

**Il n'y a qu'une ligne à lire : la dernière.** Elle rassemble tout —
les sept colonnes, les quatre index, la valeur d'enum, et les
incohérences restantes de l'inventaire :

```
EN UN MOT | tout est la | 7 colonnes sur 7, 4 index sur 4, 0 incoherence(s)
          | TOUT EST LA — le code peut partir
```

Tant qu'elle dit **« INCOMPLET »**, remonter dans le tableau et lire la
colonne `verdict` pour savoir où ça cloche. Dans phpMyAdmin, taper
`ECHEC` dans **« Filtrer les lignes »** au-dessus du résultat : zéro
ligne affichée = tout va bien.

Les quatre lignes du bloc **F** sont celles qui comptent les
incohérences restantes de l'inventaire, et doivent afficher
`0 ligne(s)`. Si l'une d'elles ne le dit pas, la migration n'a pas
tourné en entier — rejouer l'étape 1, elle est faite pour ça.

Tant qu'une ligne dit `ECHEC` ou `INCOMPLET` : **ne pas pousser le
code**.

---

## Étape 3 — Le cron (une ligne à ajouter, une fois)

Deux tâches nouvelles vivent dans `public/cron.php`, qui tourne déjà :

- **le renouvellement des budgets** (à chaque passage) ;
- **le résumé hebdomadaire des baisses de prix** (lundi, 9 h).

Si le cron horaire est en place, il n'y a **rien à faire** : les deux
tâches s'ajoutent d'elles-mêmes au passage suivant. Sinon, c'est la
même ligne que d'habitude :

```
0 * * * * curl -s "https://m2atodev.com/api.epilist/public/cron.php?key=VOTRE_CRON_SECRET"
```

Vérifier que `CRON_SECRET` est bien posé dans le `.env` de production :
sans lui, l'accès HTTP est refusé (c'est voulu).

---

## Étape 4 — Pousser (votre geste)

```
git push origin master
```

Le `push` déclenche le déploiement FTP. Onze commits partent — les dix
du travail, plus celui du présent carnet :

1. Les textes parlent à l'utilisatrice, les icônes disent leur section
2. Au magasin, l'article coché reste à sa place
3. À la maison : la quantité décide de l'état
4. Le prix s'entre au magasin, et le budget le voit
5. Le budget a une période, et deux phrases ne se contredisent plus
6. Une liste récurrente se modifie, et on sait ce qu'on modifie
7. La dictée découpe la phrase, et se vérifie avant d'ajouter
8. Après « Créer », la liste est sous les yeux
9. Les repas partent des jours, et on peut écrire le sien
10. Les magasins savent où ils sont, et combien il reste à y prendre

---

## Étape 5 — Vérifier l'API en production

```bash
# Racine : doit répondre 200
curl -s -o /dev/null -w "%{http_code}\n" https://m2atodev.com/api.epilist/public/

# Un point d'entrée protégé : doit répondre 401, PAS 500.
# 500 voudrait dire que le code lit une colonne absente.
curl -s -o /dev/null -w "%{http_code}\n" https://m2atodev.com/api.epilist/public/inventory
curl -s -o /dev/null -w "%{http_code}\n" https://m2atodev.com/api.epilist/public/recipes
```

Puis, avec l'API locale branchée sur la production **si vous voulez
aller plus loin** (elle crée un compte jetable) :

```bash
php api/scripts/test_analyse_endpoints.php https://m2atodev.com/api.epilist/public
```

Attendu : **40 vérifications réussies, 0 échec**.

---

## Si ça tourne mal

L'application plante sur **À la maison** ou **Budgets** après le push :
c'est que le SQL n'est pas passé. Rejouer l'étape 1 (les deux
fichiers), puis l'étape 2.

« À la maison » n'affiche que le bloc **Ailleurs** : la colonne `zone`
est là, mais aucune provision n'en a encore une — c'est normal, et
chaque produit se range depuis « Quantité et seuils ».

Les états d'inventaire sont faux après la migration : les quatre
`UPDATE` du bloc 8 se rejouent seuls, sans risque — ils sont écrits
pour être idempotents.

Retour en arrière complet : restaurer la sauvegarde de l'étape 0, puis
`git revert` des commits poussés. Les colonnes ajoutées sont nulles et
ne gênent pas l'ancien code : **laisser la base en place** est
préférable à une restauration, qui ferait perdre les données du jour.

---

## Ce qui N'EST PAS dans cette mise en production

Trois choses de l'analyse, et la même raison pour les trois : elles
demandent un contrat ou un coût, pas du code.

- **La carte avec les épingles des magasins.** Des tuiles
  cartographiques, donc un fournisseur, des conditions d'utilisation et
  une facturation à l'usage. La liste triée par distance réelle et
  l'itinéraire dans l'application de cartes du téléphone sont faits.
- **La photo réelle d'une devanture.** Elle appartient à l'enseigne ou
  au service de cartes. La devanture dessinée reste l'image de secours,
  comme l'analyse le demande.
- **Les prix par magasin issus des circulaires.** Une source de données
  externe. Les alertes de prix fonctionnent sur ce que l'application
  observe : les reçus scannés et, depuis cette version, les prix saisis
  en magasin.
