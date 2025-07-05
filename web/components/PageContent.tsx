'use client';

import Header from '@/components/Header';
import HeroSection from '@/components/HeroSection';
import FeaturesSection from '@/components/FeaturesSection';
import BenefitsSection from '@/components/BenefitsSection';
import TestimonialsSection from '@/components/TestimonialsSection';
import NewBrunswickSection from '@/components/NewBrunswickSection';
import CTASection from '@/components/CTASection';
import Footer from '@/components/Footer';

export default function PageContent() {
  return (
    <main className="min-h-screen">
      <Header />
      <HeroSection />
      <FeaturesSection />
      <BenefitsSection />
      <TestimonialsSection />
      <NewBrunswickSection />
      <CTASection />
      <Footer />
    </main>
  );
}