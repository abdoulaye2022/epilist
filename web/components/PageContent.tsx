"use client";

import DownloadAnalytics from "@/components/DownloadAnalytics";

import Header from "@/components/Header";
import HeroSection from "@/components/HeroSection";
import FeaturesSection from "@/components/FeaturesSection";
import BenefitsSection from "@/components/BenefitsSection";
import TestimonialsSection from "@/components/TestimonialsSection";
import NewBrunswickSection from "@/components/NewBrunswickSection";
import CTASection from "@/components/CTASection";
import Footer from "@/components/Footer";
import AdvancedTracking from "./AdvancedTracking";

export default function PageContent() {
  return (
    <main className="min-h-screen">
      <DownloadAnalytics />
      <AdvancedTracking />
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
