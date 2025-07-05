'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, Shield, Eye, Lock, Database, Users, Mail, Phone, MapPin } from 'lucide-react';
import Link from 'next/link';

export default function PrivacyContent() {
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
            <Shield className="h-16 w-16 mx-auto mb-6" />
            <h1 className="text-4xl md:text-6xl font-bold mb-6">
              {t('privacyPolicyTitle')}
            </h1>
            <p className="text-xl text-white/90">
              {t('privacyPolicySubtitle')}
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
          
          {/* Introduction */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Eye className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('privacyIntroTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('privacyIntroText1')}
              </p>
              <p className="text-gray-600 leading-relaxed">
                {t('privacyIntroText2')}
              </p>
            </CardContent>
          </Card>

          {/* Data Collection */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Database className="h-6 w-6 text-epilist-blue" />
                <h2 className="text-2xl font-bold text-gray-900">{t('dataCollectionTitle')}</h2>
              </div>
              <div className="space-y-4">
                <div>
                  <h3 className="text-lg font-semibold text-gray-800 mb-2">{t('personalDataTitle')}</h3>
                  <ul className="list-disc list-inside text-gray-600 space-y-1">
                    <li>{t('personalData1')}</li>
                    <li>{t('personalData2')}</li>
                    <li>{t('personalData3')}</li>
                  </ul>
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-800 mb-2">{t('usageDataTitle')}</h3>
                  <ul className="list-disc list-inside text-gray-600 space-y-1">
                    <li>{t('usageData1')}</li>
                    <li>{t('usageData2')}</li>
                    <li>{t('usageData3')}</li>
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Data Usage */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Users className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('dataUsageTitle')}</h2>
              </div>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('dataUsage1')}</li>
                <li>{t('dataUsage2')}</li>
                <li>{t('dataUsage3')}</li>
                <li>{t('dataUsage4')}</li>
                <li>{t('dataUsage5')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* Data Security */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Lock className="h-6 w-6 text-epilist-blue" />
                <h2 className="text-2xl font-bold text-gray-900">{t('dataSecurityTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('dataSecurityText1')}
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('dataSecurity1')}</li>
                <li>{t('dataSecurity2')}</li>
                <li>{t('dataSecurity3')}</li>
                <li>{t('dataSecurity4')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* User Rights */}
          <Card className="shadow-lg border-0">
            <CardContent className="p-8">
              <div className="flex items-center space-x-3 mb-6">
                <Shield className="h-6 w-6 text-epilist-green" />
                <h2 className="text-2xl font-bold text-gray-900">{t('userRightsTitle')}</h2>
              </div>
              <p className="text-gray-600 leading-relaxed mb-4">
                {t('userRightsText')}
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-2">
                <li>{t('userRight1')}</li>
                <li>{t('userRight2')}</li>
                <li>{t('userRight3')}</li>
                <li>{t('userRight4')}</li>
                <li>{t('userRight5')}</li>
              </ul>
            </CardContent>
          </Card>

          {/* Contact */}
          <Card className="shadow-lg border-0 bg-gradient-to-r from-epilist-green/5 to-epilist-blue/5">
            <CardContent className="p-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">{t('contactUsTitle')}</h2>
              <p className="text-gray-600 leading-relaxed mb-6">
                {t('contactUsText')}
              </p>
              <div className="grid md:grid-cols-3 gap-4">
                <div className="flex items-center space-x-3">
                  <Mail className="h-5 w-5 text-epilist-green" />
                  <span className="text-gray-700">privacy@epilist.ca</span>
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