'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Globe } from 'lucide-react';

export default function LanguageToggle() {
  const { language, setLanguage } = useLanguage();

  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={() => setLanguage(language === 'fr' ? 'en' : 'fr')}
      className="flex items-center space-x-2 hover:bg-epilist-green/10 hover:text-epilist-green transition-all duration-300 group"
    >
      <Globe className="h-4 w-4 group-hover:scale-110 transition-transform duration-300" />
      <span className="font-medium">
        {language === 'fr' ? 'EN' : 'FR'}
      </span>
    </Button>
  );
}