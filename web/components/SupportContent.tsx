'use client';

import { useLanguage } from '@/hooks/useLanguage';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ArrowLeft, HelpCircle, Mail, Phone, MessageCircle, Book, Bug, Lightbulb, Clock, MapPin, Users, Star, Zap, Shield, CheckCircle, ArrowRight } from 'lucide-react';
import Link from 'next/link';

export default function SupportContent() {
  const { t } = useLanguage();

  const supportChannels = [
    {
      icon: Mail,
      titleKey: 'emailSupportTitle',
      descKey: 'emailSupportDesc',
      actionKey: 'sendEmail',
      color: 'from-blue-500 to-blue-600',
      bgColor: 'bg-blue-50',
      contact: 'support@epilist.ca',
      responseTime: '< 24h'
    },
    {
      icon: Phone,
      titleKey: 'phoneSupportTitle',
      descKey: 'phoneSupportDesc',
      actionKey: 'callUs',
      color: 'from-green-500 to-green-600',
      bgColor: 'bg-green-50',
      contact: '+1 (506) 123-4567',
      responseTime: t('immediate')
    },
    {
      icon: MessageCircle,
      titleKey: 'liveChatTitle',
      descKey: 'liveChatDesc',
      actionKey: 'startChat',
      color: 'from-purple-500 to-purple-600',
      bgColor: 'bg-purple-50',
      contact: t('availableNow'),
      responseTime: '< 5min'
    }
  ];

  const helpCategories = [
    {
      icon: Book,
      titleKey: 'gettingStartedTitle',
      descKey: 'gettingStartedDesc',
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      articles: '12'
    },
    {
      icon: Users,
      titleKey: 'familySharingTitle',
      descKey: 'familySharingDesc',
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      articles: '8'
    },
    {
      icon: Shield,
      titleKey: 'securityPrivacyTitle',
      descKey: 'securityPrivacyDesc',
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
      articles: '6'
    },
    {
      icon: Zap,
      titleKey: 'troubleshootingTitle',
      descKey: 'troubleshootingDesc',
      color: 'text-red-600',
      bgColor: 'bg-red-50',
      articles: '15'
    },
    {
      icon: Bug,
      titleKey: 'reportBugTitle',
      descKey: 'reportBugDesc',
      color: 'text-orange-600',
      bgColor: 'bg-orange-50',
      articles: '3'
    },
    {
      icon: Lightbulb,
      titleKey: 'featureRequestTitle',
      descKey: 'featureRequestDesc',
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-50',
      articles: '5'
    }
  ];

  const faqs = [
    {
      questionKey: 'faq1Question',
      answerKey: 'faq1Answer',
      category: 'getting-started'
    },
    {
      questionKey: 'faq2Question',
      answerKey: 'faq2Answer',
      category: 'family-sharing'
    },
    {
      questionKey: 'faq3Question',
      answerKey: 'faq3Answer',
      category: 'sync'
    },
    {
      questionKey: 'faq4Question',
      answerKey: 'faq4Answer',
      category: 'offline'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-purple-50">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-purple-600 via-blue-600 to-purple-800 text-white overflow-hidden">
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
              <HelpCircle className="h-10 w-10" />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white to-purple-100 bg-clip-text text-transparent">
              {t('supportTitle')}
            </h1>
            <p className="text-xl md:text-2xl text-purple-100 max-w-3xl mx-auto leading-relaxed">
              {t('supportSubtitle')}
            </p>
            
            {/* Quick Stats */}
            <div className="mt-12 grid grid-cols-3 gap-8 max-w-2xl mx-auto">
              <div className="text-center">
                <div className="text-3xl font-bold text-white mb-2">98%</div>
                <div className="text-purple-200 text-sm">{t('satisfactionRate')}</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-white mb-2">< 2h</div>
                <div className="text-purple-200 text-sm">{t('averageResponseTime')}</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-white mb-2">24/7</div>
                <div className="text-purple-200 text-sm">{t('availability')}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Support Channels */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-6">{t('howCanWeHelp')}</h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              {t('chooseYourPreferredWay')}
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 mb-20">
            {supportChannels.map((channel, index) => (
              <Card key={index} className="shadow-xl border-0 hover:shadow-2xl transition-all duration-300 group overflow-hidden">
                <CardContent className="p-0">
                  <div className={`${channel.bgColor} p-8 h-full`}>
                    <div className="text-center">
                      <div className={`w-20 h-20 bg-gradient-to-r ${channel.color} rounded-full flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300 shadow-lg`}>
                        <channel.icon className="h-10 w-10 text-white" />
                      </div>
                      
                      <h3 className="text-2xl font-bold text-gray-900 mb-4">
                        {t(channel.titleKey as any)}
                      </h3>
                      <p className="text-gray-600 mb-6 leading-relaxed">
                        {t(channel.descKey as any)}
                      </p>
                      
                      <div className="space-y-4 mb-8">
                        <div className="flex items-center justify-center space-x-2 text-sm text-gray-500">
                          <Clock className="h-4 w-4" />
                          <span>{t('responseTime')}: {channel.responseTime}</span>
                        </div>
                        <div className="text-sm font-medium text-gray-700">
                          {channel.contact}
                        </div>
                      </div>
                      
                      <Button className={`bg-gradient-to-r ${channel.color} text-white hover:shadow-lg transition-all duration-300 group-hover:scale-105`}>
                        {t(channel.actionKey as any)}
                        <ArrowRight className="ml-2 h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Help Categories */}
          <div className="mb-20">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-gray-900 mb-6">{t('browseHelpTopics')}</h2>
              <p className="text-xl text-gray-600">
                {t('findAnswersInOurKnowledgeBase')}
              </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {helpCategories.map((category, index) => (
                <Card key={index} className="shadow-lg border-0 hover:shadow-xl transition-all duration-300 group cursor-pointer">
                  <CardContent className="p-6">
                    <div className={`${category.bgColor} rounded-2xl p-4 mb-4 inline-block`}>
                      <category.icon className={`h-8 w-8 ${category.color}`} />
                    </div>
                    <h3 className="text-xl font-bold text-gray-900 mb-3 group-hover:text-purple-600 transition-colors">
                      {t(category.titleKey as any)}
                    </h3>
                    <p className="text-gray-600 mb-4 leading-relaxed">
                      {t(category.descKey as any)}
                    </p>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-500">
                        {category.articles} {t('articles')}
                      </span>
                      <ArrowRight className="h-4 w-4 text-gray-400 group-hover:text-purple-600 group-hover:translate-x-1 transition-all" />
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* FAQ Section */}
          <div className="mb-20">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-gray-900 mb-6">{t('frequentlyAskedQuestions')}</h2>
              <p className="text-xl text-gray-600">
                {t('quickAnswersToCommonQuestions')}
              </p>
            </div>

            <div className="space-y-6 max-w-4xl mx-auto">
              {faqs.map((faq, index) => (
                <Card key={index} className="shadow-lg border-0 hover:shadow-xl transition-all duration-300">
                  <CardContent className="p-8">
                    <div className="flex items-start space-x-4">
                      <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center flex-shrink-0 mt-1">
                        <span className="text-white font-bold text-sm">Q</span>
                      </div>
                      <div className="flex-1">
                        <h3 className="text-xl font-bold text-gray-900 mb-4">
                          {t(faq.questionKey as any)}
                        </h3>
                        <p className="text-gray-600 leading-relaxed">
                          {t(faq.answerKey as any)}
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>

          {/* Support Hours & Location */}
          <div className="grid md:grid-cols-2 gap-8 mb-16">
            <Card className="shadow-xl border-0">
              <CardContent className="p-8 bg-gradient-to-br from-blue-50 to-indigo-50">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center">
                    <Clock className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">{t('supportHoursTitle')}</h3>
                </div>
                <div className="space-y-4">
                  <div className="flex justify-between items-center p-4 bg-white rounded-xl">
                    <span className="font-semibold text-gray-900">{t('mondayFriday')}</span>
                    <span className="text-gray-600">8h00 - 20h00 (AST)</span>
                  </div>
                  <div className="flex justify-between items-center p-4 bg-white rounded-xl">
                    <span className="font-semibold text-gray-900">{t('weekend')}</span>
                    <span className="text-gray-600">10h00 - 18h00 (AST)</span>
                  </div>
                  <div className="flex justify-between items-center p-4 bg-white rounded-xl">
                    <span className="font-semibold text-gray-900">{t('holidays')}</span>
                    <span className="text-gray-600">{t('limitedSupport')}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="shadow-xl border-0">
              <CardContent className="p-8 bg-gradient-to-br from-green-50 to-emerald-50">
                <div className="flex items-center space-x-4 mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl flex items-center justify-center">
                    <MapPin className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900">{t('ourLocationTitle')}</h3>
                </div>
                <div className="space-y-4">
                  <div className="p-4 bg-white rounded-xl">
                    <div className="font-semibold text-gray-900 mb-2">EpiList Support Center</div>
                    <div className="text-gray-600 space-y-1">
                      <p>123 Innovation Avenue</p>
                      <p>Fredericton, NB E3B 1A1</p>
                      <p>{t('canada')}</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2 text-sm text-gray-500">
                    <CheckCircle className="h-4 w-4 text-green-500" />
                    <span>{t('localTeamAvailable')}</span>
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