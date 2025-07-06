'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, FileText, Users, AlertTriangle, Scale, Smartphone, Mail, Phone, MapPin, CheckCircle, XCircle, Info } from 'lucide-react';
import Link from 'next/link';

export default function TermsContent() {
  const { t } = useLanguage();

  const termsSections = [
    {
      icon: Scale,
      titleKey: 'acceptanceTitle',
      contentKey: 'acceptanceText1',
      color: 'from-green-500 to-green-600',
      bgColor: 'bg-green-50',
      type: 'acceptance'
    },
    {
      icon: Smartphone,
      titleKey: 'serviceDescriptionTitle',
      contentKey: 'serviceDescriptionText',
      color: 'from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50',
      type: 'service'
    },
    {
      icon: Users,
      titleKey: 'userResponsibilitiesTitle',
      contentKey: 'userResponsibilitiesText',
      color: 'from-purple-500 to-purple-600',
      bgColor: 'bg-purple-50',
      type: 'responsibilities'
    },
    {
      icon: AlertTriangle,
      titleKey: 'prohibitedUsesTitle',
      contentKey: 'prohibitedUsesText',
      color: 'from-red-500 to-red-600',
      bgColor: 'bg-red-50',
      type: 'prohibited'
    },
    {
      icon: FileText,
      titleKey: 'intellectualPropertyTitle',
      contentKey: 'intellectualPropertyText1',
      color: 'from-indigo-500 to-indigo-600',
      bgColor: 'bg-indigo-50',
      type: 'intellectual'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-green-50">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-green-600 via-blue-600 to-green-800 text-white overflow-hidden">
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
              <FileText className="h-10 w-10" />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white to-green-100 bg-clip-text text-transparent">
              {t('termsOfServiceTitle')}
            </h1>
            <p className="text-xl md:text-2xl text-green-100 max-w-3xl mx-auto leading-relaxed">
              {t('termsOfServiceSubtitle')}
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

      {/* Quick Summary */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          
          <div className="bg-gradient-to-r from-green-50 to-blue-50 rounded-3xl p-8 mb-16 border border-green-100">
            <div className="text-center mb-8">
              <Info className="h-12 w-12 text-green-600 mx-auto mb-4" />
              <h2 className="text-3xl font-bold text-gray-900 mb-4">{t('quickSummary')}</h2>
              <p className="text-gray-600 text-lg">{t('quickSummaryDesc')}</p>
            </div>
            
            <div className="grid md:grid-cols-3 gap-6">
              <div className="text-center p-6 bg-white rounded-2xl shadow-lg">
                <CheckCircle className="h-8 w-8 text-green-600 mx-auto mb-4" />
                <h3 className="font-bold text-gray-900 mb-2">{t('freeToUse')}</h3>
                <p className="text-gray-600 text-sm">{t('freeToUseDesc')}</p>
              </div>
              
              <div className="text-center p-6 bg-white rounded-2xl shadow-lg">
                <Users className="h-8 w-8 text-blue-600 mx-auto mb-4" />
                <h3 className="font-bold text-gray-900 mb-2">{t('respectfulUse')}</h3>
                <p className="text-gray-600 text-sm">{t('respectfulUseDesc')}</p>
              </div>
              
              <div className="text-center p-6 bg-white rounded-2xl shadow-lg">
                <Scale className="h-8 w-8 text-purple-600 mx-auto mb-4" />
                <h3 className="font-bold text-gray-900 mb-2">{t('fairTerms')}</h3>
                <p className="text-gray-600 text-sm">{t('fairTermsDesc')}</p>
              </div>
            </div>
          </div>

          {/* Terms Sections */}
          <div className="space-y-8">
            {termsSections.map((section, index) => (
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
                          <p className="leading-relaxed mb-6">
                            {t(section.contentKey as any)}
                          </p>
                          
                          {/* Service Features */}
                          {section.type === 'service' && (
                            <div className="grid md:grid-cols-2 gap-4">
                              {[
                                { icon: CheckCircle, text: t('serviceFeature1'), color: 'text-green-600' },
                                { icon: CheckCircle, text: t('serviceFeature2'), color: 'text-blue-600' },
                                { icon: CheckCircle, text: t('serviceFeature3'), color: 'text-purple-600' },
                                { icon: CheckCircle, text: t('serviceFeature4'), color: 'text-indigo-600' }
                              ].map((item, idx) => (
                                <div key={idx} className="flex items-center space-x-3 p-4 bg-white/50 rounded-xl">
                                  <item.icon className={`h-5 w-5 ${item.color}`} />
                                  <span className="text-gray-700">{item.text}</span>
                                </div>
                              ))}
                            </div>
                          )}

                          {/* User Responsibilities */}
                          {section.type === 'responsibilities' && (
                            <div className="space-y-3">
                              {[
                                t('userResponsibility1'),
                                t('userResponsibility2'),
                                t('userResponsibility3'),
                                t('userResponsibility4'),
                                t('userResponsibility5')
                              ].map((responsibility, idx) => (
                                <div key={idx} className="flex items-center space-x-3 p-3 bg-white/50 rounded-lg">
                                  <CheckCircle className="h-5 w-5 text-purple-600" />
                                  <span className="text-gray-700">{responsibility}</span>
                                </div>
                              ))}
                            </div>
                          )}

                          {/* Prohibited Uses */}
                          {section.type === 'prohibited' && (
                            <div className="space-y-3">
                              {[
                                t('prohibitedUse1'),
                                t('prohibitedUse2'),
                                t('prohibitedUse3'),
                                t('prohibitedUse4'),
                                t('prohibitedUse5')
                              ].map((prohibition, idx) => (
                                <div key={idx} className="flex items-center space-x-3 p-3 bg-white/50 rounded-lg">
                                  <XCircle className="h-5 w-5 text-red-600" />
                                  <span className="text-gray-700">{prohibition}</span>
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

          {/* Additional Terms */}
          <div className="grid md:grid-cols-2 gap-8 mt-16">
            <Card className="shadow-xl border-0">
              <CardContent className="p-8 bg-gradient-to-br from-yellow-50 to-orange-50">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center">
                    <Scale className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">{t('limitationLiabilityTitle')}</h3>
                </div>
                <p className="text-gray-700 leading-relaxed mb-4">
                  {t('limitationLiabilityText1')}
                </p>
                <p className="text-gray-700 leading-relaxed">
                  {t('limitationLiabilityText2')}
                </p>
              </CardContent>
            </Card>

            <Card className="shadow-xl border-0">
              <CardContent className="p-8 bg-gradient-to-br from-blue-50 to-indigo-50">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center">
                    <AlertTriangle className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">{t('modificationsTitle')}</h3>
                </div>
                <p className="text-gray-700 leading-relaxed">
                  {t('modificationsText')}
                </p>
              </CardContent>
            </Card>
          </div>

        </div>
      </div>
    </div>
  );
}