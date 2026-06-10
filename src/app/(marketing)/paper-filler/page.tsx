'use client';

import Header from '../components/Header';
import Footer from '../components/Footer';
import HeroSection from '../components/paper-filler/HeroSection';
import ApplicationSection from '../components/paper-filler/ApplicationSection';
import ValuePropositionSection from '../components/paper-filler/ValuePropositionSection';
import ContactSection from '../components/paper-filler/ContactSection';

export default function PaperFiller() {
  return (
    <div className="min-h-screen bg-white" style={{ fontFamily: '"Inter", "Roboto", sans-serif' }}>
      <Header />
      <main>
        <HeroSection />
        <ApplicationSection />
        <ValuePropositionSection />
        <ContactSection />
      </main>
      <Footer />
    </div>
  );
}
