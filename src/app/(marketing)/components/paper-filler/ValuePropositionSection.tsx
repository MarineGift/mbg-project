export default function ValuePropositionSection() {
  return (
    <section className="py-24 bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800 relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-0 w-full h-full" style={{
          backgroundImage: 'radial-gradient(circle at 2px 2px, white 1px, transparent 0)',
          backgroundSize: '40px 40px'
        }}></div>
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <span className="inline-block px-6 py-2 bg-amber-500/20 border border-amber-500/30 rounded-full text-amber-400 font-semibold text-sm tracking-wider mb-6 whitespace-nowrap">
            COMPETITIVE ADVANTAGE
          </span>
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Why License FCC Technology?
          </h2>
          <p className="text-xl text-blue-100 max-w-3xl mx-auto">
            Gain a decisive edge in the global paper manufacturing market
          </p>
        </div>

        {/* Value Props Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
          {/* Cost Leadership */}
          <div className="group relative bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-10 hover:bg-white/10 transition-all duration-300">
            <div className="flex items-start space-x-6">
              <div className="flex-shrink-0">
                <div className="w-20 h-20 bg-gradient-to-br from-amber-500 to-amber-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                  <i className="ri-money-dollar-circle-line text-3xl text-white"></i>
                </div>
              </div>
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white mb-4">Cost Leadership</h3>
                <p className="text-blue-100 text-lg leading-relaxed mb-6">
                  Replace expensive pulp with stable mineral fillers to secure profit margins and maintain competitive pricing in global markets.
                </p>
                <ul className="space-y-3">
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Up to 40% reduction in raw material costs</span>
                  </li>
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Stable pricing independent of pulp market volatility</span>
                  </li>
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Enhanced profit margins across all product lines</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Scientific Validation */}
          <div className="group relative bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-10 hover:bg-white/10 transition-all duration-300">
            <div className="flex items-start space-x-6">
              <div className="flex-shrink-0">
                <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform">
                  <i className="ri-flask-line text-3xl text-white"></i>
                </div>
              </div>
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white mb-4">Scientific Validation</h3>
                <p className="text-blue-100 text-lg leading-relaxed mb-6">
                  Proven technology backed by peer-reviewed research and validated by industry leaders worldwide.
                </p>
                <ul className="space-y-3">
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Published in ACS Sustainable Chemistry & Engineering (2020)</span>
                  </li>
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Validated by leading paper manufacturers</span>
                  </li>
                  <li className="flex items-center text-blue-100">
                    <i className="ri-check-line text-amber-400 text-xl mr-3"></i>
                    <span>Continuous R&D support and innovation</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Research Publication Highlight */}
        <div className="bg-gradient-to-r from-amber-500/20 to-blue-500/20 backdrop-blur-sm border border-amber-500/30 rounded-2xl p-10">
          <div className="flex flex-col lg:flex-row items-center justify-between space-y-6 lg:space-y-0 lg:space-x-8">
            <div className="flex items-center space-x-6">
              <div className="w-24 h-24 bg-white rounded-xl flex items-center justify-center shadow-lg flex-shrink-0">
                <img 
                  src="https://readdy.ai/api/search-image?query=ACS%20American%20Chemical%20Society%20journal%20logo%20and%20publication%20cover%2C%20scientific%20research%20journal%2C%20professional%20academic%20publication%20design%2C%20navy%20blue%20and%20gold%20color%20scheme%2C%20prestigious%20chemistry%20journal&width=200&height=200&seq=acs-journal&orientation=squarish"
                  alt="ACS Publication"
                  className="w-20 h-20 object-contain"
                />
              </div>
              <div>
                <h4 className="text-2xl font-bold text-white mb-2">
                  Peer-Reviewed Research
                </h4>
                <p className="text-blue-100 text-lg">
                  ACS Sustainable Chemistry & Engineering, 2020
                </p>
                <p className="text-blue-200 text-sm mt-2">
                  "Cellulose Nanofiber-Based Functional Composite Filler for Paper Manufacturing"
                </p>
              </div>
            </div>
            <a 
              href="#contact"
              className="flex-shrink-0 inline-flex items-center px-8 py-4 bg-white text-slate-900 font-semibold rounded-lg hover:bg-amber-50 transition-colors whitespace-nowrap cursor-pointer"
            >
              Access Research Data
              <i className="ri-external-link-line ml-3 text-xl"></i>
            </a>
          </div>
        </div>

        {/* Additional Benefits */}
        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="w-16 h-16 bg-amber-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <i className="ri-global-line text-3xl text-amber-400"></i>
            </div>
            <h4 className="text-xl font-bold text-white mb-2">Global Support</h4>
            <p className="text-blue-100">
              Comprehensive technical support and training worldwide
            </p>
          </div>
          <div className="text-center">
            <div className="w-16 h-16 bg-amber-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <i className="ri-shield-check-line text-3xl text-amber-400"></i>
            </div>
            <h4 className="text-xl font-bold text-white mb-2">IP Protection</h4>
            <p className="text-blue-100">
              Secure licensing with full intellectual property protection
            </p>
          </div>
          <div className="text-center">
            <div className="w-16 h-16 bg-amber-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <i className="ri-line-chart-line text-3xl text-amber-400"></i>
            </div>
            <h4 className="text-xl font-bold text-white mb-2">Market Advantage</h4>
            <p className="text-blue-100">
              First-mover advantage in emerging markets
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

