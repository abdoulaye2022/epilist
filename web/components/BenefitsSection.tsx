'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { 
  Clock, 
  Users, 
  TrendingUp, 
  Heart,
  Target,
  Zap,
  Shield,
  Smile
} from 'lucide-react';
import { useLanguage } from '@/hooks/useLanguage';

const benefits = [
  {
    icon: Clock,
    titleKey: 'benefit1Title',
    descKey: 'benefit1Desc',
    statKey: 'benefit1Stat',
    statLabelKey: 'benefit1StatLabel',
    color: 'from-epilist-green to-epilist-green-light',
    bgColor: 'bg-epilist-green/10'
  },
  {
    icon: Users,
    titleKey: 'benefit2Title',
    descKey: 'benefit2Desc',
    statKey: 'benefit2Stat',
    statLabelKey: 'benefit2StatLabel',
    color: 'from-epilist-blue to-epilist-blue-light',
    bgColor: 'bg-epilist-blue/10'
  },
  {
    icon: TrendingUp,
    titleKey: 'benefit3Title',
    descKey: 'benefit3Desc',
    statKey: 'benefit3Stat',
    statLabelKey: 'benefit3StatLabel',
    color: 'from-epilist-green to-epilist-green-light',
    bgColor: 'bg-epilist-green/10'
  },
  {
    icon: Heart,
    titleKey: 'benefit4Title',
    descKey: 'benefit4Desc',
    statKey: 'benefit4Stat',
    statLabelKey: 'benefit4StatLabel',
    color: 'from-epilist-blue to-epilist-blue-light',
    bgColor: 'bg-epilist-blue/10'
  },
  {
    icon: Target,
    titleKey: 'benefit5Title',
    descKey: 'benefit5Desc',
    statKey: 'benefit5Stat',
    statLabelKey: 'benefit5StatLabel',
    color: 'from-epilist-green to-epilist-green-light',
    bgColor: 'bg-epilist-green/10'
  },
  {
    icon: Zap,
    titleKey: 'benefit6Title',
    descKey: 'benefit6Desc',
    statKey: 'benefit6Stat',
    statLabelKey: 'benefit6StatLabel',
    color: 'from-epilist-blue to-epilist-blue-light',
    bgColor: 'bg-epilist-blue/10'
  }
];

export default function BenefitsSection() {
  const [visibleItems, setVisibleItems] = useState<number[]>([]);
  const { t } = useLanguage();

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = parseInt(entry.target.getAttribute('data-benefit-index') || '0');
            setTimeout(() => {
              setVisibleItems(prev => [...prev, index]);
            }, index * 150);
          }
        });
      },
      { threshold: 0.1 }
    );

    const elements = document.querySelectorAll('[data-benefit-index]');
    elements.forEach(el => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  return (
    <section id="avantages" className="py-24 bg-gradient-to-br from-epilist-gray-50 via-white to-epilist-gray-50 relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-r from-epilist-green/20 to-epilist-blue/20 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-gradient-to-r from-epilist-blue/20 to-epilist-green/20 rounded-full blur-3xl animate-float-reverse"></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <div className="text-center mb-20">
          <div className="inline-flex items-center space-x-2 bg-gradient-epilist text-white px-6 py-2 rounded-full text-sm font-medium mb-6">
            <Smile className="h-4 w-4" />
            <span>{t('concreteAdvantages')}</span>
          </div>
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            {t('benefitsTitle')}{' '}
            <span className="bg-gradient-epilist bg-clip-text text-transparent">
              {t('benefitsTitleHighlight')}
            </span>
          </h2>
          <p className="text-xl md:text-2xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
            {t('benefitsSubtitle')}
          </p>
        </div>

        {/* Benefits Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {benefits.map((benefit, index) => (
            <Card
              key={index}
              data-benefit-index={index}
              className={`group hover:shadow-card-hover transition-all duration-500 cursor-pointer border-0 shadow-lg bg-white/80 backdrop-blur-sm hover:bg-white ${
                visibleItems.includes(index) ? 'animate-scale-in' : 'opacity-0'
              }`}
            >
              <CardContent className="p-8 text-center relative overflow-hidden">
                {/* Background Pattern */}
                <div className={`absolute inset-0 ${benefit.bgColor} opacity-0 group-hover:opacity-100 transition-opacity duration-300`}></div>
                
                {/* Stats Circle */}
                <div className="relative mb-6">
                  <div className="relative w-24 h-24 mx-auto">
                    {/* Animated Ring */}
                    <div className={`absolute inset-0 bg-gradient-to-r ${benefit.color} rounded-full animate-pulse-gentle`}></div>
                    <div className="absolute inset-2 bg-white rounded-full flex flex-col items-center justify-center">
                      <div className={`text-2xl font-bold bg-gradient-to-r ${benefit.color} bg-clip-text text-transparent`}>
                        {t(benefit.statKey as any)}
                      </div>
                    </div>
                  </div>
                  <div className="text-sm text-gray-500 mt-2 font-medium">{t(benefit.statLabelKey as any)}</div>
                </div>

                {/* Icon */}
                <div className="relative mb-6">
                  <div className={`w-16 h-16 mx-auto bg-gradient-to-br ${benefit.color} rounded-2xl flex items-center justify-center group-hover:scale-110 group-hover:rotate-6 transition-all duration-300 shadow-lg`}>
                    <benefit.icon className="h-8 w-8 text-white" />
                  </div>
                  <div className={`absolute inset-0 w-16 h-16 mx-auto bg-gradient-to-br ${benefit.color} rounded-2xl blur-xl opacity-30 group-hover:opacity-50 transition-opacity duration-300`}></div>
                </div>

                {/* Content */}
                <div className="relative">
                  <h3 className="text-xl font-bold text-gray-900 mb-4 group-hover:text-epilist-green transition-colors duration-300">
                    {t(benefit.titleKey as any)}
                  </h3>
                  <p className="text-gray-600 leading-relaxed">
                    {t(benefit.descKey as any)}
                  </p>
                </div>

                {/* Hover Effect */}
                <div className={`absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r ${benefit.color} transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-center`}></div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Success Stories */}
        <div className="mt-20 text-center">
          <div className="bg-white/80 backdrop-blur-sm rounded-3xl p-8 shadow-xl max-w-4xl mx-auto">
            <div className="grid md:grid-cols-4 gap-8">
              {[
                { number: '200+', labelKey: 'activeUsers' },
                { number: '4.9/5', labelKey: 'averageRating' },
                { number: '450+', labelKey: 'listsCreated' },
                { number: '98%', labelKey: 'satisfaction' }
              ].map((stat, index) => (
                <div key={index} className="text-center">
                  <div className="text-3xl font-bold bg-gradient-epilist bg-clip-text text-transparent mb-2">
                    {stat.number}
                  </div>
                  <div className="text-gray-600 font-medium">{t(stat.labelKey as any)}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}