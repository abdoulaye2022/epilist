'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, FileText, Users, AlertTriangle, Scale, Smartphone, Mail, Phone, MapPin } from 'lucide-react';
import Link from 'next/link';

export default function TermsContent() {
  const { t } = useLanguage();

  return (
    <div className="min-h-screen bg-gradient-to-br from-epilist-gray-50 via-white to-epilist-gray-50">
      {/* Header */}
      <div className="bg-gradient-epilist text-white py-16">
        <div className="container mx-auto px-4">
          <Link href="/">
            <Button variant="ghost" className="text-white hover:bg-white/20 mb-8">
              <ArrowLeft className="mr-2 h-4 w-4" />
              {t('backToHome')}
            </Button>
          </Link>
          <div className="max-w-4xl mx-auto text-center">
            <FileText className="h-16 w-16 mx-auto mb-6" />
            <h1 className="text-4xl md:text-6xl font-bold mb-6">
              {t('termsOfServiceTitle')}
            </h1>
            <p className="text-xl text-white/90">
              {t('termsOfServiceSubtitle')}
            </p>
            <div className="mt-6 text-white/80">
              {t('lastUpdated')}: {t('language') === 'fr' ? '15 décembre 2024' : 'December 15, 2024'}
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto space-y-8">
          
          {/* Acceptance */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Scale className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('acceptanceTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('acceptanceText1')}
              </p>
              <p className="text-gray-600 leading-relaxed">
                {t('acceptanceText2')}
              </p>
            </CardContent>
          </Card>

          {/* Service Description */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Smartphone className="h-6 w-6 text-epilist-blue" />
                <h2 className="text-2xl font-bold text-gray-900">{t('serviceDescriptionTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('serviceDescriptionText')}
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('serviceFeature1')}</li>
                <li>{t('serviceFeature2')}</li>
                <li>{t('serviceFeature3')}</li>
                <li>{t('serviceFeature4')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* User Responsibilities */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Users className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('userResponsibilitiesTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('userResponsibilitiesText')}
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('userResponsibility1')}</li>
                <li>{t('userResponsibility2')}</li>
                <li>{t('userResponsibility3')}</li>
                <li>{t('userResponsibility4')}</li>
                <li>{t('userResponsibility5')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* Prohibited Uses */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <AlertTriangle className="h-6 w-6 text-red-500" />
                <h2 className="text-2xl font-bold text-gray-900">{t('prohibitedUsesTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('prohibitedUsesText')}
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('prohibitedUse1')}</li>
                <li>{t('prohibitedUse2')}</li>
                <li>{t('prohibitedUse3')}</li>
                <li>{t('prohibitedUse4')}</li>
                <li>{t('prohibitedUse5')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* Intellectual Property */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <FileText className="h-6 w-6 text-epilist-blue" />
                <h2 className="text-2xl font-bold text-gray-900">{t('intellectualPropertyTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('intellectualPropertyText1')}
              </p>
              <p className="text-gray-600 leading-relaxed">
                {t('intellectualPropertyText2')}
              </p>
            </CardContent>
          </Card>

          {/* Limitation of Liability */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Scale className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('limitationLiabilityTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('limitationLiabilityText1')}
              </p>
              <p className="text-gray-600 leading-relaxed">
                {t('limitationLiabilityText2')}
              </p>
            </CardContent>
          </Card>

          {/* Modifications */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <AlertTriangle className="h-6 w-6 text-epilist-blue" />
                <h2 className="text-2xl font-bold text-gray-900">{t('modificationsTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed">
                {t('modificationsText')}
              </p>
            </CardContent>
          </Card>

          {/* Contact */}
          <Card className="shadow-lg border-0 bg-gradient-to-r from-epilist-green/5 to-epilist-blue/5">
            <CardContent className="p-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">{t('contactUsTitle')}</h2>
              <p className="text-gray-600 leading-relaxed mb-6">
                {t('termsContactText')}
              </p>
              <div className="grid md:grid-cols-3 gap-4">
                <div className="flex items-center space-x-3">
                  <Mail className="h-5 w-5 text-epilist-green" />
                  <span className="text-gray-700">legal@epilist.ca</span>
                </div>
                <div className="flex items-center space-x-3">
                  <Phone className="h-5 w-5 text-epilist-blue" />
                  <span className="text-gray-700">+1 (506) 123-4567</span>
                </div>
                <div className="flex items-center space-x-3">
                  <MapPin className="h-5 w-5 text-epilist-green" />
                  <span className="text-gray-700">Fredericton, NB</span>
                </div>
              </div>
            </CardContent>
          </Card>

        </div>
      </div>
    </div>
  );
}