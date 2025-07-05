'use client';

import { Smartphone, Facebook, Twitter, Instagram, Mail, MapPin, Phone, Clock } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useLanguage } from '@/hooks/useLanguage';

export default function Footer() {
  const { t } = useLanguage();

  return (
    <footer id="contact" className="bg-gray-900 text-white relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-20 w-64 h-64 bg-epilist-green/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-80 h-80 bg-epilist-blue/10 rounded-full blur-3xl"></div>
      </div>

      <div className="container mx-auto px-4 py-16 relative z-10">
        <div className="grid md:grid-cols-4 gap-12">
          {/* Brand Section */}
          <div className="col-span-1 md:col-span-2">
            <div className="flex items-center space-x-3 mb-6">
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
            <p className="text-gray-400 mb-8 leading-relaxed text-lg">
              {t('footerDescription')}
            </p>
            
            {/* Contact Info */}
            <div className="space-y-4 mb-8">
              <div className="flex items-center space-x-3 text-gray-400">
                <MapPin className="h-5 w-5 text-epilist-green" />
                <span>{t('footerAddress')}</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-400">
                <Phone className="h-5 w-5 text-epilist-blue" />
                <span>{t('footerPhone')}</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-400">
                <Clock className="h-5 w-5 text-epilist-green" />
                <span>{t('footerSupport')}</span>
              </div>
            </div>

            {/* Social Media */}
            <div className="flex space-x-4">
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
          </div>

          {/* Features Links */}
          <div>
            <h3 className="text-xl font-bold mb-6 text-white">{t('footerFeatures')}</h3>
            <ul className="space-y-3">
              {[
                t('shoppingLists'),
                t('familySharing'),
                t('synchronization'),
                t('advancedSecurity'),
                t('offlineMode'),
                t('smartSuggestions')
              ].map((item, index) => (
                <li key={index}>
                  <a 
                    href="#" 
                    className="text-gray-400 hover:text-epilist-green transition-colors duration-300 flex items-center space-x-2 group"
                  >
                    <div className="w-1 h-1 bg-epilist-green rounded-full group-hover:scale-150 transition-transform duration-300"></div>
                    <span>{item}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Support Links */}
          <div>
            <h3 className="text-xl font-bold mb-6 text-white">{t('footerSupport2')}</h3>
            <ul className="space-y-3">
              {[
                t('helpCenter'),
                t('contact'),
                t('faq'),
                t('reportBug'),
                t('featureRequest'),
                t('community')
              ].map((item, index) => (
                <li key={index}>
                  <a 
                    href={
                      item === t('helpCenter') ? '/support' :
                      item === t('contact') ? '#contact' :
                      '#'
                    }
                    className="text-gray-400 hover:text-epilist-blue transition-colors duration-300 flex items-center space-x-2 group"
                  >
                    <div className="w-1 h-1 bg-epilist-blue rounded-full group-hover:scale-150 transition-transform duration-300"></div>
                    <span>{item}</span>
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Newsletter Section */}
        <div className="border-t border-gray-800 mt-12 pt-8">
          <div className="bg-gradient-to-r from-epilist-green/10 to-epilist-blue/10 rounded-2xl p-8 text-center">
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
        <div className="border-t border-gray-800 mt-12 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p className="text-gray-400 text-sm mb-4 md:mb-0">
            {t('footerCopyright')}
          </p>
          <div className="flex flex-wrap gap-6">
            {[
              t('privacyPolicy'),
              t('termsOfService'),
              t('legalNotices'),
              t('cookies')
            ].map((link, index) => (
              <a
                key={index}
                href={
                  link === t('privacyPolicy') ? '/privacy' :
                  link === t('termsOfService') ? '/terms' :
                  '#'
                }
                className="text-gray-400 hover:text-epilist-green transition-colors duration-300 text-sm"
              >
                {link}
              </a>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}