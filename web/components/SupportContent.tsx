'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, HelpCircle, Mail, Phone, MessageCircle, Book, Bug, Lightbulb, Clock, MapPin, Users, Star } from 'lucide-react';
import Link from 'next/link';

export default function SupportContent() {
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
            <HelpCircle className="h-16 w-16 mx-auto mb-6" />
            <h1 className="text-4xl md:text-6xl font-bold mb-6">
              {t('supportTitle')}
            </h1>
            <p className="text-xl text-white/90">
              {t('supportSubtitle')}
            </p>
          </div>
        </div>
      </div>

      {/* Quick Help */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          
          {/* Contact Options */}
          <div className="grid md:grid-cols-3 gap-8 mb-16">
            <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group">
              <CardContent className="p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-br from-epilist-green to-epilist-green-light rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Mail className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-4">{t('emailSupportTitle')}</h3>
                <p className="text-gray-600 mb-6">{t('emailSupportDesc')}</p>
                <Button className="bg-gradient-epilist text-white">
                  {t('sendEmail')}
                </Button>
                <div className="mt-4 text-sm text-gray-500">
                  support@epilist.ca
                </div>
              </CardContent>
            </Card>

            <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group">
              <CardContent className="p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-br from-epilist-blue to-epilist-blue-light rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <Phone className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-4">{t('phoneSupportTitle')}</h3>
                <p className="text-gray-600 mb-6">{t('phoneSupportDesc')}</p>
                <Button variant="outline" className="border-epilist-blue text-epilist-blue hover:bg-epilist-blue hover:text-white">
                  {t('callUs')}
                </Button>
                <div className="mt-4 text-sm text-gray-500">
                  +1 (506) 123-4567
                </div>
              </CardContent>
            </Card>

            <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group">
              <CardContent className="p-8 text-center">
                <div className="w-16 h-16 bg-gradient-to-br from-epilist-green to-epilist-green-light rounded-2xl flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                  <MessageCircle className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-4">{t('liveChatTitle')}</h3>
                <p className="text-gray-600 mb-6">{t('liveChatDesc')}</p>
                <Button className="bg-gradient-epilist text-white">
                  {t('startChat')}
                </Button>
                <div className="mt-4 text-sm text-gray-500">
                  {t('availableNow')}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Support Categories */}
          <div className="mb-16">
            <h2 className="text-3xl font-bold text-gray-900 text-center mb-12">{t('supportCategoriesTitle')}</h2>
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              
              <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group cursor-pointer">
                <CardContent className="p-6 text-center">
                  <Book className="h-12 w-12 text-epilist-green mx-auto mb-4 group-hover:scale-110 transition-transform duration-300" />
                  <h3 className="font-bold text-gray-900 mb-2">{t('gettingStartedTitle')}</h3>
                  <p className="text-sm text-gray-600">{t('gettingStartedDesc')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group cursor-pointer">
                <CardContent className="p-6 text-center">
                  <Users className="h-12 w-12 text-epilist-blue mx-auto mb-4 group-hover:scale-110 transition-transform duration-300" />
                  <h3 className="font-bold text-gray-900 mb-2">{t('familySharingTitle')}</h3>
                  <p className="text-sm text-gray-600">{t('familySharingDesc')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group cursor-pointer">
                <CardContent className="p-6 text-center">
                  <Bug className="h-12 w-12 text-red-500 mx-auto mb-4 group-hover:scale-110 transition-transform duration-300" />
                  <h3 className="font-bold text-gray-900 mb-2">{t('reportBugTitle')}</h3>
                  <p className="text-sm text-gray-600">{t('reportBugDesc')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group cursor-pointer">
                <CardContent className="p-6 text-center">
                  <Lightbulb className="h-12 w-12 text-yellow-500 mx-auto mb-4 group-hover:scale-110 transition-transform duration-300" />
                  <h3 className="font-bold text-gray-900 mb-2">{t('featureRequestTitle')}</h3>
                  <p className="text-sm text-gray-600">{t('featureRequestDesc')}</p>
                </CardContent>
              </Card>

            </div>
          </div>

          {/* FAQ Section */}
          <div className="mb-16">
            <h2 className="text-3xl font-bold text-gray-900 text-center mb-12">{t('faqTitle')}</h2>
            <div className="space-y-6">
              
              <Card className="shadow-lg border-0">
                <CardContent className="p-6">
                  <h3 className="text-lg font-bold text-gray-900 mb-3">{t('faq1Question')}</h3>
                  <p className="text-gray-600">{t('faq1Answer')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0">
                <CardContent className="p-6">
                  <h3 className="text-lg font-bold text-gray-900 mb-3">{t('faq2Question')}</h3>
                  <p className="text-gray-600">{t('faq2Answer')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0">
                <CardContent className="p-6">
                  <h3 className="text-lg font-bold text-gray-900 mb-3">{t('faq3Question')}</h3>
                  <p className="text-gray-600">{t('faq3Answer')}</p>
                </CardContent>
              </Card>

              <Card className="shadow-lg border-0">
                <CardContent className="p-6">
                  <h3 className="text-lg font-bold text-gray-900 mb-3">{t('faq4Question')}</h3>
                  <p className="text-gray-600">{t('faq4Answer')}</p>
                </CardContent>
              </Card>

            </div>
          </div>

          {/* Support Hours */}
          <Card className="shadow-lg border-0 bg-gradient-to-r from-epilist-green/5 to-epilist-blue/5">
            <CardContent className="p-8">
              <div className="grid md:grid-cols-2 gap-8 items-center">
                <div>
                  <div className="flex items-center space-x-3 mb-4">
                    <Clock className="h-6 w-6 text-epilist-green" />
                    <h3 className="text-2xl font-bold text-gray-900">{t('supportHoursTitle')}</h3>
                  </div>
                  <div className="space-y-2 text-gray-600">
                    <p><strong>{t('mondayFriday')}:</strong> 8h00 - 20h00 (AST)</p>
                    <p><strong>{t('weekend')}:</strong> 10h00 - 18h00 (AST)</p>
                    <p><strong>{t('holidays')}:</strong> {t('limitedSupport')}</p>
                  </div>
                </div>
                <div>
                  <div className="flex items-center space-x-3 mb-4">
                    <MapPin className="h-6 w-6 text-epilist-blue" />
                    <h3 className="text-2xl font-bold text-gray-900">{t('ourLocationTitle')}</h3>
                  </div>
                  <div className="text-gray-600">
                    <p>EpiList Support Center</p>
                    <p>123 Innovation Avenue</p>
                    <p>Fredericton, NB E3B 1A1</p>
                    <p>{t('canada')}</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Satisfaction */}
          <div className="mt-16 text-center">
            <Card className="shadow-lg border-0 bg-white/80 backdrop-blur-sm">
              <CardContent className="p-8">
                <Star className="h-12 w-12 text-epilist-green mx-auto mb-4" />
                <h3 className="text-2xl font-bold text-gray-900 mb-4">{t('satisfactionTitle')}</h3>
                <p className="text-gray-600 mb-6">{t('satisfactionText')}</p>
                <div className="flex justify-center items-center space-x-8">
                  <div className="text-center">
                    <div className="text-3xl font-bold text-epilist-green">98%</div>
                    <div className="text-sm text-gray-500">{t('satisfactionRate')}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-epilist-blue">&lt; 2h</div>
                    <div className="text-sm text-gray-500">{t('averageResponseTime')}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-3xl font-bold text-epilist-green">24/7</div>
                    <div className="text-sm text-gray-500">{t('availability')}</div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

        </div>
      </div>
    </div>
  );
}