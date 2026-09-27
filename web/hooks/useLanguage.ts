'use client';

// hooks/useLanguage.ts - La langue est portée par l'URL (/en/... = anglais,
// slugs français sinon). Changer de langue = naviguer vers le chemin
// équivalent. localStorage ne sert qu'à mémoriser la préférence.
import { useState, useEffect, createContext, useContext } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { translations, Language, TranslationKey } from '@/lib/translations';
import { languageFromPath, counterpartPath } from '@/lib/routes';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: TranslationKey) => string;
}

export const LanguageContext = createContext<LanguageContextType | undefined>(
  undefined
);

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
}

export function useLanguageState() {
  const pathname = usePathname() ?? '/';
  const router = useRouter();
  const urlLanguage = languageFromPath(pathname) as Language;
  const [language, setLanguageState] = useState<Language>(urlLanguage);

  // L'URL est la source de vérité : chaque navigation la fait suivre.
  useEffect(() => {
    setLanguageState(urlLanguage);
    try {
      localStorage.setItem('epilist-language', urlLanguage);
      document.documentElement.lang = urlLanguage;
    } catch {}
  }, [urlLanguage]);

  const setLanguage = (lang: Language) => {
    if (lang === language) return;
    try {
      localStorage.setItem('epilist-language', lang);
    } catch {}
    router.push(counterpartPath(pathname, lang));
  };

  const t = (key: TranslationKey): string => {
    return translations[language][key] || key;
  };

  return { language, setLanguage, t };
}
