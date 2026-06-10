'use client';

import Header from '../components/Header';
import Footer from '../components/Footer';
import HeroSection from '../components/home/HeroSection';
import TechnologySection from '../components/home/TechnologySection';
import ProductsSection from '../components/home/ProductsSection';
import ResearchSection from '../components/home/ResearchSection';
import AboutSection from '../components/home/AboutSection';
import ContactSection from '../components/home/ContactSection';

export default function Home() {
  return (
    <div className="min-h-screen bg-white" style={{ fontFamily: '"Noto Sans KR", sans-serif' }}>
      <Header />
      <main>
        <HeroSection />
        <TechnologySection />
        <ProductsSection />
        <ResearchSection />
        <AboutSection />
        <ContactSection />
      </main>
      <Footer />
    </div>
  );
}
