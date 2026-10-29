export const translations = {
  fr: {
    // Header
    features: 'Fonctionnalités',
    benefits: 'Avantages',
    testimonials: 'Témoignages',
    contact: 'Contact',
    help: 'Aide',
    download: 'Télécharger',
    downloadApp: 'Télécharger l\'app',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    
    // Hero Section
    heroTitle: 'Révolutionnez vos',
    heroTitleHighlight: 'courses',
    heroSubtitle: 'L\'application qui transforme vos courses en expérience familiale fluide et organisée.',
    heroSubtitleHighlight: 'Créez, partagez, économisez.',
    downloadNow: 'Télécharger maintenant',
    watchDemo: 'Voir la démo',
    familySync: 'Synchronisation familiale',
    freeForLife: 'Gratuit à vie',
    noAds: 'Sans publicité',
    instantInstall: 'Installation instantanée',
    discoverFeatures: 'Découvrir les fonctionnalités',
    
    // Features Section - Enhanced
    featuresTitle: 'Tout ce dont vous avez',
    featuresTitleHighlight: 'besoin',
    featuresSubtitle: 'Découvrez une suite complète d\'outils pensés pour transformer votre expérience d\'achat et renforcer la collaboration familiale',
    advancedFeatures: 'Fonctionnalités avancées',
    
    // Enhanced Features (9 features total)
    feature1Title: 'Gestion intelligente des listes',
    feature1Desc: 'Créez, modifiez et dupliquez vos listes avec suggestions automatiques et organisation par catégories',
    
    feature2Title: 'Partage familial instantané',
    feature2Desc: 'Partagez vos listes par lien sécurisé, avec les droits de chacun et une notification instantanée à chaque changement',
    
    feature3Title: 'Gestion avancée des articles',
    feature3Desc: 'Ajoutez des articles avec suggestions intelligentes, quantités et statuts d\'achat personnalisables',
    
    feature4Title: 'Budgets et suivi financier',
    feature4Desc: 'Créez des budgets, suivez vos dépenses avec graphiques détaillés et analyses par période',
    
    feature5Title: 'Analytiques et statistiques',
    feature5Desc: 'Visualisez vos habitudes d\'achat avec graphiques des top produits et analyses temporelles',
    
    feature6Title: 'Sécurité et profil utilisateur',
    feature6Desc: 'Comptes sécurisés avec confirmation email, gestion de profil et récupération de mot de passe',
    
    feature7Title: 'Collaboration familiale',
    feature7Desc: 'Invitez votre famille, gérez les droits, et travaillez à plusieurs sur la même liste',
    
    feature8Title: 'Mode hors ligne avancé',
    feature8Desc: 'Travaillez sans connexion avec cache intelligent, synchronisation automatique et file d\'attente des actions',

    feature9Title: 'Multi-devises international',
    // TODO (devises) : le site annoncait « 150+ devises ». Le nombre
    // reel est en production — le depot ne contient aucun INSERT dans
    // la table `currencies`. Avant d'ecrire un chiffre ici, verifier :
    //   SELECT COUNT(*) AS total FROM currencies;
    //   SELECT COUNT(*) AS actives FROM currencies WHERE is_active = 1;
    feature9Desc: 'Tenez vos budgets dans la devise de votre pays, avec le formatage local des montants',

    feature10Title: 'Connexion SSO simplifiée',
    feature10Desc: 'Connectez-vous rapidement avec Google ou Apple Sign-In, sécurisé et sans mot de passe',

    feature11Title: 'Catégories personnalisables',
    feature11Desc: 'Créez et gérez vos propres catégories d\'articles avec icônes et couleurs personnalisées',

    feature12Title: 'Notifications instantanées',
    feature12Desc: 'Recevez une alerte pour les partages, les modifications et les dépassements de budget',

    feature13Title: 'Analytiques visuelles',
    feature13Desc: 'Graphiques détaillés de vos dépenses mensuelles, top produits et tendances d\'achat',

    feature14Title: 'Préférences email',
    feature14Desc: 'Personnalisez vos notifications email par type : alertes, résumés quotidiens ou hebdomadaires',

    feature15Title: 'Ajout vocal intelligent',
    feature15Desc: 'Ajoutez des articles à vos listes simplement en parlant. Reconnaissance vocale en français et anglais avec détection automatique des quantités',

    feature16Title: 'Détection des doublons',
    feature16Desc: 'Évitez les articles en double avec notre système intelligent qui détecte les similitudes et propose de fusionner ou d\'augmenter les quantités',

    feature17Title: 'Suggestions d\'habitudes',
    feature17Desc: 'Recevez des suggestions personnalisées basées sur vos achats récurrents et vos habitudes de consommation analysées intelligemment',

    feature18Title: 'Scanner de code-barres',
    feature18Desc: 'Scannez les codes-barres pour ajouter rapidement des produits avec informations nutritionnelles via OpenFoodFacts',

    feature19Title: 'Messagerie de listes',
    feature19Desc: 'Communiquez avec les membres de vos listes partagées pour coordonner vos achats',

    feature20Title: 'Gestion des reçus',
    feature20Desc: 'Attachez des photos de reçus à vos listes pour suivre vos dépenses réelles et conserver un historique visuel',

    moreToDiscover: 'Et bien plus encore à découvrir...',
    
    // Feature Categories
    essentialFeatures: 'Fonctionnalités essentielles',
    collaborativeTools: 'Outils collaboratifs',
    advancedTools: 'Outils avancés',
    analyticsTools: 'Outils d\'analyse',
    securityTools: 'Outils de sécurité',
    
    // Account Management Features
    accountManagement: 'Gestion de compte',
    createAccount: 'Créer un compte utilisateur',
    confirmEmail: 'Confirmer l\'email du compte',
    changePassword: 'Changer de mot de passe',
    loginAccount: 'Se connecter',
    tokenManagement: 'Gestion des tokens de connexion',
    profileManagement: 'Modifier le profil',
    deleteAccount: 'Supprimer le compte utilisateur',
    cancelDeletion: 'Annuler la suppression du compte',
    
    // List Management Features
    listManagement: 'Gestion des listes',
    createList: 'Créer une liste',
    editList: 'Modifier une liste',
    duplicateList: 'Dupliquer une liste',
    shareList: 'Partager une liste',
    deleteList: 'Supprimer une liste',
    deepLinking: 'Liens profonds testés',
    
    // Item Management Features
    itemManagement: 'Gestion des articles',
    createItem: 'Créer un article',
    editItem: 'Modifier un article',
    itemSuggestions: 'Suggestions d\'articles',
    deleteSuggestionData: 'Supprimer les données de suggestion',
    
    // Budget Features
    budgetManagement: 'Gestion des budgets',
    createBudget: 'Créer un budget',
    editBudget: 'Modifier un budget',
    disableBudget: 'Désactiver un budget',
    deleteBudget: 'Supprimer un budget',
    budgetFilter: 'Filtrer les budgets',
    
    // Analytics Features
    analyticsFeatures: 'Analyses et statistiques',
    topProductsChart: 'Graphique des top produits',
    expensesChart: 'Graphique des dépenses',
    monthlyFilter: 'Filtrer par mois',
    weeklyFilter: 'Filtrer par semaine',
    yearlyFilter: 'Filtrer par année',
    
    // Security Features
    securityFeatures: 'Fonctionnalités de sécurité',
    emailVerification: 'Vérification par email',
    secureAuthentication: 'Authentification sécurisée',
    passwordRecovery: 'Récupération de mot de passe',
    accountProtection: 'Protection du compte',
    dataEncryption: 'Chiffrement des données',
    
    // Collaboration Features
    collaborationFeatures: 'Fonctionnalités collaboratives',
    familyInvites: 'Invitations familiales',
    permissionManagement: 'Gestion des permissions',
    sharedLists: 'Listes partagées',
    teamwork: 'Travail d\'équipe',
    
    // Advanced Analytics
    advancedAnalytics: 'Analyses avancées',
    spendingPatterns: 'Habitudes de dépenses',
    topProducts: 'Produits favoris',
    budgetTracking: 'Suivi budgétaire',
    monthlyReports: 'Rapports mensuels',
    yearlyOverview: 'Vue d\'ensemble annuelle',
    
    // User Experience
    userExperience: 'Expérience utilisateur',
    intuitivInterface: 'Interface intuitive',
    smartSuggestions: 'Suggestions intelligentes',
    offlineAccess: 'Accès hors ligne',
    quickActions: 'Actions rapides',
    seamlessNavigation: 'Navigation fluide',
    
    // Enhanced Benefits Section
    benefitsTitle: 'Transformez votre',
    benefitsTitleHighlight: 'quotidien',
    benefitsSubtitle: 'Ce que l\'application fait vraiment, et que vous pouvez vérifier dès votre première liste',
    
    benefit1Title: 'Gratuite, et sans publicité',
    benefit1Desc: 'Aucun abonnement, aucun achat dans l\'application, aucune bannière. Tout ce que vous voyez est accessible sans payer.',
    
    benefit2Title: 'Bilingue d\'un bout à l\'autre',
    benefit2Desc: 'Français et anglais dans toute l\'application et dans les courriels que vous recevez. On change de langue sans rien perdre.',
    
    benefit3Title: 'Fonctionne hors ligne',
    benefit3Desc: 'Vos listes s\'ouvrent et se modifient sans réseau. Ce que vous faites dans le magasin part dès que la connexion revient.',
    
    benefit4Title: 'Vos reçus se lisent sur votre téléphone',
    benefit4Desc: 'Vous photographiez un reçu, le texte est lu sur l\'appareil. L\'image n\'est pas analysée sur nos serveurs.',
    
    benefit5Title: 'Une liste pour tout le foyer',
    benefit5Desc: 'Chacun ajoute, coche et voit les mêmes articles, avec les droits que vous choisissez : lecture, modification ou administration.',
    
    benefit6Title: 'Budgets et alertes',
    benefit6Desc: 'Fixez un budget par semaine ou par mois, suivez les dépenses, et recevez une alerte avant de le dépasser.',
    
    // Testimonials
    testimonialsTitle: 'Ils ont adopté',
    testimonialsTitleHighlight: 'EpiList',
    testimonialsSubtitle: 'Des retours de personnes qui utilisent EpiList, publiés avec leur accord écrit',
    
    // Enhanced testimonials
    
    
    
    
    
    // CTA Section
    ctaTitle: 'Prêt à révolutionner vos courses ?',
    ctaSubtitle: 'Gratuite, sans publicité, et utilisable hors ligne. Sur iOS et sur Android.',
    
    // Footer
    footerDescription: 'L\'application complète qui révolutionne votre façon de faire les courses. Organisez, partagez, budgétisez et analysez vos habitudes d\'achat avec votre famille.',
    footerNewBrunswick: 'Fièrement développé au Nouveau-Brunswick, Canada',
    footerFeatures: 'Fonctionnalités',
    footerSupport2: 'Support',
    footerNewsletter: 'Restez informé des nouveautés',
    footerNewsletterDesc: 'Recevez les dernières mises à jour et conseils pour optimiser vos courses et budgets',
    footerNewsletterPlaceholder: 'Votre adresse email',
    footerNewsletterButton: 'S\'abonner',
    footerCopyright: '© 2024 EpiList. Tous droits réservés. Fait avec ❤️ au Canada.',
    
    // Footer links
    shoppingLists: 'Listes de courses',
    familySharing: 'Partage familial',
    synchronization: 'Synchronisation',
    advancedSecurity: 'Sécurité avancée',
    offlineMode: 'Mode hors ligne',
    smartSuggestionsFooter: 'Suggestions intelligentes',
    helpCenter: 'Centre d\'aide',
    faq: 'FAQ',
    reportBug: 'Signaler un bug',
    featureRequest: 'Demande de fonctionnalité',
    community: 'Communauté',
    privacyPolicy: 'Politique de confidentialité',
    termsOfService: 'Conditions d\'utilisation',
    legalNotices: 'Mentions légales',
    cookies: 'Cookies',
    
    // New Brunswick Section
    nbTitle: 'Fièrement',
    nbTitleHighlight: 'Néo-Brunswickois',
    nbSubtitle: 'Développé avec passion dans les Maritimes canadiennes',
    nbDescription: 'EpiList est né au cœur du Nouveau-Brunswick, province bilingue reconnue pour son innovation technologique et sa qualité de vie exceptionnelle.',
    nbFeature1: 'Innovation Maritime',
    nbFeature1Desc: 'Technologie de pointe développée dans les Maritimes',
    nbFeature2: 'Bilinguisme naturel',
    nbFeature2Desc: 'Conçu dans une province officiellement bilingue',
    nbFeature3: 'Valeurs familiales',
    nbFeature3Desc: 'Reflète l\'esprit communautaire néo-brunswickois',
    nbWhyTitle: 'Pourquoi le Nouveau-Brunswick ?',
    nbOfficiallyBilingual: 'Province officiellement bilingue',
    nbOfficiallyBilingualDesc: 'Français et anglais à égalité',
    nbMaritimeInnovation: 'Innovation maritime',
    nbMaritimeInnovationDesc: 'Hub technologique de l\'Atlantique',
    nbFamilyValues: 'Valeurs familiales',
    nbFamilyValuesDesc: 'Communauté unie et solidaire',
    nbQualityOfLife: 'Qualité de vie',
    nbQualityOfLifeDesc: 'Équilibre travail-famille parfait',
    nbCapital: 'Capitale technologique des Maritimes',
    
    // Common
    activeUsers: 'utilisateurs actifs',
    free: '100% Gratuit',
    noHiddenFees: 'Aucun frais caché',
    adFree: 'Sans publicité',
    pureExperience: 'Expérience pure',
    quickInstall: 'Installation rapide',
    readyIn30s: 'Prêt en 30 secondes',
    madeInCanada: 'Conçue au Nouveau-Brunswick, Canada',
    language: 'fr',
    availability: 'Disponibilité',
    
    // Legal Pages Common
    backToHome: 'Retour à l\'accueil',
    lastUpdated: 'Dernière mise à jour',
    contactUsTitle: 'Nous contacter',
    
    // Privacy Policy
    privacyPolicyTitle: 'Politique de confidentialité',
    privacyPolicySubtitle: 'Ce que nous collectons, pourquoi, où cela est rangé, et ce que vous pouvez en faire.',
    
    // Privacy additional content
    bankLevelSecurity: 'Mots de passe illisibles',
    emailSupport: 'Support par email',
    phoneSupport: 'Support téléphonique',
    ourLocation: 'Notre emplacement',
    
    dataCollectionTitle: 'Collecte des données',
    
    dataUsageTitle: 'Utilisation des données',
    
    dataSecurityTitle: 'Sécurité des données',
    
    userRightsTitle: 'Vos droits',
    
    
    // Terms of Service
    termsOfServiceTitle: 'Conditions d\'utilisation',
    termsOfServiceSubtitle: 'Les règles et conditions qui régissent l\'utilisation d\'EpiList.',
    
    // Terms additional content
    quickSummary: 'Résumé rapide',
    quickSummaryDesc: 'Voici l\'essentiel de nos conditions d\'utilisation en quelques points clés.',
    freeToUse: 'Gratuit à utiliser',
    freeToUseDesc: 'EpiList est 100% gratuit, sans frais cachés',
    respectfulUse: 'Utilisation respectueuse',
    respectfulUseDesc: 'Utilisez l\'app de manière éthique et légale',
    fairTerms: 'Conditions équitables',
    fairTermsDesc: 'Des règles claires et transparentes pour tous',
    legalTeam: 'Équipe juridique',
    
    acceptanceTitle: 'Acceptation des conditions',
    acceptanceContent: 'En téléchargeant, installant ou utilisant l\'application EpiList, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre service.',
    
    serviceDescriptionTitle: 'Description du service',
    serviceDescriptionContent: 'EpiList est une application mobile gratuite qui permet de créer, gérer et partager des listes de courses avec son foyer. Le service comprend la création et la gestion de listes, le partage avec les droits de chacun, les notifications instantanées lors des changements, les budgets, la lecture des reçus et les suggestions d\'articles.',
    
    userAccountTitle: 'Compte utilisateur',
    userAccountContent: 'Pour utiliser EpiList, vous devez créer un compte avec une adresse email valide. Vous êtes responsable de maintenir la confidentialité de vos informations de connexion et de toutes les activités qui se produisent sous votre compte.',
    
    listsAndSharingTitle: 'Listes et partage',
    listsAndSharingContent: 'Vous pouvez créer des listes de courses personnelles et les partager avec votre famille ou amis via des liens sécurisés. Vous contrôlez les permissions d\'accès (lecture, modification, administration) pour chaque personne invitée.',
    
    acceptableUseTitle: 'Utilisation acceptable',
    acceptableUseContent: 'Vous vous engagez à utiliser EpiList de manière légale et éthique. Il est interdit d\'utiliser le service pour violer des lois, transmettre du contenu offensant, accéder aux comptes d\'autres utilisateurs ou interférer avec le fonctionnement normal du service.',
    
    contentOwnershipTitle: 'Propriété du contenu',
    contentOwnershipContent: 'Vous conservez la propriété de vos listes de courses et données personnelles. EpiList et ses contenus sont protégés par les lois sur le droit d\'auteur. En utilisant notre service, vous nous accordez une licence limitée pour traiter vos données afin de fournir le service.',
    
    calculationsTitle: 'Calculs et totaux',
    calculationsContent: 'EpiList effectue des calculs automatiques pour vos totaux de courses et pourcentages d\'articles achetés. Bien que nous nous efforcions d\'assurer l\'exactitude, ces calculs sont fournis à titre indicatif.',
    
    serviceAvailabilityTitle: 'Disponibilité du service',
    serviceAvailabilityContent: 'Nous nous efforçons de maintenir EpiList disponible 24h/7j, mais nous ne garantissons pas un service ininterrompu. Des maintenances programmées ou des problèmes techniques peuvent occasionnellement affecter la disponibilité.',
    
    limitationLiabilityTitle: 'Limitation de responsabilité',
    limitationLiabilityContent: 'EpiList est fourni "tel quel" sans garantie d\'aucune sorte. Nous ne garantissons pas que le service sera ininterrompu ou exempt d\'erreurs. Dans la mesure permise par la loi, M2atech Solutions Inc. ne sera pas responsable des dommages indirects, accessoires ou consécutifs résultant de l\'utilisation du service.',
    
    suspensionTitle: 'Suspension et résiliation',
    suspensionContent: 'Nous nous réservons le droit de suspendre ou résilier votre accès à EpiList en cas de violation de ces conditions. Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.',
    
    modificationsTitle: 'Modifications des conditions',
    modificationsContent: 'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications importantes seront communiquées par email ou notification dans l\'application.',
    
    applicableLawTitle: 'Droit applicable',
    applicableLawContent: 'Ces conditions sont régies par les lois du Canada et de la province du Nouveau-Brunswick. Tout litige sera soumis à la juridiction exclusive des tribunaux du Nouveau-Brunswick.',
    
    contactSupportTitle: 'Contact et support',
    contactSupportContent: 'Pour toute question concernant ces conditions d\'utilisation ou si vous avez besoin d\'aide, notre équipe est à votre disposition.',
    
    // Support Page
    supportTitle: 'Centre d\'aide',
    supportSubtitle: 'Nous sommes là pour vous aider. Trouvez des réponses ou contactez notre équipe.',
    
    // Support additional content
    howCanWeHelp: 'Comment pouvons-nous vous aider ?',
    chooseYourPreferredWay: 'Choisissez votre méthode de contact préférée pour obtenir l\'aide dont vous avez besoin.',
    immediate: 'Immédiat',
    responseTime: 'Temps de réponse',
    browseHelpTopics: 'Parcourir les sujets d\'aide',
    findAnswersInOurKnowledgeBase: 'Trouvez des réponses dans notre base de connaissances complète.',
    articles: 'articles',
    frequentlyAskedQuestions: 'Questions fréquemment posées',
    quickAnswersToCommonQuestions: 'Réponses rapides aux questions les plus courantes.',
    securityPrivacyTitle: 'Sécurité et confidentialité',
    securityPrivacyDesc: 'Protection de vos données et vie privée',
    troubleshootingTitle: 'Dépannage',
    troubleshootingDesc: 'Solutions aux problèmes techniques',
    localTeamAvailable: 'Équipe locale disponible',
    satisfactionGuarantee: 'Garantie de satisfaction',
    satisfactionGuaranteeText: 'Nous nous engageons à vous fournir le meilleur support possible. Votre satisfaction est notre priorité absolue.',
    happyUsers: 'utilisateurs satisfaits',
    
    emailSupportTitle: 'Support par email',
    emailSupportDesc: 'Envoyez-nous un message détaillé et nous vous répondrons dans les 24h.',
    sendEmail: 'Envoyer un email',
    
    phoneSupportTitle: 'Support téléphonique',
    phoneSupportDesc: 'Parlez directement avec notre équipe du lundi au vendredi.',
    callUs: 'Nous appeler',
    
    liveChatTitle: 'Chat en direct',
    liveChatDesc: 'Obtenez une aide immédiate via notre chat en ligne.',
    startChat: 'Démarrer le chat',
    availableNow: 'Disponible maintenant',
    
    supportCategoriesTitle: 'Catégories d\'aide',
    gettingStartedTitle: 'Premiers pas',
    gettingStartedDesc: 'Guide pour débuter avec EpiList',
    familySharingTitle: 'Partage familial',
    familySharingDesc: 'Comment partager vos listes',
    reportBugTitle: 'Signaler un bug',
    reportBugDesc: 'Aidez-nous à améliorer l\'app',
    featureRequestTitle: 'Nouvelle fonctionnalité',
    featureRequestDesc: 'Suggérez des améliorations',
    
    faqTitle: 'Questions fréquentes',
    faq1Question: 'Comment créer ma première liste de courses ?',
    faq1Answer: 'Ouvrez l\'application, appuyez sur le bouton "+" et commencez à ajouter vos articles. Vous pouvez organiser par catégories et partager avec votre famille.',
    faq2Question: 'Comment partager une liste avec ma famille ?',
    faq2Answer: 'Dans votre liste, appuyez sur l\'icône de partage, puis invitez les membres de votre famille par email. Ils recevront une invitation à rejoindre la liste.',
    faq3Question: 'Mes données sont-elles synchronisées entre mes appareils ?',
    faq3Answer: 'Vos listes sont conservées sur votre compte et se retrouvent sur chacun de vos appareils. L\'application récupère les changements à l\'ouverture et au rafraîchissement, et une notification instantanée signale ce qui bouge dans une liste partagée.',
    faq4Question: 'L\'application fonctionne-t-elle hors ligne ?',
    faq4Answer: 'Oui, vous pouvez consulter et modifier vos listes hors ligne. Les changements seront synchronisés dès que vous retrouverez une connexion internet.',
    
    supportHoursTitle: 'Heures de support',
    mondayFriday: 'Lundi - Vendredi',
    weekend: 'Week-end',
    holidays: 'Jours fériés',
    limitedSupport: 'Support limité',
    
    ourLocationTitle: 'Notre emplacement',
    canada: 'Canada',
    
    satisfactionTitle: 'Votre satisfaction, notre priorité',
    satisfactionText: 'Nous nous engageons à fournir un support exceptionnel à tous nos utilisateurs.',
    satisfactionRate: 'Taux de satisfaction',
    averageResponseTime: 'Temps de réponse moyen',
    
    // Contact Page
    contactTitle: 'Nous écrire',
    contactSubtitle: 'Nous sommes là pour vous aider. Envoyez-nous un message et nous vous répondrons rapidement.',
    getInTouch: 'Entrer en contact',
    contactFormDescription: 'Remplissez le formulaire ci-dessous et nous vous répondrons dans les plus brefs délais.',
    yourName: 'Votre nom',
    namePlaceholder: 'Jean Dupont',
    yourEmail: 'Votre email',
    emailPlaceholder: 'jean@exemple.com',
    subject: 'Sujet',
    selectSubject: 'Sélectionnez un sujet',
    technicalSupport: 'Support technique',
    bugReport: 'Signalement de bug',
    partnership: 'Partenariat',
    other: 'Autre',
    message: 'Message',
    messagePlaceholder: 'Décrivez votre demande en détail...',
    sendMessage: 'Envoyer le message',
    sending: 'Envoi en cours...',
    messageSent: 'Message envoyé !',
    messageConfirmation: 'Merci pour votre message. Nous vous répondrons dans les 24 heures.',
    contactInfo: 'Informations de contact',
    emailUs: 'Envoyez-nous un email',
    responseIn24h: 'Réponse sous 24h',
    visitUs: 'Rendez-nous visite',
    businessHours: 'Heures d\'ouverture',
    closed: 'Fermé',
    quickLinks: 'Liens rapides',
    
    // Privacy Policy - Detailed Content
    dataCollectionTitleP: '1. Collecte des informations',
    dataCollectionContent: 'EpiList collecte les informations suivantes :\n\n• Compte : prénom, nom, adresse courriel, mot de passe (jamais conservé en clair — seule une empreinte est stockée)\n• Listes : noms des listes, articles, quantités, prix, magasins (facultatif)\n• Partage : liens de partage et droits d\'accès (lecture, modification, administration)\n• Reçus : photo du reçu, magasin, date et montants — voir la section « Reçus et photos de reçus »\n• Usage : articles cochés, totaux et pourcentages calculés\n• Technique : journaux d\'erreurs et de performance de l\'application\n• Appareil : un jeton d\'envoi de notifications, si vous les acceptez\n\nPosition : si vous l\'autorisez, l\'application lit la position de votre téléphone pour trier vos magasins du plus proche au plus loin. Cette position reste sur l\'appareil — elle n\'est ni enregistrée, ni envoyée à nos serveurs. Vous pouvez la refuser et ne donner que votre code postal.\n\nNous ne collectons aucune donnée sensible au-delà de ce qui est nécessaire au fonctionnement.',
    
    dataUsageTitleP: '2. Utilisation des données',
    dataUsageContent: 'Vos données servent uniquement à :\n\n• Créer et gérer votre compte\n• Créer, modifier, dupliquer et supprimer vos listes\n• Calculer les totaux et le pourcentage d\'articles achetés\n• Partager vos listes avec les personnes que vous choisissez, selon les droits que vous fixez\n• Retrouver vos listes sur chacun de vos appareils\n• Suivre vos budgets et vous alerter avant un dépassement\n• Vous envoyer les courriels liés à votre compte : vérification, changement de mot de passe, suppression\n• Vous aider quand vous nous écrivez\n\nNous ne vendons, ne louons et n\'échangeons aucune donnée personnelle.',
    receiptsTitle: 'Reçus et photos de reçus',
    receiptsContent: 'Quand vous photographiez un reçu :\n\n• La lecture du texte se fait SUR votre téléphone. L\'image n\'est pas envoyée à un service d\'analyse, et nous ne l\'analysons pas sur nos serveurs.\n• Vous validez ce qui a été lu. Seuls le magasin, la date et les montants sont enregistrés dans votre compte, pour vos budgets et votre historique.\n• La photo, si vous la conservez, est rangée de façon privée chez notre fournisseur d\'hébergement infonuagique. Elle n\'a pas d\'adresse publique : l\'application demande un lien temporaire, valable quinze minutes, et seulement si vous avez le droit de voir la liste concernée.\n• Les membres d\'une liste partagée voient les reçus de cette liste. Personne d\'autre.\n• Vos reçus et leurs photos sont effacés avec votre compte.',
    
    dataSecurityTitleP: '3. Stockage et sécurité',
    dataSecurityContent: 'Vos données sont protégées par :\n\n• Un transport chiffré entre l\'application et nos serveurs\n• Des mots de passe conservés sous forme d\'empreinte, jamais en clair : nous ne pouvons pas les lire\n• Une vérification en deux étapes par courriel, si vous l\'activez\n• Des photos de reçus rangées en accès privé, qui ne s\'ouvrent que par un lien temporaire\n• Des liens de partage dont vous fixez les droits, révocables à tout moment\n• Des sauvegardes régulières\n\nAucun système n\'est à l\'abri de tout. Si un incident touchait vos données, nous vous en informerions.',
    
    dataSharingTitle: 'Partage des données',
    dataSharingContent: 'Vos données personnelles ne sont partagées que dans ces cas :\n\n• Avec les personnes que vous autorisez, par le partage d\'une liste ou d\'un espace\n• Avec nos fournisseurs techniques, et strictement pour faire fonctionner le service : hébergement infonuagique de la base de données et des images, envoi des courriels, envoi des notifications\n• Avec les autorités, si la loi l\'exige\n\nLe partage d\'une liste suit les droits que vous définissez :\n• Lecture seule : consulter, sans modifier\n• Modification : ajouter, cocher et supprimer des articles\n• Administration : tout gérer, y compris supprimer la liste\n\nAucun partage commercial n\'est effectué.',
    
    userRightsTitleP: '5. Vos droits',
    userRightsContent: 'Vous avez le droit de :\n\n• Accéder à vos données personnelles\n• Corriger vos informations de compte (prénom, nom, courriel)\n• Supprimer votre compte et les données qui s\'y rattachent — depuis l\'application, ou depuis la page de suppression de compte de ce site\n• Exporter vos reçus en PDF ou en CSV depuis l\'application\n• Révoquer un lien de partage, ou changer les droits d\'un membre, à tout moment\n• Supprimer une liste ou un article un par un\n• Retirer votre consentement aux courriels d\'information, sans perdre votre compte\n\nÉcrivez-nous pour exercer un droit que l\'application ne couvre pas encore.',
    accountDeletionTitle: 'Suppression du compte',
    accountDeletionContent: 'Vous pouvez supprimer votre compte depuis l\'application — Profil, puis Sécurité — ou depuis la page de suppression de compte de ce site si vous n\'avez plus l\'application. Dans les deux cas, une confirmation par courriel est demandée : personne ne peut supprimer votre compte sans accès à votre boîte.\n\nCe qui se passe dès la confirmation :\n\n• Votre prénom, votre nom, votre adresse courriel, votre mot de passe et votre photo de profil sont effacés\n• Vos listes personnelles, vos reçus et leurs photos, vos budgets, votre inventaire, votre historique d\'achats et vos préférences sont détruits\n• Vos appareils, vos jetons de connexion et vos liens de connexion externes sont révoqués\n• Les listes et espaces que vous partagiez sont transmis à un autre membre qui peut les administrer, pour ne pas lui retirer ses courses ; ceux que personne d\'autre ne peut reprendre sont détruits\n• Vos messages dans les conversations partagées restent, signés « Utilisateur supprimé », pour ne pas trouer l\'historique des autres membres\n\nLa ligne vide qui subsiste dans notre base est détruite au plus tard trente jours après la suppression. Votre adresse courriel redevient disponible : vous pouvez créer un nouveau compte avec elle.',
    
    appFeaturesTitle: 'Fonctionnalités de l\'application',
    appFeaturesContent: 'EpiList traite vos données pour offrir les fonctionnalités suivantes :\n\n• Création et gestion de comptes utilisateurs\n• Création, duplication, modification et suppression de listes\n• Ajout d\'articles avec nom, quantité, prix et magasin (optionnel)\n• Marquage d\'articles comme achetés ou suppression d\'articles\n• Calcul automatique des totaux et pourcentages d\'achat\n• Génération de liens de partage sécurisés\n• Gestion des permissions d\'accès collaboratif\n\nToutes ces données restent sous votre contrôle.',
    measurementTitle: 'Mesure d\'audience',
    measurementContent: 'Dans l\'application : aucun outil de mesure. Aucun événement d\'usage n\'est envoyé à un tiers. Les seules communications sortantes sont celles qui font fonctionner le service — nos serveurs, l\'envoi des courriels et l\'envoi des notifications.\n\nSur ce site web : nous utilisons des outils de mesure d\'audience fournis par des tiers, pour savoir combien de personnes visitent les pages et par où elles arrivent. Ils déposent des témoins et enregistrent des informations techniques : pages vues, provenance, type d\'appareil. Ils n\'ont aucun accès au contenu de votre compte EpiList — ce site ne le lit jamais.\n\nVous pouvez les bloquer en refusant les témoins dans votre navigateur. Un réglage de consentement sur le site est en préparation.',
    
    cookiesTitle: 'Témoins et technologies similaires',
    cookiesContent: 'Dans l\'application : aucun témoin publicitaire. L\'application garde sur votre téléphone ce qu\'il faut pour vous reconnaître d\'une ouverture à l\'autre — un jeton de connexion — ainsi que vos préférences d\'affichage, comme la langue et le thème.\n\nSur ce site : votre choix de langue est conservé par votre navigateur, et les outils de mesure d\'audience décrits à la section précédente déposent leurs propres témoins. Vous pouvez tout effacer depuis votre navigateur ; le site reste utilisable.\n\nNous n\'utilisons aucun témoin pour vous montrer de la publicité : il n\'y en a pas dans EpiList.',
    privacyModificationsTitle: 'Modifications de cette politique',
    privacyModificationsContent: 'Cette politique peut être mise à jour pour suivre les évolutions de l\'application. Les changements importants vous seront annoncés par courriel à l\'adresse de votre compte, et la date en haut de cette page sera modifiée.',
    privacyUpdatedDate: '29 octobre 2026',
    dataResidencyCanada: 'Nos serveurs et le stockage des images sont situés au Canada.',
    
    modificationsTitleP: '8. Modifications',
    modificationsContentP: 'Cette politique peut être mise à jour pour refléter les évolutions de l\'application. Nous vous informerons des changements importants par :\n\n• Email à l\'adresse associée à votre compte\n• Mise à jour de la date en haut de cette politique\n\nVotre utilisation continue de l\'application après les modifications constitue votre acceptation.',
    
    contactTitleP: '9. Contact',
    contactContent: 'Pour toute question concernant cette politique de confidentialité ou vos données, veuillez nous contacter via notre site web.\n\nNous nous engageons à répondre sous 48h ouvrées.',
    
    // Additional privacy terms
    encryptedStorage: 'Conservés sous forme d\'empreinte, même pour nous',
    dataProtection: 'Photos de reçus privées',
    industryStandards: 'Ouvertes par un lien de quinze minutes',
    userControl: 'Suppression réelle',
    fullDataControl: 'Vos données effacées, pas seulement désactivées',
    allRightsReserved: 'Tous droits réservés',

    // Footer additional
    footerTagline: 'Simplifiez vos courses',
    application: 'Application',
    support: 'Support',
    company: 'Entreprise',
    legal: 'Légal',
    contactUs: 'Nous contacter',
    about: 'À propos',
    privacy: 'Confidentialité',
    terms: 'Conditions',
    comparison: 'Comparaison',
    stayInformed: 'Restez informé 📬',
    newsletterDescription: 'Nouvelles fonctionnalités, conseils courses et mises à jour exclusives',
    subscribe: 'S\'abonner',
    newBrunswick: '🍁 Nouveau-Brunswick',
    copyright: '© EpiList — M2atech Solutions Inc. Tous droits réservés.',
    madeWith: 'Made with',
    inNewBrunswick: 'in New Brunswick',

    // Nouvelles fonctionnalités 2026 (intelligence prix & foyer)
    featureScanTitle: 'Scanner de reçus',
    featureScanDesc: "Photographiez votre reçu : EpiList lit les articles et les prix, vous validez, l'historique se remplit tout seul.",
    featurePricesTitle: 'Comparateur de prix',
    featurePricesDesc: 'Comparez le coût de votre liste entre vos magasins, à partir des prix réels de vos achats.',
    featurePredictTitle: 'Suggestions prédictives',
    featurePredictDesc: "« Il vous manque probablement du lait » : EpiList apprend vos habitudes et prévient avant la panne.",
    featureInventoryTitle: 'Inventaire maison',
    featureInventoryDesc: 'Rangé par zone — garde-manger, frigo, congélateur, entretien — et relié à vos listes.',
    featureStoreModeTitle: 'Mode magasin',
    featureStoreModeDesc: 'Votre liste triée rayon par rayon selon votre magasin, avec la progression qui suit vos achats.',
    featureMealsTitle: 'Planificateur de repas',
    featureMealsDesc: 'Choisissez vos repas, EpiList consolide les ingrédients et crée la liste en tenant compte de votre inventaire.',
    switchToEnglish: 'English version',
    switchToFrench: 'Version française',
    navigation: 'Navigation',
    product: 'Produit',
    // Page À propos
    aboutPageTitle: 'À propos d\u2019EpiList',
    aboutPageSubtitle: 'Une équipe basée au Nouveau-Brunswick, dédiée à simplifier les courses des familles canadiennes.',
    aboutMissionTitle: 'Notre mission',
    aboutMissionText: 'Simplifier la façon dont les familles s\u2019organisent au quotidien : des listes partagées, un budget maîtrisé et des courses plus rapides, sans complexité inutile.',
    aboutValuesTitle: 'Nos valeurs',
    aboutValue1Title: 'La famille d\u2019abord',
    aboutValue1Desc: 'Des outils qui renforcent la collaboration et simplifient le quotidien de toute la maison.',
    aboutValue2Title: 'Innovation locale',
    aboutValue2Desc: 'Conçue et développée au Nouveau-Brunswick, au c\u0153ur des Maritimes.',
    aboutValue3Title: 'Écoute des utilisateurs',
    aboutValue3Desc: 'Chaque retour compte : l\u2019application évolue au rythme des besoins réels des familles.',
    aboutStatsTitle: 'EpiList en bref',
    aboutStat1Value: '2024',
    aboutStat1Label: 'Année de création',
    aboutStat2Value: '100 %',
    aboutStat2Label: 'Gratuite, sans publicité',
    aboutStat3Value: '2',
    aboutStat3Label: 'Langues (français, anglais)',
    aboutStat4Value: 'Hors ligne',
    aboutStat4Label: 'Listes accessibles sans réseau',
    aboutTeamTitle: 'Une équipe des Maritimes',
    aboutTeamText: 'EpiList est développée par M2atech Solutions Inc., une équipe qui combine expertise technique et compréhension concrète des besoins des familles canadiennes.',
    // Page Aide
    helpPageTitle: 'Centre d\u2019aide',
    helpPageSubtitle: 'Trouvez rapidement des réponses, ou écrivez à notre équipe du Nouveau-Brunswick.',
    helpFaqTitle: 'Questions fréquentes',
    helpFaq1Q: 'EpiList est-elle vraiment gratuite ?',
    helpFaq1A: 'Oui, EpiList est entièrement gratuite : aucun frais caché, aucun abonnement, aucune publicité.',
    helpFaq2Q: 'Comment partager mes listes avec ma famille ?',
    helpFaq2A: 'Créez votre liste puis partagez-la par lien ou par invitation. Chaque membre reçoit une notification instantanée lorsqu\'un article change.',
    helpFaq3Q: 'L\u2019application fonctionne-t-elle hors ligne ?',
    helpFaq3A: 'Oui. Vos listes restent disponibles sans connexion et se synchronisent dès que vous retrouvez Internet.',
    helpFaq4Q: 'Sur quelles plateformes EpiList est-elle disponible ?',
    helpFaq4A: 'Sur iOS (App Store) et Android (Google Play), avec synchronisation entre tous vos appareils.',
    helpFaq5Q: 'Mes données sont-elles sécurisées ?',
    helpFaq5A: 'Vos données sont protégées et ne sont jamais vendues. Voyez notre politique de confidentialité pour le détail.',
    helpFaq6Q: 'Comment fonctionne le scanner de reçus ?',
    helpFaq6A: 'Photographiez votre reçu : l\u2019application lit les articles et les prix sur votre téléphone, vous corrigez si besoin, puis l\u2019historique de prix se construit automatiquement.',
    helpContactTitle: 'Besoin d\u2019aide personnalisée ?',
    helpContactText: 'Notre équipe est là pour vous aider, en français ou en anglais.',
    helpResponseTime: 'Réponse sous 24 h',
    // Page Télécharger
    dlBadge: 'Téléchargement gratuit',
    dlTitle: 'Téléchargez EpiList',
    dlSubtitle: 'Listes partagées, budget, scanner de reçus et comparateur de prix. Gratuit, sans publicité, hors ligne.',
    dlOnStore: 'Télécharger sur',
    dlFeature1Title: 'Installation rapide',
    dlFeature1Desc: 'Prête en moins d\u2019une minute',
    dlFeature2Title: 'Gratuite à vie',
    dlFeature2Desc: 'Aucun frais caché',
    dlFeature3Title: 'Conçue au Canada',
    dlFeature3Desc: 'Nouveau-Brunswick, Canada',
    dlScreensTitle: 'Aperçu de l\u2019application',
    dlShot1Title: 'Listes intelligentes',
    dlShot1Desc: 'Créez et organisez vos listes facilement',
    dlShot2Title: 'Analyses détaillées',
    dlShot2Desc: 'Suivez vos habitudes d\u2019achat',
    dlShot3Title: 'Budget maîtrisé',
    dlShot3Desc: 'Suivez vos dépenses de près',
    // Page Comparaison
    cmpTitle: 'Pourquoi choisir EpiList ?',
    cmpSubtitle: 'Comparaison factuelle avec les principales applications de listes de courses.',
    cmpColFeatures: 'Fonctionnalités',
    cmpRowPrice: 'Prix',
    cmpRowShare: 'Partage familial',
    cmpRowOffline: 'Mode hors ligne',
    cmpRowNoAds: 'Sans publicité',
    cmpRowSuggestions: 'Suggestions intelligentes',
    cmpRowPrices: 'Comparateur de prix magasins',
    cmpFreeForever: 'Gratuit à vie',
    cmpWhyTitle: 'Ce qui distingue EpiList',
    cmpWhy1Title: '100 % gratuite',
    cmpWhy1Desc: 'Pas d\u2019abonnement, pas de version « premium »',
    cmpWhy2Title: 'Fonctionne partout',
    cmpWhy2Desc: 'Mode hors ligne complet, données synchronisées',
    cmpWhy3Title: 'Conçue au Canada',
    cmpWhy3Desc: 'Bilingue, multidevise, pensée pour les familles d\u2019ici',

    // Suppression de compte depuis le site (exigence des magasins
    // d'applications : la procédure doit exister hors de l'application)
    delTitle: 'Supprimer votre compte EpiList',
    delFooterLink: 'Supprimer mon compte',
    delIntro: 'Vous pouvez supprimer votre compte depuis l\'application, dans Profil puis Sécurité. Si vous n\'avez plus l\'application, utilisez ce formulaire : nous vous enverrons un lien de confirmation par courriel.',
    delEmailLabel: 'Votre adresse courriel',
    delEmailPlaceholder: 'vous@exemple.com',
    delSubmit: 'Envoyer le lien de confirmation',
    delSending: 'Envoi en cours...',
    delSentTitle: 'Vérifiez votre courriel',
    delWhatTitle: 'Ce qui sera effacé',
    delWhat1: 'Votre nom, votre adresse courriel et votre mot de passe',
    delWhat2: 'Vos listes personnelles, leurs articles et leur historique',
    delWhat3: 'Vos reçus et les photos de reçus',
    delWhat4: 'Vos budgets, votre inventaire et vos préférences',
    delKeptTitle: 'Ce qui est transmis',
    delKept1: 'Les listes que vous partagez avec d\'autres personnes leur sont transmises, pour ne pas leur retirer leurs courses.',
    delKept2: 'Vos messages dans les conversations partagées restent, signés « Utilisateur supprimé ».',
    delDelayTitle: 'Dans quels délais',
    delDelayText: 'Vos données personnelles sont effacées dès la confirmation. La ligne vide qui reste est détruite au plus tard trente jours après.',
    delHelpText: 'Une question avant de vous décider ? Écrivez-nous.',
    delInvalidEmail: 'Veuillez saisir une adresse courriel valide.',
    delFailed: 'L\'envoi a échoué. Réessayez dans un instant ou écrivez-nous.',
    delConfirmChecking: 'Vérification du lien...',
    delConfirmOkTitle: 'Compte supprimé',
    delConfirmErrorTitle: 'Lien plus valable',
    delBackHome: 'Retour à l\'accueil',


  },
  en: {
    // Header
    features: 'Features',
    benefits: 'Benefits',
    testimonials: 'Testimonials',
    contact: 'Contact',
    help: 'Help',
    download: 'Download',
    downloadApp: 'Download app',
    appStore: 'App Store',
    googlePlay: 'Google Play',
    
    // Hero Section
    heroTitle: 'Revolutionize your',
    heroTitleHighlight: 'shopping',
    heroSubtitle: 'The app that transforms your grocery shopping into a smooth and organized family experience.',
    heroSubtitleHighlight: 'Create, share, save.',
    downloadNow: 'Download now',
    watchDemo: 'Watch demo',
    familySync: 'Family synchronization',
    freeForLife: 'Free for life',
    noAds: 'Ad-free',
    instantInstall: 'Instant install',
    discoverFeatures: 'Discover features',
    
    // Features Section - Enhanced
    featuresTitle: 'Everything you',
    featuresTitleHighlight: 'need',
    featuresSubtitle: 'Discover a complete suite of tools designed to transform your shopping experience and strengthen family collaboration',
    advancedFeatures: 'Advanced features',
    
    // Enhanced Features (9 features total)
    feature1Title: 'Smart List Management',
    feature1Desc: 'Create, edit and duplicate your lists with automatic suggestions and category organization',
    
    feature2Title: 'Instant Family Sharing',
    feature2Desc: 'Share your lists by secure link, with each person’s rights and an instant notification on every change',
    
    feature3Title: 'Advanced Item Management',
    feature3Desc: 'Add items with smart suggestions, customizable quantities and purchase statuses',
    
    feature4Title: 'Budgets & Financial Tracking',
    feature4Desc: 'Create budgets, track expenses with detailed charts and period analysis',
    
    feature5Title: 'Analytics & Statistics',
    feature5Desc: 'Visualize your shopping habits with top product charts and temporal analysis',
    
    feature6Title: 'Security & User Profile',
    feature6Desc: 'Secure accounts with email confirmation, profile management and password recovery',
    
    feature7Title: 'Family Collaboration',
    feature7Desc: 'Invite your family, manage rights, and work together on the same list',
    
    feature8Title: 'Advanced Offline Mode',
    feature8Desc: 'Work without connection with smart cache, automatic sync and action queue',

    feature9Title: 'Multi-Currency International',
    // TODO (devises) : le site annoncait « 150+ devises ». Le nombre
    // reel est en production — le depot ne contient aucun INSERT dans
    // la table `currencies`. Avant d'ecrire un chiffre ici, verifier :
    //   SELECT COUNT(*) AS total FROM currencies;
    //   SELECT COUNT(*) AS actives FROM currencies WHERE is_active = 1;
    feature9Desc: 'Keep your budgets in your own currency, with amounts formatted the local way',

    feature10Title: 'Simplified SSO Login',
    feature10Desc: 'Sign in quickly with Google or Apple Sign-In, secure and password-free',

    feature11Title: 'Customizable Categories',
    feature11Desc: 'Create and manage your own item categories with custom icons and colors',

    feature12Title: 'Instant notifications',
    feature12Desc: 'Get an alert for shares, changes and budget overruns',

    feature13Title: 'Visual Analytics',
    feature13Desc: 'Detailed charts of monthly expenses, top products and shopping trends',

    feature14Title: 'Email Preferences',
    feature14Desc: 'Customize your email notifications by type: alerts, daily or weekly summaries',

    feature15Title: 'Smart Voice Input',
    feature15Desc: 'Add items to your lists simply by speaking. Voice recognition in French and English with automatic quantity detection',

    feature16Title: 'Duplicate Detection',
    feature16Desc: 'Avoid duplicate items with our smart system that detects similarities and suggests merging or increasing quantities',

    feature17Title: 'Habit Suggestions',
    feature17Desc: 'Receive personalized suggestions based on your recurring purchases and intelligently analyzed consumption habits',

    feature18Title: 'Barcode Scanner',
    feature18Desc: 'Scan barcodes to quickly add products with nutritional information via OpenFoodFacts',

    feature19Title: 'List Messaging',
    feature19Desc: 'Talk with the members of your shared lists to coordinate your shopping',

    feature20Title: 'Receipt Management',
    feature20Desc: 'Attach receipt photos to your lists to track actual expenses and maintain a visual history',

    moreToDiscover: 'And much more to discover...',
    
    // Feature Categories
    essentialFeatures: 'Essential Features',
    collaborativeTools: 'Collaborative Tools',
    advancedTools: 'Advanced Tools',
    analyticsTools: 'Analytics Tools',
    securityTools: 'Security Tools',
    
    // Account Management Features
    accountManagement: 'Account Management',
    createAccount: 'Create user account',
    confirmEmail: 'Confirm account email',
    changePassword: 'Change password',
    loginAccount: 'Sign in',
    tokenManagement: 'Login token management',
    profileManagement: 'Edit profile',
    deleteAccount: 'Delete user account',
    cancelDeletion: 'Cancel account deletion',
    
    // List Management Features
    listManagement: 'List Management',
    createList: 'Create a list',
    editList: 'Edit a list',
    duplicateList: 'Duplicate a list',
    shareList: 'Share a list',
    deleteList: 'Delete a list',
    deepLinking: 'Deep linking tested',
    
    // Item Management Features
    itemManagement: 'Item Management',
    createItem: 'Create an item',
    editItem: 'Edit an item',
    itemSuggestions: 'Item suggestions',
    deleteSuggestionData: 'Delete suggestion data',
    
    // Budget Features
    budgetManagement: 'Budget Management',
    createBudget: 'Create a budget',
    editBudget: 'Edit a budget',
    disableBudget: 'Disable a budget',
    deleteBudget: 'Delete a budget',
    budgetFilter: 'Filter budgets',
    
    // Analytics Features
    analyticsFeatures: 'Analytics & Statistics',
    topProductsChart: 'Top products chart',
    expensesChart: 'Expenses chart',
    monthlyFilter: 'Filter by month',
    weeklyFilter: 'Filter by week',
    yearlyFilter: 'Filter by year',
    
    // Security Features
    securityFeatures: 'Security Features',
    emailVerification: 'Email verification',
    secureAuthentication: 'Secure authentication',
    passwordRecovery: 'Password recovery',
    accountProtection: 'Account protection',
    dataEncryption: 'Data encryption',
    
    // Collaboration Features
    collaborationFeatures: 'Collaborative Features',
    familyInvites: 'Family invitations',
    permissionManagement: 'Permission management',
    sharedLists: 'Shared lists',
    teamwork: 'Teamwork',
    
    // Advanced Analytics
    advancedAnalytics: 'Advanced Analytics',
    spendingPatterns: 'Spending patterns',
    topProducts: 'Top products',
    budgetTracking: 'Budget tracking',
    monthlyReports: 'Monthly reports',
    yearlyOverview: 'Yearly overview',
    
    // User Experience
    userExperience: 'User Experience',
    intuitivInterface: 'Intuitive interface',
    smartSuggestions: 'Smart suggestions',
    offlineAccess: 'Offline access',
    quickActions: 'Quick actions',
    seamlessNavigation: 'Seamless navigation',
    
    // Enhanced Benefits Section
    benefitsTitle: 'Transform your',
    benefitsTitleHighlight: 'daily life',
    benefitsSubtitle: 'What the app actually does — and what you can check for yourself on your first list',
    
    benefit1Title: 'Free, and ad-free',
    benefit1Desc: 'No subscription, no in-app purchase, no banner. Everything you see is available without paying.',
    
    benefit2Title: 'Bilingual all the way through',
    benefit2Desc: 'French and English across the whole app and in the emails you receive. Switch language without losing anything.',
    
    benefit3Title: 'Works offline',
    benefit3Desc: 'Your lists open and change with no network. What you do in the store syncs as soon as the connection is back.',
    
    benefit4Title: 'Your receipts are read on your phone',
    benefit4Desc: 'You photograph a receipt and the text is read on the device. The image is not analysed on our servers.',
    
    benefit5Title: 'One list for the whole household',
    benefit5Desc: 'Everyone adds, checks off and sees the same items, with the rights you choose: read, edit or admin.',
    
    benefit6Title: 'Budgets and alerts',
    benefit6Desc: 'Set a weekly or monthly budget, track spending, and get an alert before you go over.',
    
    // Testimonials
    testimonialsTitle: 'They adopted',
    testimonialsTitleHighlight: 'EpiList',
    testimonialsSubtitle: 'Feedback from people who use EpiList, published with their written consent',
    
    // Enhanced testimonials
    
    
    
    
    
    // CTA Section
    ctaTitle: 'Ready to revolutionize your shopping?',
    ctaSubtitle: 'Free, ad-free, and usable offline. On iOS and on Android.',
    
    // Footer
    footerDescription: 'The complete app that revolutionizes your way of shopping. Organize, share, budget and analyze your shopping habits with your family.',
    footerNewBrunswick: 'Proudly developed in New Brunswick, Canada',
    footerFeatures: 'Features',
    footerSupport2: 'Support',
    footerNewsletter: 'Stay informed about news',
    footerNewsletterDesc: 'Receive the latest updates and tips to optimize your shopping and budgets',
    footerNewsletterPlaceholder: 'Your email address',
    footerNewsletterButton: 'Subscribe',
    footerCopyright: '© 2024 EpiList. All rights reserved. Made with ❤️ in Canada.',
    
    // Footer links
    shoppingLists: 'Shopping lists',
    familySharing: 'Family sharing',
    synchronization: 'Synchronization',
    advancedSecurity: 'Advanced security',
    offlineMode: 'Offline mode',
    smartSuggestionsFooter: 'Smart suggestions',
    helpCenter: 'Help center',
    faq: 'FAQ',
    reportBug: 'Report a bug',
    featureRequest: 'Feature request',
    community: 'Community',
    privacyPolicy: 'Privacy policy',
    termsOfService: 'Terms of service',
    legalNotices: 'Legal notices',
    cookies: 'Cookies',
    
    // New Brunswick Section
    nbTitle: 'Proudly',
    nbTitleHighlight: 'New Brunswicker',
    nbSubtitle: 'Developed with passion in the Canadian Maritimes',
    nbDescription: 'EpiList was born in the heart of New Brunswick, a bilingual province recognized for its technological innovation and exceptional quality of life.',
    nbFeature1: 'Maritime Innovation',
    nbFeature1Desc: 'Cutting-edge technology developed in the Maritimes',
    nbFeature2: 'Natural bilingualism',
    nbFeature2Desc: 'Designed in an officially bilingual province',
    nbFeature3: 'Family values',
    nbFeature3Desc: 'Reflects the New Brunswick community spirit',
    nbWhyTitle: 'Why New Brunswick?',
    nbOfficiallyBilingual: 'Officially bilingual province',
    nbOfficiallyBilingualDesc: 'French and English on equal footing',
    nbMaritimeInnovation: 'Maritime innovation',
    nbMaritimeInnovationDesc: 'Atlantic technological hub',
    nbFamilyValues: 'Family values',
    nbFamilyValuesDesc: 'United and supportive community',
    nbQualityOfLife: 'Quality of life',
    nbQualityOfLifeDesc: 'Perfect work-family balance',
    nbCapital: 'Technological capital of the Maritimes',
    
    // Common
    activeUsers: 'active users',
    free: '100% Free',
    noHiddenFees: 'No hidden fees',
    adFree: 'Ad-free',
    pureExperience: 'Pure experience',
    quickInstall: 'Quick install',
    readyIn30s: 'Ready in 30 seconds',
    madeInCanada: 'Built in New Brunswick, Canada',
    language: 'en',
    availability: 'Availability',
    
    // Legal Pages Common
    backToHome: 'Back to Home',
    lastUpdated: 'Last updated',
    contactUsTitle: 'Contact Us',
    
    // Privacy Policy
    privacyPolicyTitle: 'Privacy Policy',
    privacyPolicySubtitle: 'What we collect, why, where it is kept, and what you can do about it.',
    
    // Privacy additional content
    bankLevelSecurity: 'Unreadable passwords',
    emailSupport: 'Email support',
    phoneSupport: 'Phone support',
    ourLocation: 'Our location',
    
    dataCollectionTitle: 'Data we collect',
    
    dataUsageTitle: 'How we use your data',
    
    dataSecurityTitle: 'Data security',
    
    userRightsTitle: 'Your rights',
    
    
    // Terms of Service
    termsOfServiceTitle: 'Terms of Service',
    termsOfServiceSubtitle: 'The rules and conditions that govern the use of EpiList.',
    
    // Terms additional content
    quickSummary: 'Quick Summary',
    quickSummaryDesc: 'Here are the essentials of our terms of service in a few key points.',
    freeToUse: 'Free to use',
    freeToUseDesc: 'EpiList is 100% free, no hidden fees',
    respectfulUse: 'Respectful use',
    respectfulUseDesc: 'Use the app ethically and legally',
    fairTerms: 'Fair terms',
    fairTermsDesc: 'Clear and transparent rules for everyone',
    legalTeam: 'Legal team',
    
    acceptanceTitle: 'Acceptance of Terms',
    acceptanceContent: 'By downloading, installing, or using the EpiList application, you agree to be bound by these terms of service. If you do not agree to these terms, please do not use our service.',
    
    serviceDescriptionTitle: 'Service Description',
    serviceDescriptionContent: 'EpiList is a free mobile application for creating, managing and sharing grocery lists with your household. The service includes list creation and management, sharing with per-person rights, instant notifications on changes, budgets, receipt reading and item suggestions.',
    
    userAccountTitle: 'User Account',
    userAccountContent: 'To use EpiList, you must create an account with a valid email address. You are responsible for maintaining the confidentiality of your login information and all activities that occur under your account.',
    
    listsAndSharingTitle: 'Lists and Sharing',
    listsAndSharingContent: 'You can create personal shopping lists and share them with your family or friends via secure links. You control access permissions (read, edit, admin) for each invited person.',
    
    acceptableUseTitle: 'Acceptable Use',
    acceptableUseContent: 'You agree to use EpiList legally and ethically. It is prohibited to use the service to violate laws, transmit offensive content, access other users\' accounts, or interfere with the normal operation of the service.',
    
    contentOwnershipTitle: 'Content Ownership',
    contentOwnershipContent: 'You retain ownership of your shopping lists and personal data. EpiList and its contents are protected by copyright laws. By using our service, you grant us a limited license to process your data to provide the service.',
    
    calculationsTitle: 'Calculations and Totals',
    calculationsContent: 'EpiList performs automatic calculations for your shopping totals and percentages of purchased items. While we strive to ensure accuracy, these calculations are provided for informational purposes.',
    
    serviceAvailabilityTitle: 'Service Availability',
    serviceAvailabilityContent: 'We strive to keep EpiList available 24/7, but we do not guarantee uninterrupted service. Scheduled maintenance or technical issues may occasionally affect availability.',
    
    limitationLiabilityTitle: 'Limitation of Liability',
    limitationLiabilityContent: 'EpiList is provided "as is" without warranty of any kind. We do not guarantee that the service will be uninterrupted or error-free. To the extent permitted by law, M2atech Solutions Inc. will not be liable for indirect, incidental, or consequential damages resulting from the use of the service.',
    
    suspensionTitle: 'Suspension and Termination',
    suspensionContent: 'We reserve the right to suspend or terminate your access to EpiList in case of violation of these terms. You can delete your account at any time from the application settings.',
    
    modificationsTitle: 'Modifications to Terms',
    modificationsContent: 'We reserve the right to modify these terms at any time. Significant changes will be communicated by email or in-app notification.',
    
    applicableLawTitle: 'Applicable Law',
    applicableLawContent: 'These terms are governed by the laws of Canada and the province of New Brunswick. Any dispute will be submitted to the exclusive jurisdiction of the courts of New Brunswick.',
    
    contactSupportTitle: 'Contact and Support',
    contactSupportContent: 'For any questions regarding these terms of service or if you need help, our team is at your disposal.',
    
    // Support Page
    supportTitle: 'Help Center',
    supportSubtitle: 'We\'re here to help. Find answers or contact our team.',
    
    // Support additional content
    howCanWeHelp: 'How can we help you?',
    chooseYourPreferredWay: 'Choose your preferred contact method to get the help you need.',
    immediate: 'Immediate',
    responseTime: 'Response time',
    browseHelpTopics: 'Browse help topics',
    findAnswersInOurKnowledgeBase: 'Find answers in our comprehensive knowledge base.',
    articles: 'articles',
    frequentlyAskedQuestions: 'Frequently Asked Questions',
    quickAnswersToCommonQuestions: 'Quick answers to the most common questions.',
    securityPrivacyTitle: 'Security & Privacy',
    securityPrivacyDesc: 'Protection of your data and privacy',
    troubleshootingTitle: 'Troubleshooting',
    troubleshootingDesc: 'Solutions to technical problems',
    localTeamAvailable: 'Local team available',
    satisfactionGuarantee: 'Satisfaction guarantee',
    satisfactionGuaranteeText: 'We are committed to providing you with the best possible support. Your satisfaction is our absolute priority.',
    happyUsers: 'happy users',
    
    emailSupportTitle: 'Email Support',
    emailSupportDesc: 'Send us a detailed message and we\'ll respond within 24 hours.',
    sendEmail: 'Send Email',
    
    phoneSupportTitle: 'Phone Support',
    phoneSupportDesc: 'Speak directly with our team Monday through Friday.',
    callUs: 'Call Us',
    
    liveChatTitle: 'Live Chat',
    liveChatDesc: 'Get immediate help through our online chat.',
    startChat: 'Start Chat',
    availableNow: 'Available now',
    
    supportCategoriesTitle: 'Help Categories',
    gettingStartedTitle: 'Getting Started',
    gettingStartedDesc: 'Guide to get started with EpiList',
    familySharingTitle: 'Family Sharing',
    familySharingDesc: 'How to share your lists',
    reportBugTitle: 'Report a Bug',
    reportBugDesc: 'Help us improve the app',
    featureRequestTitle: 'Feature Request',
    featureRequestDesc: 'Suggest improvements',
    
    faqTitle: 'Frequently Asked Questions',
    faq1Question: 'How do I create my first shopping list?',
    faq1Answer: 'Open the app, tap the "+" button and start adding your items. You can organize by categories and share with your family.',
    faq2Question: 'How do I share a list with my family?',
    faq2Answer: 'In your list, tap the share icon, then invite family members by email. They will receive an invitation to join the list.',
    faq3Question: 'Is my data synchronized across my devices?',
    faq3Answer: 'Your lists live in your account and show up on each of your devices. The app fetches changes when it opens and when you refresh, and an instant notification tells you what moved in a shared list.',
    faq4Question: 'Does the app work offline?',
    faq4Answer: 'Yes, you can view and edit your lists offline. Changes will be synchronized as soon as you regain an internet connection.',
    
    supportHoursTitle: 'Support Hours',
    mondayFriday: 'Monday - Friday',
    weekend: 'Weekend',
    holidays: 'Holidays',
    limitedSupport: 'Limited support',
    
    ourLocationTitle: 'Our Location',
    canada: 'Canada',
    
    satisfactionTitle: 'Your satisfaction, our priority',
    satisfactionText: 'We are committed to providing exceptional support to all our users.',
    satisfactionRate: 'Satisfaction rate',
    averageResponseTime: 'Average response time',
    
    // Contact Page
    contactTitle: 'Write to us',
    contactSubtitle: 'We\'re here to help. Send us a message and we\'ll respond quickly.',
    getInTouch: 'Get in Touch',
    contactFormDescription: 'Fill out the form below and we\'ll get back to you as soon as possible.',
    yourName: 'Your Name',
    namePlaceholder: 'John Doe',
    yourEmail: 'Your Email',
    emailPlaceholder: 'john@example.com',
    subject: 'Subject',
    selectSubject: 'Select a subject',
    technicalSupport: 'Technical Support',
    bugReport: 'Bug Report',
    partnership: 'Partnership',
    other: 'Other',
    message: 'Message',
    messagePlaceholder: 'Describe your request in detail...',
    sendMessage: 'Send Message',
    sending: 'Sending...',
    messageSent: 'Message Sent!',
    messageConfirmation: 'Thank you for your message. We\'ll respond within 24 hours.',
    contactInfo: 'Contact Information',
    emailUs: 'Email us',
    responseIn24h: 'Response within 24h',
    visitUs: 'Visit us',
    businessHours: 'Business Hours',
    closed: 'Closed',
    quickLinks: 'Quick Links',
    
    // Privacy Policy - Detailed Content
    dataCollectionTitleP: '1. Information Collection',
    dataCollectionContent: 'EpiList collects the following information:\n\n• Account: first name, last name, email address, password (never kept in clear text — only a hash is stored)\n• Lists: list names, items, quantities, prices, stores (optional)\n• Sharing: sharing links and access rights (read, edit, admin)\n• Receipts: the receipt photo, store, date and amounts — see the "Receipts and receipt photos" section\n• Usage: items checked off, totals and percentages computed\n• Technical: application error and performance logs\n• Device: a notification token, if you accept notifications\n\nLocation: if you allow it, the app reads your phone’s location to sort your stores from nearest to farthest. That location stays on the device — it is not stored and not sent to our servers. You can refuse it and give only your postal code.\n\nWe collect no sensitive data beyond what the service needs to work.',
    
    dataUsageTitleP: '2. Data Usage',
    dataUsageContent: 'Your data is used only to:\n\n• Create and manage your account\n• Create, edit, duplicate and delete your lists\n• Compute totals and the percentage of items bought\n• Share your lists with the people you choose, with the rights you set\n• Find your lists again on each of your devices\n• Track your budgets and alert you before you go over\n• Send you the emails tied to your account: verification, password change, deletion\n• Help you when you write to us\n\nWe do not sell, rent or trade any personal data.',
    receiptsTitle: 'Receipts and receipt photos',
    receiptsContent: 'When you photograph a receipt:\n\n• The text is read ON your phone. The image is not sent to an analysis service, and we do not analyse it on our servers.\n• You confirm what was read. Only the store, the date and the amounts are saved to your account, for your budgets and your history.\n• The photo, if you keep it, is stored privately with our cloud hosting provider. It has no public address: the app asks for a temporary link, valid for fifteen minutes, and only if you are allowed to see the list it belongs to.\n• The members of a shared list see that list’s receipts. Nobody else.\n• Your receipts and their photos are erased along with your account.',
    
    dataSecurityTitleP: '3. Storage and Security',
    dataSecurityContent: 'Your data is protected by:\n\n• Encrypted transport between the app and our servers\n• Passwords kept as a hash, never in clear text: we cannot read them\n• Two-step email verification, if you turn it on\n• Receipt photos kept private, which open only through a temporary link\n• Sharing links whose rights you set, revocable at any time\n• Regular backups\n\nNo system is beyond reach. If an incident affected your data, we would tell you.',
    
    dataSharingTitle: 'Data sharing',
    dataSharingContent: 'Your personal data is shared only in these cases:\n\n• With the people you authorize, by sharing a list or a space\n• With our technical providers, strictly to run the service: cloud hosting of the database and images, sending emails, sending notifications\n• With the authorities, where the law requires it\n\nSharing a list follows the rights you set:\n• Read-only: view, without changing\n• Edit: add, check off and remove items\n• Admin: manage everything, including deleting the list\n\nNo commercial sharing takes place.',
    
    userRightsTitleP: '5. Your Rights',
    userRightsContent: 'You have the right to:\n\n• Access your personal data\n• Correct your account information (first name, last name, email)\n• Delete your account and the data attached to it — from the app, or from the account deletion page on this site\n• Export your receipts as PDF or CSV from the app\n• Revoke a sharing link, or change a member’s rights, at any time\n• Delete a list or an item one at a time\n• Withdraw your consent to our news emails without losing your account\n\nWrite to us to exercise a right the app does not cover yet.',
    accountDeletionTitle: 'Deleting your account',
    accountDeletionContent: 'You can delete your account from the app — Profile, then Security — or from the account deletion page on this site if you no longer have the app. Either way, an email confirmation is required: nobody can delete your account without access to your inbox.\n\nWhat happens as soon as you confirm:\n\n• Your first name, last name, email address, password and profile photo are erased\n• Your personal lists, your receipts and their photos, your budgets, your inventory, your purchase history and your preferences are destroyed\n• Your devices, sign-in tokens and external sign-in links are revoked\n• The lists and spaces you shared are handed over to another member who can administer them, so they do not lose their groceries; those nobody else can take over are destroyed\n• Your messages in shared conversations stay, signed "Deleted user", so the other members’ history keeps its thread\n\nThe empty row left in our database is destroyed within thirty days of the deletion. Your email address becomes available again: you can create a new account with it.',
    
    appFeaturesTitle: 'Application features',
    appFeaturesContent: 'EpiList processes your data to offer the following features:\n\n• Creation and management of user accounts\n• Creation, duplication, modification and deletion of lists\n• Adding items with name, quantity, price and store (optional)\n• Marking items as purchased or deleting items\n• Automatic calculation of purchase totals and percentages\n• Generation of secure sharing links\n• Management of collaborative access permissions\n\nAll this data remains under your control.',
    measurementTitle: 'Audience measurement',
    measurementContent: 'In the app: no measurement tool. No usage event is sent to a third party. The only outgoing traffic is what makes the service work — our servers, sending emails and sending notifications.\n\nOn this website: we use third-party audience measurement tools, to know how many people visit the pages and where they come from. They set cookies and record technical information: pages viewed, referrer, device type. They have no access to the contents of your EpiList account — this site never reads it.\n\nYou can block them by refusing cookies in your browser. A consent setting for the site is in preparation.',
    
    cookiesTitle: 'Cookies and similar technologies',
    cookiesContent: 'In the app: no advertising cookie. The app keeps on your phone what it needs to recognise you from one launch to the next — a sign-in token — plus your display preferences, such as language and theme.\n\nOn this site: your language choice is kept by your browser, and the audience measurement tools described in the previous section set their own cookies. You can clear all of it from your browser; the site stays usable.\n\nWe use no cookie to show you advertising: there is none in EpiList.',
    privacyModificationsTitle: 'Changes to this policy',
    privacyModificationsContent: 'This policy may be updated to follow changes in the app. Significant changes will be announced by email to your account address, and the date at the top of this page will change.',
    privacyUpdatedDate: 'October 29, 2026',
    dataResidencyCanada: 'Our servers and image storage are located in Canada.',
    
    modificationsTitleP: '8. Modifications',
    modificationsContentP: 'This policy may be updated to reflect application developments. We will inform you of important changes by:\n\n• Email to the address associated with your account\n• Updating the date at the top of this policy\n\nYour continued use of the application after modifications constitutes your acceptance.',
    
    contactTitleP: '9. Contact',
    contactContent: 'For any questions regarding this privacy policy or your data, please contact us via our website.\n\nWe are committed to responding within 48 business hours.',
    
    // Additional privacy terms
    encryptedStorage: 'Kept as a hash, even from us',
    dataProtection: 'Private receipt photos',
    industryStandards: 'Opened by a fifteen-minute link',
    userControl: 'Real deletion',
    fullDataControl: 'Your data erased, not just deactivated',
    allRightsReserved: 'All rights reserved',

    // Footer
    footerTagline: 'Simplify your shopping',
    application: 'Application',
    support: 'Support',
    company: 'Company',
    legal: 'Legal',
    contactUs: 'Contact us',
    about: 'About',
    newBrunswick: '🍁 New Brunswick',
    privacy: 'Privacy',
    terms: 'Terms',
    comparison: 'Comparison',
    stayInformed: 'Stay informed 📬',
    newsletterDescription: 'New features, shopping tips and exclusive updates',
    subscribe: 'Subscribe',
    copyright: '© EpiList — M2atech Solutions Inc. All rights reserved.',
    madeWith: 'Made with',
    inNewBrunswick: 'in New Brunswick',
    // New 2026 features (price & household intelligence)
    featureScanTitle: 'Receipt scanner',
    featureScanDesc: 'Snap your receipt: EpiList reads items and prices, you confirm, your history fills itself.',
    featurePricesTitle: 'Price comparison',
    featurePricesDesc: 'Compare the cost of your list across your stores, based on the real prices you paid.',
    featurePredictTitle: 'Predictive suggestions',
    featurePredictDesc: '"You are probably out of milk": EpiList learns your habits and warns you before you run out.',
    featureInventoryTitle: 'Home inventory',
    featureInventoryDesc: 'Sorted by zone — pantry, fridge, freezer, household — and linked to your lists.',
    featureStoreModeTitle: 'In-store mode',
    featureStoreModeDesc: 'Your list sorted aisle by aisle for your store, with progress that follows what you pick up.',
    featureMealsTitle: 'Meal planner',
    featureMealsDesc: 'Pick your meals; EpiList consolidates the ingredients and builds the list around your inventory.',
    switchToEnglish: 'English version',
    switchToFrench: 'Version française',
    navigation: 'Navigation',
    product: 'Product',
    // About page
    aboutPageTitle: 'About EpiList',
    aboutPageSubtitle: 'A team based in New Brunswick, dedicated to making groceries simpler for Canadian families.',
    aboutMissionTitle: 'Our mission',
    aboutMissionText: 'Simplify how families get organized: shared lists, a budget under control and faster shopping trips, without needless complexity.',
    aboutValuesTitle: 'Our values',
    aboutValue1Title: 'Family first',
    aboutValue1Desc: 'Tools that strengthen collaboration and simplify daily life for the whole household.',
    aboutValue2Title: 'Local innovation',
    aboutValue2Desc: 'Designed and built in New Brunswick, in the heart of the Maritimes.',
    aboutValue3Title: 'Listening to users',
    aboutValue3Desc: 'Every piece of feedback counts: the app evolves with the real needs of families.',
    aboutStatsTitle: 'EpiList at a glance',
    aboutStat1Value: '2024',
    aboutStat1Label: 'Founded',
    aboutStat2Value: '100%',
    aboutStat2Label: 'Free, ad-free',
    aboutStat3Value: '2',
    aboutStat3Label: 'Languages (French, English)',
    aboutStat4Value: 'Offline',
    aboutStat4Label: 'Lists available with no network',
    aboutTeamTitle: 'A Maritime team',
    aboutTeamText: 'EpiList is built by M2atech Solutions Inc., a team combining technical expertise with a practical understanding of Canadian families.',
    // Help page
    helpPageTitle: 'Help center',
    helpPageSubtitle: 'Find answers quickly, or write to our New Brunswick team.',
    helpFaqTitle: 'Frequently asked questions',
    helpFaq1Q: 'Is EpiList really free?',
    helpFaq1A: 'Yes, EpiList is completely free: no hidden fees, no subscription, no ads.',
    helpFaq2Q: 'How do I share my lists with my family?',
    helpFaq2A: 'Create your list then share it by link or invitation. Each member gets an instant notification when an item changes.',
    helpFaq3Q: 'Does the app work offline?',
    helpFaq3A: 'Yes. Your lists stay available without a connection and sync as soon as you are back online.',
    helpFaq4Q: 'Which platforms is EpiList available on?',
    helpFaq4A: 'iOS (App Store) and Android (Google Play), with sync across all your devices.',
    helpFaq5Q: 'Is my data secure?',
    helpFaq5A: 'Your data is protected and never sold. See our privacy policy for details.',
    helpFaq6Q: 'How does the receipt scanner work?',
    helpFaq6A: 'Snap a photo of your receipt: the app reads items and prices on your phone, you fix anything if needed, and your price history builds itself.',
    helpContactTitle: 'Need personalized help?',
    helpContactText: 'Our team is here to help, in French or English.',
    helpResponseTime: 'Reply within 24 hours',
    // Download page
    dlBadge: 'Free download',
    dlTitle: 'Download EpiList',
    dlSubtitle: 'Shared lists, budget, receipt scanner and price comparison. Free, ad-free, offline-ready.',
    dlOnStore: 'Download on',
    dlFeature1Title: 'Quick install',
    dlFeature1Desc: 'Ready in under a minute',
    dlFeature2Title: 'Free forever',
    dlFeature2Desc: 'No hidden fees',
    dlFeature3Title: 'Built in Canada',
    dlFeature3Desc: 'New Brunswick, Canada',
    dlScreensTitle: 'App preview',
    dlShot1Title: 'Smart lists',
    dlShot1Desc: 'Create and organize your lists with ease',
    dlShot2Title: 'Detailed analytics',
    dlShot2Desc: 'Track your shopping habits',
    dlShot3Title: 'Budget under control',
    dlShot3Desc: 'Keep a close eye on your spending',
    // Comparison page
    cmpTitle: 'Why choose EpiList?',
    cmpSubtitle: 'A factual comparison with the main grocery list apps.',
    cmpColFeatures: 'Features',
    cmpRowPrice: 'Price',
    cmpRowShare: 'Family sharing',
    cmpRowOffline: 'Offline mode',
    cmpRowNoAds: 'Ad-free',
    cmpRowSuggestions: 'Smart suggestions',
    cmpRowPrices: 'Store price comparison',
    cmpFreeForever: 'Free forever',
    cmpWhyTitle: 'What sets EpiList apart',
    cmpWhy1Title: '100% free',
    cmpWhy1Desc: 'No subscription, no premium tier',
    cmpWhy2Title: 'Works everywhere',
    cmpWhy2Desc: 'Full offline mode, synced data',
    cmpWhy3Title: 'Built in Canada',
    cmpWhy3Desc: 'Bilingual, multi-currency, made for families here',

    // Account deletion from the website
    delTitle: 'Delete your EpiList account',
    delFooterLink: 'Delete my account',
    delIntro: 'You can delete your account from the app, under Profile then Security. If you no longer have the app, use this form: we will email you a confirmation link.',
    delEmailLabel: 'Your email address',
    delEmailPlaceholder: 'you@example.com',
    delSubmit: 'Send the confirmation link',
    delSending: 'Sending...',
    delSentTitle: 'Check your email',
    delWhatTitle: 'What will be erased',
    delWhat1: 'Your name, email address and password',
    delWhat2: 'Your personal lists, their items and their history',
    delWhat3: 'Your receipts and receipt photos',
    delWhat4: 'Your budgets, your inventory and your preferences',
    delKeptTitle: 'What is handed over',
    delKept1: 'Lists you share with other people are handed over to them, so they do not lose their groceries.',
    delKept2: 'Your messages in shared conversations stay, signed “Deleted user”.',
    delDelayTitle: 'How long it takes',
    delDelayText: 'Your personal data is erased as soon as you confirm. The empty row that remains is destroyed within thirty days.',
    delHelpText: 'A question before you decide? Write to us.',
    delInvalidEmail: 'Please enter a valid email address.',
    delFailed: 'Sending failed. Try again in a moment, or write to us.',
    delConfirmChecking: 'Checking the link...',
    delConfirmOkTitle: 'Account deleted',
    delConfirmErrorTitle: 'Link no longer valid',
    delBackHome: 'Back to home',

  }
};

export type Language = 'fr' | 'en';
export type TranslationKey = keyof typeof translations.fr;