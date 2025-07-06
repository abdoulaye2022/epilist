'use client';

import { Smartphone, Facebook, Twitter, Instagram, Mail } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLanguage } from '@/hooks/useLanguage';

export default function Footer() {
  const { t } = useLanguage();

  return (
    <footer className="bg-gray-900 text-white relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-64 h-64 bg-epilist-green/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-80 h-80 bg-epilist-blue/10 rounded-full blur-3xl"></div>
      </div>

      <div className="container mx-auto px-4 py-16 relative z-10">
        
        {/* Main Footer Content */}
        <div className="text-center mb-12">
          {/* Logo */}
          <div className="flex items-center justify-center space-x-3 mb-6">
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-epilist rounded-2xl blur-lg opacity-50"></div>
              <div className="relative bg-gradient-epilist p-3 rounded-2xl shadow-lg">
                <Smartphone className="h-8 w-8 text-white" />
              </div>
            </div>
            <div>
              <span className="text-3xl font-bold bg-gradient-epilist bg-clip-text text-transparent">
                EpiList
              </span>
              <div className="text-gray-400 text-sm">{t('language') === 'fr' ? 'Simplifiez vos courses' : 'Simplify your shopping'}</div>
            </div>
          </div>

          {/* Description */}
          <p className="text-gray-400 mb-8 leading-relaxed text-lg max-w-2xl mx-auto">
            {t('footerDescription')}
          </p>

          {/* Social Media */}
          <div className="flex justify-center space-x-4 mb-8">
            {[
              { icon: Facebook, label: 'Facebook' },
              { icon: Twitter, label: 'Twitter' },
              { icon: Instagram, label: 'Instagram' },
              { icon: Mail, label: 'Email' }
            ].map((social, index) => (
              <Button
                key={index}
                size="sm"
                variant="ghost"
                className="hover:bg-epilist-green/20 hover:text-epilist-green transition-all duration-300 group"
                aria-label={social.label}
              >
                <social.icon className="h-5 w-5 group-hover:scale-110 transition-transform duration-300" />
              </Button>
            ))}
          </div>

          {/* Quick Links */}
          <div className="flex flex-wrap justify-center gap-6 mb-8">
            {[
              { text: t('privacyPolicy'), href: '/privacy' },
              { text: t('termsOfService'), href: '/terms' },
              { text: t('helpCenter'), href: '/support' },
              { text: t('contact'), href: '/contact' }
            ].map((link, index) => (
              <a
                key={index}
                href={link.href}
                className="text-gray-400 hover:text-epilist-green transition-colors duration-300 text-sm"
              >
                {link.text}
              </a>
            ))}
          </div>
        </div>

        {/* Newsletter Section */}
        <div className="border-t border-gray-800 pt-8 mb-8">
          <div className="bg-gradient-to-r from-epilist-green/10 to-epilist-blue/10 rounded-2xl p-8 text-center max-w-2xl mx-auto">
            <h3 className="text-2xl font-bold mb-4">{t('footerNewsletter')}</h3>
            <p className="text-gray-400 mb-6">
              {t('footerNewsletterDesc')}
            </p>
            <div className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
              <input
                type="email"
                placeholder={t('footerNewsletterPlaceholder')}
                className="flex-1 px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:border-epilist-green transition-colors duration-300"
              />
              <Button className="bg-gradient-epilist hover:shadow-glow-green text-white px-6 py-3">
                {t('footerNewsletterButton')}
              </Button>
            </div>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="text-center">
          <p className="text-gray-400 text-sm">
            {t('footerCopyright')}
          </p>
        </div>
      </div>
    </footer>
  );
}