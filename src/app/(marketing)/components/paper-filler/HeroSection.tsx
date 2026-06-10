'use client';

export default function HeroSection() {
  const handleInquiry = () => {
    const contactSection = document.getElementById('contact');
    if (contactSection) {
      contactSection.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800">
      {/* Background Image with Overlay */}
      <div className="absolute inset-0">
        <img 
          src="https://readdy.ai/api/search-image?query=Modern%20industrial%20paper%20manufacturing%20facility%20with%20advanced%20machinery%20and%20high-tech%20equipment%2C%20sophisticated%20production%20line%20with%20large%20paper%20rolls%2C%20professional%20industrial%20photography%2C%20deep%20navy%20blue%20and%20gold%20lighting%2C%20premium%20corporate%20atmosphere%2C%20clean%20organized%20factory%20floor&width=1920&height=1080&seq=fcc-hero-bg&orientation=landscape"
          alt="Paper Manufacturing"
          className="w-full h-full object-cover object-center"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-slate-900/85 via-blue-900/80 to-slate-900/90"></div>
      </div>

      {/* Decorative Elements */}
      <div className="absolute top-20 right-20 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl"></div>
      <div className="absolute bottom-20 left-20 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl"></div>

      {/* Content */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center py-32">
        <div className="mb-8">
          <span className="inline-block px-6 py-2 bg-amber-500/20 border border-amber-500/30 rounded-full text-amber-400 font-semibold text-sm tracking-wider whitespace-nowrap">
            FCC TECHNOLOGY LICENSING
          </span>
        </div>

        <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 leading-tight">
          The New Standard for
          <span className="block mt-2 bg-gradient-to-r from-amber-400 to-amber-200 bg-clip-text text-transparent">
            Paper Fillers
          </span>
        </h1>

        <p className="text-xl md:text-2xl text-blue-100 mb-12 max-w-4xl mx-auto leading-relaxed">
          Revolutionizing Copy, Thermal, and Label Papers with 1:40 CNF Synthesis Technology
        </p>

        <button 
          onClick={handleInquiry}
          className="group relative inline-flex items-center px-10 py-5 bg-gradient-to-r from-amber-500 to-amber-600 text-slate-900 font-bold text-lg rounded-lg overflow-hidden transition-all duration-300 hover:shadow-2xl hover:shadow-amber-500/50 hover:scale-105 whitespace-nowrap cursor-pointer"
        >
          <span className="relative z-10 flex items-center">
            Inquire for Licensing
            <i className="ri-arrow-right-line ml-3 text-xl group-hover:translate-x-2 transition-transform"></i>
          </span>
          <div className="absolute inset-0 bg-gradient-to-r from-amber-400 to-amber-500 opacity-0 group-hover:opacity-100 transition-opacity"></div>
        </button>

        {/* Stats Bar */}
        <div className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
            <div className="text-4xl font-bold text-amber-400 mb-2">1:40</div>
            <div className="text-blue-100 font-medium">CNF Synthesis Ratio</div>
          </div>
          <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
            <div className="text-4xl font-bold text-amber-400 mb-2">3X</div>
            <div className="text-blue-100 font-medium">Cost Reduction</div>
          </div>
          <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl p-6">
            <div className="text-4xl font-bold text-amber-400 mb-2">Global</div>
            <div className="text-blue-100 font-medium">Market Ready</div>
          </div>
        </div>
      </div>

      {/* Scroll Indicator */}
      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
        <i className="ri-arrow-down-line text-3xl text-white/60"></i>
      </div>
    </section>
  );
}

