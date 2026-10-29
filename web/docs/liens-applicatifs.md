# Les liens qui ouvrent l'application

Deux fichiers, un par plateforme, dans `web/public/.well-known/`. Ils
disent à Android et à iOS que `epilist.app` et l'application
`com.m2atech.epilist` sont la même maison.

## Android — `assetlinks.json`

Ce fichier dit à Android que `epilist.app` et l'application
`com.m2atech.epilist` sont la même maison. **Sans lui, un lien de
partage n'ouvre jamais l'application** : le manifeste Android demande
`android:autoVerify="true"` (`app/android/app/src/main/AndroidManifest.xml`),
Android va chercher ce fichier à l'installation, ne le trouve pas, et
classe le lien comme « non vérifié ». Le lien s'ouvre alors dans le
navigateur, qui ne peut rien en faire.

Il doit être servi à **`https://epilist.app/.well-known/assetlinks.json`**,
en `application/json`, **sans redirection** et **sans authentification**.

## Les deux empreintes

| Empreinte | D'où elle vient | État |
|---|---|---|
| Clé de **signature de l'application** | Play Console | **à remplir** |
| Clé d'**importation** (upload) | extraite de l'AAB du 24 octobre 2026 | déjà là |

La seconde est réelle : elle vient du certificat `META-INF/UPLOAD.RSA`
de `app-release.aab`. Elle sert aux versions installées directement
(APK de test), pas à celles qui viennent du magasin.

La première est **celle qui compte**, parce que Google Play **resigne**
chaque application avec sa propre clé : ce que les gens installent n'est
pas signé par la clé d'importation. Tant que la ligne
`REMPLACER_PAR_...` est là, la vérification échoue.

## Où la trouver, exactement

Play Console → sélectionner **EpiList** → menu de gauche **Test et
publication** → **Intégrité de l'application** (ou **Signature de
l'application**) → section **Certificat de la clé de signature de
l'application** → copier l'**empreinte du certificat SHA-256**.

Elle ressemble à `AB:CD:12:...` sur 32 octets séparés par des
deux-points. Remplacer la ligne `REMPLACER_PAR_...` par cette valeur,
entre guillemets, en gardant la virgule.

La même page donne l'empreinte du **certificat de la clé
d'importation** : elle doit correspondre à celle déjà inscrite ici. Si
ce n'est pas le cas, c'est que l'AAB a été signé avec une autre clé que
celle enregistrée chez Google.

## Vérifier, une fois en ligne

```bash
curl -I https://epilist.app/.well-known/assetlinks.json
# attendu : 200, content-type: application/json, aucune redirection
```

Puis l'outil de Google, qui lit le fichier comme Android le lit :

```
https://digitalassetlinks.googleapis.com/v1/statements:list\
?source.web.site=https://epilist.app\
&relation=delegate_permission/common.handle_all_urls
```

Sur un téléphone Android, après réinstallation :

```bash
adb shell pm get-app-links com.m2atech.epilist
# attendu : epilist.app: verified
```

## iOS — `apple-app-site-association`

Celui-là existe déjà, et il est complet : `appIDs` porte
`79F8TZGAPL.com.m2atech.epilist`, les composants couvrent `/share/*`, et
l'entitlement correspondant est bien dans le projet Xcode
(`app/ios/Runner/RunnerRelease.entitlements` :
`com.apple.developer.associated-domains` → `applinks:epilist.app`).

Un seul point à surveiller : **le fichier n'a pas d'extension**, et il
doit tout de même être servi en `application/json`. C'est ce que fait
l'entrée `headers()` de `next.config.js` ajoutée avec ce fichier. Sans
elle, certains hébergeurs le servent en `application/octet-stream` et
iOS l'ignore en silence.

```bash
curl -I https://epilist.app/.well-known/apple-app-site-association
# attendu : 200, content-type: application/json
```

Autrement dit : côté iOS, tout était en place ; côté Android, il
manquait le fichier entier.
