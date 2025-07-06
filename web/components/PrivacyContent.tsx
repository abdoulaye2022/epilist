'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, Shield, Eye, Lock, Database, Users, Mail, Phone, MapPin, CheckCircle, AlertCircle } from 'lucide-react';
import Link from 'next/link';

export default function PrivacyContent() {
  const { t } = useLanguage();

  const privacySections = [
    {
      icon: Eye,
      titleKey: 'privacyIntroTitle',
      contentKey: 'privacyIntroText1',
      color: 'from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50'
    },
    {
      icon: Database,
      titleKey: 'dataCollectionTitle',
      contentKey: 'dataCollectionText',
      color: 'from-green-500 to-green-600',
      bgColor: 'bg-green-50'
    },
    {
      icon: Users,
      titleKey: 'dataUsageTitle',
      contentKey: 'dataUsageText',
      color: 'from-purple-500 to-purple-600',
      bgColor: 'bg-purple-50'
    },
    {
      icon: Lock,
      titleKey: 'dataSecurityTitle',
      contentKey: 'dataSecurityText',
      color: 'from-red-500 to-red-600',
      bgColor: 'bg-red-50'
    },
    {
      icon: Shield,
      titleKey: 'userRightsTitle',
      contentKey: 'userRightsText',
      color: 'from-indigo-500 to-indigo-600',
      bgColor: 'bg-indigo-50'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-blue-50">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-blue-600 via-purple-600 to-blue-800 text-white overflow-hidden">
        <div className="absolute inset-0 bg-black/20"></div>
        <div className="absolute inset-0">
          <div className="absolute top-20 left-20 w-64 h-64 bg-white/10 rounded-full blur-3xl animate-float"></div>
          <div className="absolute bottom-20 right-20 w-80 h-80 bg-white/10 rounded-full blur-3xl animate-float-reverse"></div>
        </div>
        
        <div className="container mx-auto px-4 py-20 relative z-10">
          <Link href="/">
            <Button variant="ghost" className="text-white hover:bg-white/20 mb-8 group">
              <ArrowLeft className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
              {t('backToHome')}
            </Button>
          </Link>
          
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-8">
              <Shield className="h-10 w-10" />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white to-blue-100 bg-clip-text text-transparent">
              {t('privacyPolicyTitle')}
            </h1>
            <p className="text-xl md:text-2xl text-blue-100 max-w-3xl mx-auto leading-relaxed">
              {t('privacyPolicySubtitle')}
            </p>
            <div className="mt-8 inline-flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-full px-6 py-3">
              <CheckCircle className="h-5 w-5 text-green-300" />
              <span className="text-white/90">
                {t('lastUpdated')}: {t('language') === 'fr' ? '15 décembre 2024' : 'December 15, 2024'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Content Sections */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          
          {/* Trust Indicators */}
          <div className="grid md:grid-cols-3 gap-6 mb-16">
            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-green-100">
              <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Lock className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">{t('bankLevelSecurity')}</h3>
              <p className="text-gray-600 text-sm">{t('aes256Encryption')}</p>
            </div>
            
            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-blue-100">
              <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <MapPin className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">{t('canadianServers')}</h3>
              <p className="text-gray-600 text-sm">{t('dataStaysInCanada')}</p>
            </div>
            
            <div className="text-center p-6 bg-white rounded-2xl shadow-lg border border-purple-100">
              <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="h-8 w-8 text-white" />
              </div>
              <h3 className="font-bold text-gray-900 mb-2">{t('gdprCompliant')}</h3>
              <p className="text-gray-600 text-sm">{t('internationalStandards')}</p>
            </div>
          </div>

          {/* Privacy Sections */}
          <div className="space-y-8">
            {privacySections.map((section, index) => (
              <Card key={index} className="overflow-hidden shadow-xl border-0 hover:shadow-2xl transition-all duration-300">
                <CardContent className="p-0">
                  <div className={`${section.bgColor} p-8 border-l-4 border-l-current`}>
                    <div className="flex items-start space-x-6">
                      <div className={`w-16 h-16 bg-gradient-to-r ${section.color} rounded-2xl flex items-center justify-center flex-shrink-0 shadow-lg`}>
                        <section.icon className="h-8 w-8 text-white" />
                      </div>
                      <div className="flex-1">
                        <h2 className="text-3xl font-bold text-gray-900 mb-4">
                          {t(section.titleKey as any)}
                        </h2>
                        <div className="prose prose-lg max-w-none text-gray-700">
                          <p className="leading-relaxed">
                            {t(section.contentKey as any)}
                          </p>
                          
                          {/* Detailed content based on section */}
                          {section.titleKey === 'dataCollectionTitle' && (
                            <div className="mt-6 grid md:grid-cols-2 gap-6">
                              <div>
                                <h4 className="font-semibold text-gray-900 mb-3 flex items-center">
                                  <Users className="h-5 w-5 mr-2 text-green-600" />
                                  {t('personalDataTitle')}
                                </h4>
                                <ul className="space-y-2">
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-green-500" />
                                    {t('personalData1')}
                                  </li>
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-green-500" />
                                    {t('personalData2')}
                                  </li>
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-green-500" />
                                    {t('personalData3')}
                                  </li>
                                </ul>
                              </div>
                              <div>
                                <h4 className="font-semibold text-gray-900 mb-3 flex items-center">
                                  <Database className="h-5 w-5 mr-2 text-blue-600" />
                                  {t('usageDataTitle')}
                                </h4>
                                <ul className="space-y-2">
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-blue-500" />
                                    {t('usageData1')}
                                  </li>
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-blue-500" />
                                    {t('usageData2')}
                                  </li>
                                  <li className="flex items-center text-gray-600">
                                    <CheckCircle className="h-4 w-4 mr-2 text-blue-500" />
                                    {t('usageData3')}
                                  </li>
                                </ul>
                              </div>
                            </div>
                          )}

                          {section.titleKey === 'dataSecurityTitle' && (
                            <div className="mt-6 grid md:grid-cols-2 gap-4">
                              {[
                                { icon: Lock, text: t('dataSecurity1') },
                                { icon: Shield, text: t('dataSecurity2') },
                                { icon: MapPin, text: t('dataSecurity3') },
                                { icon: CheckCircle, text: t('dataSecurity4') }
                              ].map((item, idx) => (
                                <div key={idx} className="flex items-center space-x-3 p-4 bg-white/50 rounded-xl">
                                  <item.icon className="h-5 w-5 text-red-600" />
                                  <span className="text-gray-700">{item.text}</span>
                                </div>
                              ))}
                            </div>
                          )}

                          {section.titleKey === 'userRightsTitle' && (
                            <div className="mt-6 space-y-3">
                              {[
                                t('userRight1'),
                                t('userRight2'),
                                t('userRight3'),
                                t('userRight4'),
                                t('userRight5')
                              ].map((right, idx) => (
                                <div key={idx} className="flex items-center space-x-3 p-3 bg-white/50 rounded-lg">
                                  <CheckCircle className="h-5 w-5 text-indigo-600" />
                                  <span className="text-gray-700">{right}</span>
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

        </div>
      </div>
    </div>
  );
}