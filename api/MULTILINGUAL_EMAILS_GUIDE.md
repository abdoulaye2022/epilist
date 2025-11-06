# Guide Complet - Emails Multilingues EpiList

## ✅ Étapes Complétées

### 1. Base de Données
- ✅ Migration créée (`migrations/add_language_to_users.sql`)
- ✅ Colonne `language` ajoutée à la table `users`
- ✅ Index créé pour optimiser les requêtes
- ✅ Valeur par défaut: `'fr'`

### 2. Modèle User
- ✅ Champ `language` ajouté au `$fillable` dans `src/Models/User.php` (ligne 34)

### 3. Service de Templates
- ✅ `EmailTemplates.php` créé avec templates FR/EN pour:
  - Email de vérification
  - Email de bienvenue
  - Email de changement de mot de passe

## 🔧 Modifications Nécessaires

### Étape 1: Modifier AuthController - Méthode register()

**Fichier**: `src/Controllers/AuthController.php`

**Localisation**: Ligne ~2030 (après la validation)

**Ajouter la validation du champ language**:

```php
// Après les autres validations
if (isset($data['language'])) {
    $validator->rule('in', 'language', ['fr', 'en'])
        ->message('Language must be fr or en');
}
```

**Lors de la création de l'utilisateur** (ligne ~2090):

```php
// Déterminer la langue (depuis l'app ou défaut)
$language = $data['language'] ?? 'fr';
if (!in_array($language, ['fr', 'en'])) {
    $language = 'fr';
}

$user = User::create([
    'first_name' => $data['first_name'],
    'last_name' => $data['last_name'],
    'email' => $data['email'],
    'password_hash' => password_hash($data['password'], PASSWORD_BCRYPT),
    'terms_accepted' => true,
    'email_verification_code' => $verificationCode,
    'email_verification_code_expires_at' => Carbon::now()->addMinutes(15),
    'currency_id' => $currencyId,
    'language' => $language, // ⭐ AJOUTER CETTE LIGNE
]);
```

**Lors de l'envoi de l'email de vérification** (ligne ~2110):

```php
use App\Services\EmailTemplates;

// REMPLACER:
$mailSender->sendVerificationEmail($user->email, $user->first_name, $verificationCode);

// PAR:
$subject = EmailTemplates::getSubject('verification', $user->language);
$htmlContent = EmailTemplates::verificationEmail($user->first_name, $verificationCode, $user->language);
MailSender::sendMail($subject, [['email' => $user->email]], $htmlContent);
```

### Étape 2: Modifier AuthController - Email de Bienvenue

**Fichier**: `src/Controllers/AuthController.php`
**Méthode**: `confirmEmail()` (ligne ~2270)

```php
use App\Services\EmailTemplates;

// REMPLACER:
$mailSender->sendWelcomeEmail($user->email, $user->first_name);

// PAR:
$subject = EmailTemplates::getSubject('welcome', $user->language);
$htmlContent = EmailTemplates::welcomeEmail($user->first_name, $user->language);
MailSender::sendMail($subject, [['email' => $user->email]], $htmlContent);
```

### Étape 3: Modifier AuthController - Changement de Mot de Passe

**Fichier**: `src/Controllers/AuthController.php`
**Méthode**: `requestPasswordChange()` (ligne ~2400)

```php
use App\Services\EmailTemplates;

// REMPLACER:
MailSender::sendPasswordChangeCode($user->email, $code);

// PAR:
$subject = EmailTemplates::getSubject('password_change', $user->language);
$htmlContent = EmailTemplates::passwordChangeEmail($code, $user->language);
MailSender::sendMail($subject, [['email' => $user->email]], $htmlContent);
```

### Étape 4: Ajouter l'import EmailTemplates

**Fichier**: `src/Controllers/AuthController.php`
**Ligne**: ~15 (avec les autres uses)

```php
use App\Services\EmailTemplates;
```

## 📱 Modification de l'Application Flutter

### Modifier AuthService pour envoyer la langue

**Fichier**: `app/lib/services/auth_service.dart`

**Dans la méthode `register()`**, ajouter le champ language:

```dart
Future<Map<String, dynamic>> register({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  int? currencyId,
  String? language, // ⭐ AJOUTER CE PARAMÈTRE
}) async {
  try {
    final response = await dio.post(
      '/register',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        if (currencyId != null) 'currency_id': currencyId,
        'language': language ?? 'fr', // ⭐ AJOUTER CETTE LIGNE
      },
    );
    // ...
  }
}
```

### Modifier AuthBloc pour passer la langue

**Fichier**: `app/lib/blocs/auth/auth_bloc.dart`

**Dans `_onSignUpRequested()`**:

```dart
Future<void> _onSignUpRequested(
  SignUpRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());

  try {
    // ⭐ Obtenir la langue depuis LocalizationBloc
    final localizationState = localizationBloc.state;
    String userLanguage = 'fr';

    if (localizationState is LocalizationLoaded) {
      userLanguage = localizationState.locale.languageCode;
    }

    print('🌍 [AuthBloc] Inscription avec langue: $userLanguage');

    final result = await authService.register(
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
      password: event.password,
      currencyId: event.currencyId,
      language: userLanguage, // ⭐ PASSER LA LANGUE
    );
    // ...
  }
}
```

## 🧪 Comment Tester

### Test 1: Utilisateur Français
1. Changer la langue du téléphone en français
2. S'inscrire dans l'application
3. Vérifier que l'email reçu est en français

### Test 2: Utilisateur Anglais
1. Changer la langue du téléphone en anglais
2. S'inscrire dans l'application
3. Vérifier que l'email reçu est en anglais

### Test 3: Langue Invalide
1. Envoyer une requête avec `language: "es"` (espagnol)
2. Vérifier que le système utilise "fr" par défaut

### Test SQL Direct
```sql
-- Vérifier les langues des utilisateurs
SELECT id, first_name, email, language, created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- Compter par langue
SELECT language, COUNT(*) as total
FROM users
GROUP BY language;
```

## 📊 Emails Supportés

| Email | Français | Anglais | Utilise la langue de l'utilisateur |
|-------|----------|---------|-----------------------------------|
| Vérification | ✅ | ✅ | ✅ |
| Bienvenue | ✅ | ✅ | ✅ |
| Changement mot de passe | ✅ | ✅ | ✅ |
| Suppression compte | ❌ | ❌ | À implémenter |
| Campagnes marketing | ❌ | ❌ | À implémenter |

## 🚀 Prochaines Améliorations

1. **Ajouter plus de langues**: es (espagnol), de (allemand), etc.
2. **Templates pour tous les emails**: compléter les emails manquants
3. **Interface admin**: Gérer les traductions depuis un dashboard
4. **A/B Testing**: Tester différentes versions d'emails
5. **Analytics**: Tracker l'engagement par langue

## 🔍 Débogage

### Vérifier la langue sauvegardée
```php
$user = User::find(1);
echo "Langue de l'utilisateur: " . $user->language;
```

### Logger l'envoi d'emails
```php
error_log("📧 Email envoyé en langue: {$user->language} à {$user->email}");
```

### Forcer une langue pour test
```php
// Dans AuthController, temporairement:
$user->language = 'en'; // Forcer anglais
```

## ✅ Checklist de Déploiement

- [ ] Migration exécutée sur la base de données de production
- [ ] EmailTemplates.php déployé
- [ ] AuthController modifié
- [ ] App Flutter mise à jour avec envoi de language
- [ ] Tests effectués pour FR et EN
- [ ] Documentation mise à jour
- [ ] Logs de monitoring activés

