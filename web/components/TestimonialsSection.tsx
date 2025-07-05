'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Star, ChevronLeft, ChevronRight, Quote } from 'lucide-react';
import { useLanguage } from '@/hooks/useLanguage';

export default function TestimonialsSection() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const [isAutoPlaying, setIsAutoPlaying] = useState(true);
  const { t } = useLanguage();

  const testimonials = [
    {
      name: t('testimonial1Name'),
      role: t('testimonial1Role'),
      content: t('testimonial1Content'),
      rating: 5,
      avatar: 'M.D',
      color: 'from-epilist-green to-epilist-green-light'
    },
    {
      name: t('testimonial2Name'),
      role: t('testimonial2Role'),
      content: t('testimonial2Content'),
      rating: 5,
      avatar: 'P.M',
      color: 'from-epilist-blue to-epilist-blue-light'
    },
    {
      name: t('testimonial3Name'),
      role: t('testimonial3Role'),
      content: t('testimonial3Content'),
      rating: 5,
      avatar: 'S.L',
      color: 'from-epilist-green to-epilist-green-light'
    },
    {
      name: t('testimonial4Name'),
      role: t('testimonial4Role'),
      content: t('testimonial4Content'),
      rating: 5,
      avatar: 'J.P',
      color: 'from-epilist-blue to-epilist-blue-light'
    },
    {
      name: t('testimonial5Name'),
      role: t('testimonial5Role'),
      content: t('testimonial5Content'),
      rating: 5,
      avatar: 'A.C',
      color: 'from-epilist-green to-epilist-green-light'
    }
  ];

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

    const element = document.getElementById('temoignages');
    if (element) observer.observe(element);

    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!isAutoPlaying) return;
    
    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % testimonials.length);
    }, 5000);

    return () => clearInterval(interval);
  }, [isAutoPlaying]);

  const nextTestimonial = () => {
    setIsAutoPlaying(false);
    setCurrentIndex((prev) => (prev + 1) % testimonials.length);
  };

  const prevTestimonial = () => {
    setIsAutoPlaying(false);
    setCurrentIndex((prev) => (prev - 1 + testimonials.length) % testimonials.length);
  };

  const goToTestimonial = (index: number) => {
    setIsAutoPlaying(false);
    setCurrentIndex(index);
  };

  return (
    <section id="temoignages" className="py-24 bg-gradient-to-br from-white via-epilist-gray-50 to-white relative overflow-hidden">
      {/* Background Elements */}
      <div className="absolute inset-0">
        <div className="absolute top-20 right-20 w-64 h-64 bg-epilist-green/10 rounded-full blur-3xl animate-float"></div>
        <div className="absolute bottom-20 left-20 w-80 h-80 bg-epilist-blue/10 rounded-full blur-3xl animate-float-reverse"></div>
      </div>

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <div className="text-center mb-20">
          <div className="inline-flex items-center space-x-2 bg-gradient-epilist text-white px-6 py-2 rounded-full text-sm font-medium mb-6">
            <Quote className="h-4 w-4" />
            <span>{t('clientTestimonials')}</span>
          </div>
          <h2 className="text-4xl md:text-6xl font-bold text-gray-900 mb-6">
            {t('testimonialsTitle')}{' '}
            <span className="bg-gradient-epilist bg-clip-text text-transparent">
              {t('testimonialsTitleHighlight')}
            </span>
          </h2>
          <p className="text-xl md:text-2xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
            {t('testimonialsSubtitle')}
          </p>
        </div>

        {/* Testimonials Carousel */}
        <div className="relative max-w-5xl mx-auto">
          <div className={`transition-all duration-500 ${isVisible ? 'animate-fade-in' : 'opacity-0'}`}>
            <Card className="shadow-2xl border-0 bg-white/80 backdrop-blur-sm overflow-hidden">
              <CardContent className="p-0">
                <div className="relative">
                  {/* Background Gradient */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${testimonials[currentIndex].color} opacity-5`}></div>
                  
                  <div className="relative p-8 md:p-12">
                    {/* Navigation */}
                    <div className="flex items-center justify-between mb-8">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={prevTestimonial}
                        className="hover:bg-epilist-green/10 hover:text-epilist-green transition-all duration-300 group"
                      >
                        <ChevronLeft className="h-5 w-5 group-hover:scale-110 transition-transform duration-300" />
                      </Button>
                      
                      {/* Dots Indicator */}
                      <div className="flex space-x-2">
                        {testimonials.map((_, index) => (
                          <button
                            key={index}
                            onClick={() => goToTestimonial(index)}
                            className={`w-3 h-3 rounded-full transition-all duration-300 ${
                              index === currentIndex 
                                ? 'bg-gradient-epilist scale-125' 
                                : 'bg-gray-300 hover:bg-gray-400'
                            }`}
                          />
                        ))}
                      </div>
                      
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={nextTestimonial}
                        className="hover:bg-epilist-green/10 hover:text-epilist-green transition-all duration-300 group"
                      >
                        <ChevronRight className="h-5 w-5 group-hover:scale-110 transition-transform duration-300" />
                      </Button>
                    </div>

                    {/* Testimonial Content */}
                    <div className="text-center">
                      {/* Stars */}
                      <div className="flex justify-center mb-6">
                        {[...Array(testimonials[currentIndex].rating)].map((_, i) => (
                          <Star 
                            key={i} 
                            className="h-6 w-6 fill-epilist-green text-epilist-green animate-pulse-gentle" 
                            style={{ animationDelay: `${i * 0.1}s` }}
                          />
                        ))}
                      </div>

                      {/* Quote */}
                      <div className="relative mb-8">
                        <Quote className="absolute -top-4 -left-4 h-8 w-8 text-epilist-green/30" />
                        <blockquote className="text-xl md:text-2xl text-gray-800 font-medium leading-relaxed italic">
                          {testimonials[currentIndex].content}
                        </blockquote>
                        <Quote className="absolute -bottom-4 -right-4 h-8 w-8 text-epilist-green/30 rotate-180" />
                      </div>

                      {/* Author */}
                      <div className="flex items-center justify-center space-x-4">
                        <div className={`w-16 h-16 bg-gradient-to-br ${testimonials[currentIndex].color} rounded-full flex items-center justify-center text-white font-bold text-lg shadow-lg`}>
                          {testimonials[currentIndex].avatar}
                        </div>
                        <div className="text-left">
                          <div className="font-bold text-gray-900 text-lg">
                            {testimonials[currentIndex].name}
                          </div>
                          <div className="text-gray-500">
                            {testimonials[currentIndex].role}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Auto-play indicator */}
          <div className="flex items-center justify-center mt-6 space-x-2">
            <div className={`w-2 h-2 rounded-full ${isAutoPlaying ? 'bg-epilist-green animate-pulse-gentle' : 'bg-gray-300'}`}></div>
            <span className="text-sm text-gray-500">
              {isAutoPlaying ? t('autoPlay') : t('pause')}
            </span>
            <button
              onClick={() => setIsAutoPlaying(!isAutoPlaying)}
              className="text-sm text-epilist-green hover:text-epilist-blue transition-colors duration-300"
            >
              {isAutoPlaying ? t('pause') : t('resume')}
            </button>
          </div>
        </div>

        {/* Trust Indicators */}
        <div className="mt-16 text-center">
          <div className="inline-flex items-center space-x-8 bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg">
            <div className="flex items-center space-x-2">
              <div className="flex space-x-1">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="h-4 w-4 fill-epilist-green text-epilist-green" />
                ))}
              </div>
              <span className="font-bold text-gray-700">4.9/5</span>
            </div>
            <div className="w-px h-6 bg-gray-300"></div>
            <span className="text-gray-600 font-medium">{t('positiveReviews')}</span>
            <div className="w-px h-6 bg-gray-300"></div>
            <span className="text-gray-600 font-medium">{t('downloads')}</span>
          </div>
        </div>
      </div>
    </section>
  );
}