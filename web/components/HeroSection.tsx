'use client';

import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Download, Star, ArrowDown, Play, Users, Clock, Shield } from 'lucide-react';
import { useLanguage } from '@/hooks/useLanguage';

export default function HeroSection() {
  const [isVisible, setIsVisible] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const { t } = useLanguage();

  useEffect(() => {
    setIsVisible(true);
    
    const handleMouseMove = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  const scrollToFeatures = () => {
    const element = document.getElementById('fonctionnalites');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section className="min-h-screen bg-gradient-mesh relative overflow-hidden">
      {/* Animated Background Elements */}
      <div className="absolute inset-0">
        <div 
          className="absolute w-96 h-96 bg-gradient-to-r from-epilist-green/20 to-epilist-blue/20 rounded-full blur-3xl animate-float"
          style={{
            left: `${20 + mousePosition.x * 0.02}%`,
            top: `${10 + mousePosition.y * 0.02}%`,
          }}
        ></div>
        <div 
          className="absolute w-80 h-80 bg-gradient-to-r from-epilist-blue/20 to-epilist-green/20 rounded-full blur-3xl animate-float-reverse"
          style={{
            right: `${15 + mousePosition.x * 0.015}%`,
            bottom: `${20 + mousePosition.y * 0.015}%`,
          }}
        ></div>
        <div className="absolute top-1/2 left-1/2 w-[600px] h-[600px] bg-gradient-to-r from-epilist-green/10 to-epilist-blue/10 rounded-full blur-3xl animate-pulse-gentle transform -translate-x-1/2 -translate-y-1/2"></div>
      </div>

      <div className="container mx-auto px-4 pt-32 pb-16 relative z-10">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Left Content */}
          <div className={`space-y-8 ${isVisible ? 'animate-slide-in-left' : 'opacity-0'}`}>
            {/* Trust Indicators */}
            <div className="flex flex-wrap items-center gap-6 text-sm">
              <div className="flex items-center space-x-2 bg-white/80 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
                <div className="flex space-x-1">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="h-4 w-4 fill-epilist-green text-epilist-green" />
                  ))}
                </div>
                <span className="font-semibold text-gray-700">4.9/5</span>
              </div>
              <div className="flex items-center space-x-2 bg-white/80 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
                <Users className="h-4 w-4 text-epilist-blue" />
                <span className="font-semibold text-gray-700">50k+ {t('activeUsers')}</span>
              </div>
              <div className="flex items-center space-x-2 bg-white/80 backdrop-blur-sm rounded-full px-4 py-2 shadow-lg">
                <Shield className="h-4 w-4 text-epilist-green" />
                <span className="font-semibold text-gray-700">100% {t('secureData')}</span>
              </div>
            </div>

            {/* Main Headline */}
            <div className="space-y-6">
              <h1 className="text-5xl md:text-7xl font-bold text-gray-900 leading-tight">
                {t('heroTitle')}{' '}
                <span className="relative">
                  <span className="bg-gradient-epilist bg-clip-text text-transparent">
                    {t('heroTitleHighlight')}
                  </span>
                  <div className="absolute -bottom-2 left-0 right-0 h-1 bg-gradient-epilist rounded-full animate-shimmer"></div>
                </span>
              </h1>
              <p className="text-xl md:text-2xl text-gray-600 leading-relaxed max-w-2xl">
                {t('heroSubtitle')}{' '}
                <span className="text-epilist-green font-semibold">{t('heroSubtitleHighlight')}</span>
              </p>
            </div>

            {/* Key Benefits */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {[
                { icon: Clock, text: t('timeSaved'), color: 'text-epilist-green' },
                { icon: Users, text: t('familySync'), color: 'text-epilist-blue' },
                { icon: Shield, text: t('secureData'), color: 'text-epilist-green' }
              ].map((benefit, index) => (
                <div key={index} className="flex items-center space-x-3 bg-white/60 backdrop-blur-sm rounded-2xl p-4 shadow-lg hover:shadow-xl transition-all duration-300 group">
                  <benefit.icon className={`h-6 w-6 ${benefit.color} group-hover:scale-110 transition-transform duration-300`} />
                  <span className="text-sm font-medium text-gray-700">{benefit.text}</span>
                </div>
              ))}
            </div>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4">
              <Button
                size="lg"
                className="bg-gradient-epilist hover:shadow-glow-green text-white group transition-all duration-300 transform hover:scale-105 relative overflow-hidden"
              >
                <span className="relative z-10 flex items-center">
                  <Download className="mr-3 h-5 w-5 group-hover:animate-bounce-gentle" />
                  {t('downloadNow')}
                </span>
                <div className="absolute inset-0 bg-gradient-epilist-reverse opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
              </Button>
              <Button
                size="lg"
                variant="outline"
                className="border-2 border-epilist-blue text-epilist-blue hover:bg-epilist-blue hover:text-white transition-all duration-300 group relative overflow-hidden"
              >
                <span className="relative z-10 flex items-center">
                  <Play className="mr-3 h-5 w-5 group-hover:animate-bounce-gentle" />
                  {t('watchDemo')}
                </span>
                <div className="absolute inset-0 bg-epilist-blue transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></div>
              </Button>
            </div>

            {/* Social Proof */}
            <div className="flex items-center space-x-8 text-sm text-gray-500 pt-4">
              <div className="flex items-center space-x-2">
                <div className="w-3 h-3 bg-epilist-green rounded-full animate-pulse-gentle"></div>
                <span>{t('freeForLife')}</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="w-3 h-3 bg-epilist-blue rounded-full animate-pulse-gentle"></div>
                <span>{t('noAds')}</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="w-3 h-3 bg-epilist-green rounded-full animate-pulse-gentle"></div>
                <span>{t('instantInstall')}</span>
              </div>
            </div>
          </div>

          {/* Right Content - Phone Mockup */}
          <div className={`relative ${isVisible ? 'animate-slide-in-right' : 'opacity-0'}`}>
            <div className="relative mx-auto w-80 h-[640px] perspective-1000">
              {/* Phone Frame */}
              <div className="relative w-full h-full bg-gray-900 rounded-[3rem] p-4 shadow-2xl animate-phone-float">
                {/* Screen */}
                <div className="w-full h-full bg-gradient-to-br from-epilist-green via-epilist-blue to-epilist-green rounded-[2.5rem] p-8 flex flex-col relative overflow-hidden">
                  {/* Screen Content */}
                  <div className="text-white space-y-6 relative z-10">
                    {/* Header */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <div className="w-8 h-8 bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11z"/>
                          </svg>
                        </div>
                        <span className="font-bold text-lg">EpiList</span>
                      </div>
                      <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
                        <Users className="w-4 h-4" />
                      </div>
                    </div>

                    {/* List Title */}
                    <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4">
                      <h3 className="font-bold text-lg mb-2">{t('language') === 'fr' ? 'Courses de la semaine' : 'Weekly shopping'}</h3>
                      <p className="text-white/80 text-sm">{t('language') === 'fr' ? 'Partagé avec la famille • 8 articles' : 'Shared with family • 8 items'}</p>
                    </div>

                    {/* Shopping Items */}
                    <div className="space-y-3">
                      {[
                        { name: 'Lait bio', checked: false, urgent: true },
                        { name: 'Pain complet', checked: true, urgent: false },
                        { name: 'Pommes rouges', checked: false, urgent: false },
                        { name: 'Yaourts nature', checked: true, urgent: false },
                        { name: 'Pâtes complètes', checked: false, urgent: false },
                      ].map((item, index) => (
                        <div key={index} className={`flex items-center space-x-3 bg-white/10 backdrop-blur-sm rounded-xl p-3 transition-all duration-300 ${item.checked ? 'opacity-60' : ''}`}>
                          <div className={`w-5 h-5 rounded-full border-2 border-white flex items-center justify-center ${item.checked ? 'bg-white' : ''}`}>
                            {item.checked && <div className="w-2 h-2 bg-epilist-green rounded-full"></div>}
                          </div>
                          <span className={`flex-1 ${item.checked ? 'line-through' : ''}`}>{item.name}</span>
                          {item.urgent && <div className="w-2 h-2 bg-red-400 rounded-full animate-pulse-gentle"></div>}
                        </div>
                      ))}
                    </div>

                    {/* Add Button */}
                    <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 flex items-center justify-center space-x-2 cursor-pointer hover:bg-white/30 transition-colors duration-300">
                      <div className="w-5 h-5 bg-white rounded-full flex items-center justify-center">
                        <span className="text-epilist-green text-lg font-bold">+</span>
                      </div>
                      <span>{t('language') === 'fr' ? 'Ajouter un article' : 'Add item'}</span>
                    </div>
                  </div>

                  {/* Animated Background Elements */}
                  <div className="absolute inset-0 opacity-30">
                    <div className="absolute top-10 right-10 w-20 h-20 bg-white/20 rounded-full blur-xl animate-float"></div>
                    <div className="absolute bottom-20 left-10 w-16 h-16 bg-white/20 rounded-full blur-xl animate-float-reverse"></div>
                  </div>
                </div>
              </div>

              {/* Floating Elements */}
              <div className="absolute -top-8 -right-8 bg-white rounded-2xl p-4 shadow-xl animate-float">
                <div className="flex items-center space-x-2">
                  <div className="w-3 h-3 bg-epilist-green rounded-full animate-pulse-gentle"></div>
                  <span className="text-sm font-medium text-gray-700">{t('synchronized')}</span>
                </div>
              </div>
              <div className="absolute -bottom-8 -left-8 bg-white rounded-2xl p-4 shadow-xl animate-float-reverse">
                <div className="flex items-center space-x-2">
                  <Users className="w-4 h-4 text-epilist-blue" />
                  <span className="text-sm font-medium text-gray-700">3 {t('members')}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll Indicator */}
        <div className="text-center mt-20">
          <button
            onClick={scrollToFeatures}
            className="inline-flex flex-col items-center space-y-2 text-gray-500 hover:text-epilist-green transition-colors group"
          >
            <span className="text-sm font-medium">{t('discoverFeatures')}</span>
            <ArrowDown className="h-6 w-6 group-hover:animate-bounce-gentle" />
          </button>
        </div>
      </div>
    </section>
  );
}