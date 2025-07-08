"use client";

import { useState } from "react";
import { useLanguage } from "@/hooks/useLanguage";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  ArrowLeft,
  Mail,
  Send,
  MapPin,
  Phone,
  Clock,
  CheckCircle,
  User,
  MessageSquare,
  FileText,
} from "lucide-react";
import Link from "next/link";

export default function ContactContent() {
  const { t } = useLanguage();
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    subject: "",
    message: "",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleInputChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    // Simulate form submission
    await new Promise((resolve) => setTimeout(resolve, 2000));

    setIsSubmitting(false);
    setIsSubmitted(true);

    // Reset form after 3 seconds
    setTimeout(() => {
      setIsSubmitted(false);
      setFormData({ name: "", email: "", subject: "", message: "" });
    }, 3000);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-epilist-gray-50">
      {/* Hero Section */}
      <div className="relative bg-gradient-epilist text-white overflow-hidden">
        <div className="absolute inset-0 bg-black/20"></div>
        <div className="absolute inset-0">
          <div className="absolute top-20 left-20 w-64 h-64 bg-white/10 rounded-full blur-3xl animate-float"></div>
          <div className="absolute bottom-20 right-20 w-80 h-80 bg-white/10 rounded-full blur-3xl animate-float-reverse"></div>
        </div>

        <div className="container mx-auto px-4 py-20 relative z-10">
          <Link href="/">
            <Button
              variant="ghost"
              className="text-white hover:bg-white/20 mb-8 group"
            >
              <ArrowLeft className="mr-2 h-4 w-4 group-hover:scale-110 transition-transform" />
              {t("backToHome")}
            </Button>
          </Link>

          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-8">
              <Mail className="h-10 w-10" />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-white to-epilist-green-light bg-clip-text text-transparent">
              {t("contactTitle")}
            </h1>
            <p className="text-xl md:text-2xl text-epilist-green-light max-w-3xl mx-auto leading-relaxed">
              {t("contactSubtitle")}
            </p>
          </div>
        </div>
      </div>

      {/* Contact Form & Info */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-6xl mx-auto">
          <div className="grid lg:grid-cols-3 gap-12">
            {/* Contact Form */}
            <div className="lg:col-span-2">
              <Card className="shadow-2xl border-0 overflow-hidden">
                <CardContent className="p-0">
                  {isSubmitted ? (
                    <div className="p-12 text-center bg-gradient-to-br from-green-50 to-epilist-green/10">
                      <div className="w-20 h-20 bg-gradient-to-r from-epilist-green to-epilist-green-light rounded-full flex items-center justify-center mx-auto mb-6">
                        <CheckCircle className="h-10 w-10 text-white" />
                      </div>
                      <h3 className="text-3xl font-bold text-gray-900 mb-4">
                        {t("messageSent")}
                      </h3>
                      <p className="text-gray-600 text-lg">
                        {t("messageConfirmation")}
                      </p>
                    </div>
                  ) : (
                    <div className="p-8 md:p-12">
                      <div className="mb-8">
                        <h2 className="text-3xl font-bold text-gray-900 mb-4">
                          {t("getInTouch")}
                        </h2>
                        <p className="text-gray-600 text-lg">
                          {t("contactFormDescription")}
                        </p>
                      </div>

                      <form onSubmit={handleSubmit} className="space-y-6">
                        {/* Name Field */}
                        <div>
                          <label
                            htmlFor="name"
                            className="block text-sm font-semibold text-gray-700 mb-3"
                          >
                            {t("yourName")}
                          </label>
                          <div className="relative">
                            <User className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                            <input
                              type="text"
                              id="name"
                              name="name"
                              value={formData.name}
                              onChange={handleInputChange}
                              placeholder={t("namePlaceholder")}
                              required
                              className="w-full pl-12 pr-4 py-4 border border-gray-200 rounded-xl focus:ring-2 focus:ring-epilist-green focus:border-transparent transition-all duration-300 text-gray-900 placeholder-gray-500"
                            />
                          </div>
                        </div>

                        {/* Email Field */}
                        <div>
                          <label
                            htmlFor="email"
                            className="block text-sm font-semibold text-gray-700 mb-3"
                          >
                            {t("yourEmail")}
                          </label>
                          <div className="relative">
                            <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                            <input
                              type="email"
                              id="email"
                              name="email"
                              value={formData.email}
                              onChange={handleInputChange}
                              placeholder={t("emailPlaceholder")}
                              required
                              className="w-full pl-12 pr-4 py-4 border border-gray-200 rounded-xl focus:ring-2 focus:ring-epilist-green focus:border-transparent transition-all duration-300 text-gray-900 placeholder-gray-500"
                            />
                          </div>
                        </div>

                        {/* Subject Field */}
                        <div>
                          <label
                            htmlFor="subject"
                            className="block text-sm font-semibold text-gray-700 mb-3"
                          >
                            {t("subject")}
                          </label>
                          <div className="relative">
                            <FileText className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                            <select
                              id="subject"
                              name="subject"
                              value={formData.subject}
                              onChange={handleInputChange}
                              required
                              className="w-full pl-12 pr-4 py-4 border border-gray-200 rounded-xl focus:ring-2 focus:ring-epilist-green focus:border-transparent transition-all duration-300 text-gray-900 appearance-none bg-white"
                            >
                              <option value="">{t("selectSubject")}</option>
                              <option value="support">
                                {t("technicalSupport")}
                              </option>
                              <option value="feature">
                                {t("featureRequest")}
                              </option>
                              <option value="bug">{t("bugReport")}</option>
                              <option value="partnership">
                                {t("partnership")}
                              </option>
                              <option value="other">{t("other")}</option>
                            </select>
                          </div>
                        </div>

                        {/* Message Field */}
                        <div>
                          <label
                            htmlFor="message"
                            className="block text-sm font-semibold text-gray-700 mb-3"
                          >
                            {t("message")}
                          </label>
                          <div className="relative">
                            <MessageSquare className="absolute left-4 top-4 h-5 w-5 text-gray-400" />
                            <textarea
                              id="message"
                              name="message"
                              value={formData.message}
                              onChange={handleInputChange}
                              placeholder={t("messagePlaceholder")}
                              required
                              rows={6}
                              className="w-full pl-12 pr-4 py-4 border border-gray-200 rounded-xl focus:ring-2 focus:ring-epilist-green focus:border-transparent transition-all duration-300 text-gray-900 placeholder-gray-500 resize-none"
                            />
                          </div>
                        </div>

                        {/* Submit Button */}
                        <Button
                          type="submit"
                          disabled={isSubmitting}
                          className="w-full bg-gradient-epilist hover:shadow-glow-green text-white py-4 text-lg font-semibold transition-all duration-300 group"
                        >
                          {isSubmitting ? (
                            <div className="flex items-center justify-center">
                              <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-3"></div>
                              {t("sending")}
                            </div>
                          ) : (
                            <div className="flex items-center justify-center">
                              <Send className="mr-3 h-5 w-5 group-hover:translate-x-1 transition-transform" />
                              {t("sendMessage")}
                            </div>
                          )}
                        </Button>
                      </form>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>

            {/* Contact Information */}
            <div className="space-y-8">
              {/* Business Hours */}
              <Card className="shadow-xl border-0">
                <CardContent className="p-8">
                  <div className="flex items-center space-x-3 mb-6">
                    <Clock className="h-6 w-6 text-epilist-blue" />
                    <h3 className="text-2xl font-bold text-gray-900">
                      {t("businessHours")}
                    </h3>
                  </div>

                  <div className="space-y-4">
                    <div className="flex justify-between items-center p-4 bg-gray-50 rounded-xl">
                      <span className="font-semibold text-gray-900">
                        {t("mondayFriday")}
                      </span>
                      <span className="text-gray-600">9h00 - 17h00</span>
                    </div>
                    <div className="flex justify-between items-center p-4 bg-gray-50 rounded-xl">
                      <span className="font-semibold text-gray-900">
                        {t("weekend")}
                      </span>
                      <span className="text-gray-600">{t("closed")}</span>
                    </div>
                    <div className="flex justify-between items-center p-4 bg-gray-50 rounded-xl">
                      <span className="font-semibold text-gray-900">
                        {t("holidays")}
                      </span>
                      <span className="text-gray-600">{t("closed")}</span>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Quick Links */}
              <Card className="shadow-xl border-0">
                <CardContent className="p-8 bg-gradient-to-br from-epilist-blue/5 to-epilist-green/5">
                  <h3 className="text-2xl font-bold text-gray-900 mb-6">
                    {t("quickLinks")}
                  </h3>

                  <div className="space-y-3">
                    <Link
                      href="/support"
                      className="flex items-center space-x-3 p-3 rounded-xl hover:bg-white transition-colors group"
                    >
                      <div className="w-8 h-8 bg-epilist-green/20 rounded-lg flex items-center justify-center group-hover:bg-epilist-green group-hover:text-white transition-colors">
                        <Mail className="h-4 w-4" />
                      </div>
                      <span className="text-gray-700 group-hover:text-epilist-green transition-colors">
                        {t("helpCenter")}
                      </span>
                    </Link>

                    <Link
                      href="/privacy"
                      className="flex items-center space-x-3 p-3 rounded-xl hover:bg-white transition-colors group"
                    >
                      <div className="w-8 h-8 bg-epilist-blue/20 rounded-lg flex items-center justify-center group-hover:bg-epilist-blue group-hover:text-white transition-colors">
                        <FileText className="h-4 w-4" />
                      </div>
                      <span className="text-gray-700 group-hover:text-epilist-blue transition-colors">
                        {t("privacyPolicy")}
                      </span>
                    </Link>

                    <Link
                      href="/terms"
                      className="flex items-center space-x-3 p-3 rounded-xl hover:bg-white transition-colors group"
                    >
                      <div className="w-8 h-8 bg-epilist-green/20 rounded-lg flex items-center justify-center group-hover:bg-epilist-green group-hover:text-white transition-colors">
                        <FileText className="h-4 w-4" />
                      </div>
                      <span className="text-gray-700 group-hover:text-epilist-green transition-colors">
                        {t("termsOfService")}
                      </span>
                    </Link>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
