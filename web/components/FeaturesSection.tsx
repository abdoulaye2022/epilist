'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { 
  ListChecks, 
  Share2, 
  Copy, 
  Shield, 
  Clock, 
  Users,
  Smartphone,
  Zap,
  Heart
} from 'lucide-react';
import { useLanguage } from '@/hooks/useLanguage';

const features = [
  {
    icon: ListChecks,
    titleKey: 'feature1Title',
    descKey: 'feature1Desc',
    color: 'from-epilist-green to-epilist-green-light',
    delay: 0
  },
  {
    icon: Share2,
    titleKey: 'feature2Title',
    descKey: 'feature2Desc',
    color: 'from-epilist-blue to-epilist-blue-light',
    delay: 100
  },
  {
    icon: Copy,
    titleKey: 'feature3Title',
    descKey: 'feature3Desc',
    color: 'from-epilist-green to-epilist-green-light',
    delay: 200
  },
  {
    icon: Shield,
    titleKey: 'feature4Title',
    descKey: 'feature4Desc',
    color: 'from-epilist-blue to-epilist-blue-light',
    delay: 300
  },
  {
    icon: Zap,
    titleKey: 'feature5Title',
    descKey: 'feature5Desc',
    color: 'from-epilist-green to-epilist-green-light',
    delay: 400
  },
  {
    icon: Heart,
    titleKey: 'feature6Title',
    descKey: 'feature6Desc',
    color: 'from-epilist-blue to-epilist-blue-light',
    delay: 500
  }
];

export default function FeaturesSection() {
  const [visibleItems, setVisibleItems] = useState<number[]>([]);
  const { t } = useLanguage();

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = parseInt(entry.target.getAttribute('data-index') || '0');
            setTimeout(() => {
              setVisibleItems(prev => [...prev, index]);
            }, features[index].delay);
          }
        });
      },
      { threshold: 0.1 }
    );

    const elements = document.querySelectorAll('[data-feature-index]');
    elements.forEach(el => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  return (
    <section id="fonctionnalites" className="py-24 bg-gradient-to-br from-white via-epilist-gray-50 to-white relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 left-10 w-72 h-72 bg-epilist-green/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-20 right-10 w-80 h-80 bg-epilist-blue/10 rounded-full blur-3xl animate-float-reverse"></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <div className="text-center mb-20">
          <div className="inline-flex items-center space-x-2 bg-gradient-epilist text-white px-6 py-2 rounded-full text-sm font-medium mb-6">
            <Smartphone className="h-4 w-4" />
            <span>{t('advancedFeatures')}</span>
          </div>
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            {t('featuresTitle')}{' '}
            <span className="bg-gradient-epilist bg-clip-text text-transparent">
              {t('featuresTitleHighlight')}
            </span>
          </h2>
          <p className="text-xl md:text-2xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
            {t('featuresSubtitle')}
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <Card
              key={index}
              data-feature-index={index}
              className={`group hover:shadow-card-hover transition-all duration-500 cursor-pointer border-0 shadow-lg bg-white/80 backdrop-blur-sm hover:bg-white ${
                visibleItems.includes(index) ? 'animate-fade-in-up' : 'opacity-0'
              }`}
            >
              <CardContent className="p-8 relative overflow-hidden">
                {/* Background Gradient */}
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.color} opacity-0 group-hover:opacity-5 transition-opacity duration-300`}></div>
                
                {/* Icon */}
                <div className="relative mb-6">
                  <div className={`w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl flex items-center justify-center group-hover:scale-110 group-hover:rotate-3 transition-all duration-300 shadow-lg`}>
                    <feature.icon className="h-8 w-8 text-white" />
                  </div>
                  <div className={`absolute inset-0 w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity duration-300`}></div>
                </div>

                {/* Content */}
                <div className="relative">
                  <h3 className="text-xl font-bold text-gray-900 mb-4 group-hover:text-epilist-green transition-colors duration-300">
                    {t(feature.titleKey as any)}
                  </h3>
                  <p className="text-gray-600 leading-relaxed">
                    {t(feature.descKey as any)}
                  </p>
                </div>

                {/* Hover Effect */}
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-epilist-green to-epilist-blue transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left"></div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="text-center mt-16">
          <div className="inline-flex items-center space-x-4 bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg">
            <div className="flex space-x-2">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="w-2 h-2 bg-epilist-green rounded-full animate-pulse-gentle" style={{ animationDelay: `${i * 0.2}s` }}></div>
              ))}
            </div>
            <span className="text-gray-700 font-medium">{t('moreToDiscover')}</span>
          </div>
        </div>
      </div>
    </section>
  );
}