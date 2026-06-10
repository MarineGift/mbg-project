'use client';


import { useState, useEffect } from 'react';

export default function HeroSection() {
  const [currentSlide, setCurrentSlide] = useState(0);
  
  const videos = [
    {
      id: "4Xf3McA6dVU",
      title: "Marine Nanofiber Innovation",
      description: "Discover our breakthrough marine biotechnology"
    },
    {
      id: "3HqpDmSSc-c", 
      title: "Advanced Research Technology",
      description: "Cutting-edge laboratory research and development"
    },
    {
      id: "Nu0bOMa0Uwk",
      title: "Sustainable Solutions",
      description: "Eco-friendly marine biomass applications"
    },
    {
      id: "EWrK9sXcfW4",
      title: "Product Manufacturing",
      description: "High-quality production processes"
    },
    {
      id: "aEUPjkScyvQ",
      title: "Future of Marine Technology",
      description: "Leading the next generation of innovation"
    }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % videos.length);
    }, 8000);
    return () => clearInterval(timer);
  }, []);

  const nextSlide = () => {
    setCurrentSlide((prev) => (prev + 1) % videos.length);
  };

  const prevSlide = () => {
    setCurrentSlide((prev) => (prev - 1 + videos.length) % videos.length);
  };

  const goToSlide = (index: number) => {
    setCurrentSlide(index);
  };

  return (
    <section id="home" className="relative h-screen bg-black overflow-hidden">
      {/* Video Carousel */}
      <div className="absolute inset-0 w-full h-full">
        {videos.map((video, index) => (
          <div
            key={index}
            className={`absolute inset-0 w-full h-full transition-opacity duration-1000 ${
              index === currentSlide ? 'opacity-100' : 'opacity-0'
            }`}
          >
            <iframe
              src={`https://www.youtube.com/embed/${video.id}?autoplay=1&mute=1&loop=1&playlist=${video.id}&controls=0&showinfo=0&rel=0&modestbranding=1`}
              className="absolute top-1/2 left-1/2 w-full h-full transform -translate-x-1/2 -translate-y-1/2"
              style={{ 
                minWidth: '100vw', 
                minHeight: '100vh',
                width: '177.77vh',
                height: '56.25vw'
              }}
              allow="autoplay; encrypted-media"
              allowFullScreen
            />
            <div className="absolute inset-0 bg-black bg-opacity-40"></div>
          </div>
        ))}
        
        {/* Content Overlay */}
        <div className="absolute inset-0 flex items-center justify-center z-10">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full">
            <div className="text-center text-white">
              <h1 className="text-4xl md:text-6xl font-bold mb-6 leading-tight">
                {videos[currentSlide].title}
              </h1>
              <p className="text-xl md:text-2xl mb-8 text-blue-100 max-w-3xl mx-auto leading-relaxed">
                {videos[currentSlide].description}
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <button 
                  onClick={() => {
                    const technologySection = document.getElementById('technology');
                    if (technologySection) {
                      technologySection.scrollIntoView({ behavior: 'smooth' });
                    }
                  }}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-lg text-lg font-semibold transition-colors whitespace-nowrap cursor-pointer"
                >
                  Explore Technology
                </button>
                <button 
                  onClick={() => {
                    const productsSection = document.getElementById('products');
                    if (productsSection) {
                      productsSection.scrollIntoView({ behavior: 'smooth' });
                    }
                  }}
                  className="border-2 border-white text-white hover:bg-white hover:text-blue-600 px-8 py-4 rounded-lg text-lg font-semibold transition-colors whitespace-nowrap cursor-pointer"
                >
                  View Products
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Arrows */}
        <button
          onClick={prevSlide}
          className="absolute left-4 top-1/2 transform -translate-y-1/2 z-20 bg-black bg-opacity-50 hover:bg-opacity-70 text-white p-3 rounded-full transition-all cursor-pointer"
        >
          <i className="ri-arrow-left-line text-2xl"></i>
        </button>
        <button
          onClick={nextSlide}
          className="absolute right-4 top-1/2 transform -translate-y-1/2 z-20 bg-black bg-opacity-50 hover:bg-opacity-70 text-white p-3 rounded-full transition-all cursor-pointer"
        >
          <i className="ri-arrow-right-line text-2xl"></i>
        </button>

        {/* Dots Indicator */}
        <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-20 flex space-x-3">
          {videos.map((_, index) => (
            <button
              key={index}
              onClick={() => goToSlide(index)}
              className={`w-3 h-3 rounded-full transition-all cursor-pointer ${
                index === currentSlide ? 'bg-white' : 'bg-white bg-opacity-50'
              }`}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

