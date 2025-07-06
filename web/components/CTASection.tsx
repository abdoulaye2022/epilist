'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Download, ArrowRight, Users, Shield, Zap, Star, CheckCircle } from 'lucide-react';
import { useLanguage } from '@/hooks/useLanguage';

export default function CTASection() {
  const [isVisible, setIsVisible] = useState(false);
  const { t } = useLanguage();

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsVisible(true);
          }
        });
      },
      { threshold: 0.1 }
    );

    const element = document.getElementById('cta-section');
    if (element) observer.observe(element);

    return () => observer.disconnect();
  }, []);

  return (
    <section id="cta-section" className="py-24 bg-gradient-to-br from-epilist-green via-epilist-blue to-epilist-green relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-white/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-white/10 rounded-full blur-3xl animate-float-reverse"></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        <div className={`text-center text-white ${isVisible ? 'animate-fade-in' : 'opacity-0'}`}>
          
          {/* Main CTA */}
          <div className="max-w-4xl mx-auto mb-16">
            <h2 className="text-4xl md:text-6xl font-bold mb-6">
              {t('ctaTitle')}
            </h2>
            <p className="text-xl md:text-2xl text-white/90 mb-12 leading-relaxed">
              {t('ctaSubtitle')}
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-6 justify-center mb-12">
              <Button
                size="lg"
                className="bg-white text-epilist-green hover:bg-white/90 hover:shadow-2xl transition-all duration-300 transform hover:scale-105 group"
              >
                <Download className="mr-3 h-6 w-6 group-hover:animate-bounce-gentle" />
                {t('downloadNow')}
                <ArrowRight className="ml-3 h-6 w-6 group-hover:translate-x-1 transition-transform" />
              </Button>
              <Button
                size="lg"
                variant="outline"
                className="border-2 border-white text-white hover:bg-white hover:text-epilist-green transition-all duration-300 group"
              >
                {t('watchDemo')}
                <ArrowRight className="ml-3 h-6 w-6 group-hover:translate-x-1 transition-transform" />
              </Button>
            </div>

            {/* Trust Indicators */}
            <div className="flex flex-wrap justify-center items-center gap-8 text-white/80">
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5" />
                <span>{t('free')}</span>
              </div>
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5" />
                <span>{t('adFree')}</span>
              </div>
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5" />
                <span>{t('quickInstall')}</span>
              </div>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto mb-16">
            <Card className="bg-white/10 backdrop-blur-sm border-white/20 hover:bg-white/20 transition-all duration-300">
              <CardContent className="p-8 text-center">
                <Users className="h-12 w-12 text-white mx-auto mb-4" />
                <div className="text-3xl font-bold text-white mb-2">50k+</div>
                <div className="text-white/80">{t('activeUsers')}</div>
              </CardContent>
            </Card>

            <Card className="bg-white/10 backdrop-blur-sm border-white/20 hover:bg-white/20 transition-all duration-300">
              <CardContent className="p-8 text-center">
                <Star className="h-12 w-12 text-white mx-auto mb-4" />
                <div className="text-3xl font-bold text-white mb-2">4.9/5</div>
                <div className="text-white/80">{t('averageRating')}</div>
              </CardContent>
            </Card>

            <Card className="bg-white/10 backdrop-blur-sm border-white/20 hover:bg-white/20 transition-all duration-300">
              <CardContent className="p-8 text-center">
                <Shield className="h-12 w-12 text-white mx-auto mb-4" />
                <div className="text-3xl font-bold text-white mb-2">100%</div>
                <div className="text-white/80">{t('secureData')}</div>
              </CardContent>
            </Card>
          </div>

          {/* Bottom Text */}
          <div className="max-w-3xl mx-auto">
            <p className="text-lg text-white/90 leading-relaxed">
              {t('ctaBottomText')}
            </p>
          </div>

        </div>
      </div>
    </section>
  );
}