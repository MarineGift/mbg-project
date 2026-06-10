'use client';

import { useState } from 'react';

export default function ContactSection() {
  const [formData, setFormData] = useState({
    company: '',
    name: '',
    email: '',
    phone: '',
    country: '',
    message: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (formData.message.length > 500) return;

    setIsSubmitting(true);
    setSubmitStatus('idle');

    try {
      const params = new URLSearchParams();
      params.append('company', formData.company);
      params.append('name', formData.name);
      params.append('email', formData.email);
      params.append('phone', formData.phone);
      params.append('country', formData.country);
      params.append('message', formData.message);
      params.append('recipient_emails', 'yunyoung.heo@marinebiogroup.com,marinegift4u@gmail.com');

      const response = await fetch('https://readdy.ai/api/form/d6h8qh35skvpgoe5sotg', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString()
      });

      if (response.ok) {
        setSubmitStatus('success');
        setFormData({ company: '', name: '', email: '', phone: '', country: '', message: '' });
      } else {
        setSubmitStatus('error');
      }
    } catch {
      setSubmitStatus('error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  return (
    <section id="contact" className="py-24 bg-gradient-to-b from-white to-slate-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16">
          {/* Left Column - Info */}
          <div>
            <span className="inline-block px-6 py-2 bg-amber-500/10 border border-amber-500/30 rounded-full text-amber-700 font-semibold text-sm tracking-wider mb-6 whitespace-nowrap">
              GET IN TOUCH
            </span>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-6">
              Ready to License FCC Technology?
            </h2>
            <p className="text-xl text-slate-600 mb-8 leading-relaxed">
              Join leading paper manufacturers worldwide who have transformed their production with our innovative filler technology.
            </p>

            <div className="space-y-6 mb-12">
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 flex items-center justify-center bg-amber-100 rounded-lg flex-shrink-0">
                  <i className="ri-mail-line text-xl text-amber-700"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-slate-900 mb-1">Email</h4>
                  <p className="text-slate-600">yunyoung.heo@marinebiogroup.com</p>
                  <p className="text-slate-600">marinegift4u@gmail.com</p>
                </div>
              </div>
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 flex items-center justify-center bg-amber-100 rounded-lg flex-shrink-0">
                  <i className="ri-phone-line text-xl text-amber-700"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-slate-900 mb-1">Phone</h4>
                  <p className="text-slate-600">(512) 996-7083</p>
                </div>
              </div>
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 flex items-center justify-center bg-amber-100 rounded-lg flex-shrink-0">
                  <i className="ri-map-pin-line text-xl text-amber-700"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-slate-900 mb-1">Location</h4>
                  <p className="text-slate-600">1108 Nueces St, Austin, TX 78701, USA</p>
                </div>
              </div>
            </div>

            <div className="rounded-2xl overflow-hidden shadow-xl h-80 w-full">
              <img
                src="https://readdy.ai/api/search-image?query=Modern%20high-tech%20laboratory%20with%20advanced%20paper%20testing%20equipment%20and%20microscopes%2C%20professional%20scientists%20analyzing%20nanofiber%20samples%2C%20sophisticated%20industrial%20research%20facility%2C%20navy%20blue%20and%20gold%20lighting%2C%20premium%20corporate%20environment&width=800&height=600&seq=lab-facility&orientation=landscape"
                alt="Research Facility"
                className="w-full h-full object-cover object-top"
              />
            </div>
          </div>

          {/* Right Column - Form */}
          <div className="bg-white rounded-2xl shadow-xl p-10 border border-slate-200">
            <h3 className="text-2xl font-bold text-slate-900 mb-6">
              Request Licensing Information
            </h3>

            <form
              onSubmit={handleSubmit}
              data-readdy-form
              className="space-y-6"
            >
              <div>
                <label htmlFor="company" className="block text-sm font-semibold text-slate-700 mb-2">
                  Company Name *
                </label>
                <input
                  type="text"
                  id="company"
                  name="company"
                  required
                  value={formData.company}
                  onChange={handleChange}
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                  placeholder="Your company name"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-semibold text-slate-700 mb-2">
                    Full Name *
                  </label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    required
                    value={formData.name}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                    placeholder="John Smith"
                  />
                </div>
                <div>
                  <label htmlFor="email" className="block text-sm font-semibold text-slate-700 mb-2">
                    Email *
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    required
                    value={formData.email}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                    placeholder="john@company.com"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="phone" className="block text-sm font-semibold text-slate-700 mb-2">
                    Phone Number
                  </label>
                  <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                    placeholder="+1 (555) 000-0000"
                  />
                </div>
                <div>
                  <label htmlFor="country" className="block text-sm font-semibold text-slate-700 mb-2">
                    Country *
                  </label>
                  <input
                    type="text"
                    id="country"
                    name="country"
                    required
                    value={formData.country}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                    placeholder="United States"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="message" className="block text-sm font-semibold text-slate-700 mb-2">
                  Message *
                </label>
                <textarea
                  id="message"
                  name="message"
                  required
                  value={formData.message}
                  onChange={handleChange}
                  rows={5}
                  maxLength={500}
                  className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-transparent resize-none text-sm"
                  placeholder="Tell us about your paper manufacturing needs and licensing interests..."
                />
                <div className="text-right text-xs text-slate-500 mt-1">
                  {formData.message.length}/500 characters
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full py-4 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 disabled:opacity-60 text-white font-bold rounded-lg transition-all duration-300 hover:shadow-lg whitespace-nowrap cursor-pointer"
              >
                {isSubmitting ? 'Submitting...' : 'Submit Inquiry'}
              </button>

              {submitStatus === 'success' && (
                <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-start space-x-3">
                  <div className="w-5 h-5 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <i className="ri-check-circle-line text-green-500 text-lg"></i>
                  </div>
                  <p className="text-green-700 font-medium text-sm">
                    Thank you for your inquiry! Our licensing team will contact you within 24 hours.
                  </p>
                </div>
              )}

              {submitStatus === 'error' && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start space-x-3">
                  <div className="w-5 h-5 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <i className="ri-error-warning-line text-red-500 text-lg"></i>
                  </div>
                  <p className="text-red-700 font-medium text-sm">
                    Something went wrong. Please try again or contact us directly at yunyoung.heo@marinebiogroup.com
                  </p>
                </div>
              )}

              <p className="text-xs text-slate-500 text-center">
                By submitting this form, you agree to our privacy policy and terms of service.
              </p>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
}

