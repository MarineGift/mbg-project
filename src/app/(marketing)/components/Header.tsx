'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';

export default function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollToSection = (sectionId: string) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setIsMenuOpen(false);
    }
  };

  return (
    <header className={`fixed w-full z-50 transition-all duration-300 ${isScrolled ? 'bg-white shadow-md' : 'bg-transparent'}`}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          {/* Logo */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center">
              <img
                src="https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/316a2b7fdbb9930ebedac283acd4ea0e.jpeg"
                alt="Marinebio Group Logo"
                className="h-12 w-auto object-contain"
              />
            </Link>
          </div>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-8">
            <button onClick={() => scrollToSection('technology')} className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Technology
            </button>
            <button onClick={() => scrollToSection('products')} className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Products
            </button>
            <Link href="/paper-filler" className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Paper Filler
            </Link>
            <button onClick={() => scrollToSection('research')} className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Research
            </button>
            <button onClick={() => scrollToSection('about')} className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              About
            </button>
            <button onClick={() => scrollToSection('contact')} className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Contact
            </button>
            <Link href="/urm/dashboard" className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              CRM
            </Link>
            <Link href="/videos" className={`font-medium transition-colors whitespace-nowrap cursor-pointer ${isScrolled ? 'text-gray-700 hover:text-blue-600' : 'text-white hover:text-blue-200'}`}>
              Videos
            </Link>
          </nav>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className={`md:hidden w-8 h-8 flex items-center justify-center cursor-pointer ${isScrolled ? 'text-gray-900' : 'text-white'}`}
          >
            <i className={`${isMenuOpen ? 'ri-close-line' : 'ri-menu-line'} text-2xl`}></i>
          </button>
        </div>

        {/* Mobile Menu */}
        {isMenuOpen && (
          <div className="md:hidden bg-white shadow-lg rounded-lg mt-2 py-4">
            <button onClick={() => scrollToSection('technology')} className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Technology
            </button>
            <button onClick={() => scrollToSection('products')} className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Products
            </button>
            <Link href="/paper-filler" className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Paper Filler
            </Link>
            <button onClick={() => scrollToSection('research')} className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Research
            </button>
            <button onClick={() => scrollToSection('about')} className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              About
            </button>
            <button onClick={() => scrollToSection('contact')} className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Contact
            </button>
            <Link href="/urm/dashboard" className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              CRM
            </Link>
            <Link href="/videos" className="block w-full text-left px-4 py-2 text-gray-700 hover:bg-blue-50 cursor-pointer">
              Videos
            </Link>
          </div>
        )}
      </div>
    </header>
  );
}
