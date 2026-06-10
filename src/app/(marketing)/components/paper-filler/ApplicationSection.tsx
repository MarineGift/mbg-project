'use client';

export default function ApplicationSection() {
  const applications = [
    {
      icon: 'ri-file-copy-line',
      title: 'Copy Paper',
      headline: 'Superior Runnability',
      description: 'Achieve high stiffness and bulk opacity while significantly reducing wood pulp usage.',
      image: 'https://readdy.ai/api/search-image?query=Premium%20white%20copy%20paper%20stack%20with%20excellent%20opacity%20and%20stiffness%2C%20professional%20office%20paper%20quality%2C%20clean%20industrial%20photography%2C%20navy%20blue%20and%20gold%20accent%20lighting%2C%20high-end%20paper%20manufacturing%20product%20showcase&width=600&height=400&seq=copy-paper&orientation=landscape',
      color: 'from-blue-600 to-blue-800',
      iconBg: 'bg-blue-500'
    },
    {
      icon: 'ri-printer-line',
      title: 'Thermal Paper',
      headline: 'Optimized Base Sheet',
      description: 'Provides a smooth, flawless surface essential for thermal coating efficiency and base sheet strength.',
      image: 'https://readdy.ai/api/search-image?query=High-quality%20thermal%20paper%20roll%20with%20smooth%20flawless%20surface%2C%20professional%20receipt%20paper%20for%20thermal%20printing%2C%20industrial%20product%20photography%2C%20navy%20blue%20and%20gold%20lighting%2C%20premium%20paper%20manufacturing%20showcase&width=600&height=400&seq=thermal-paper&orientation=landscape',
      color: 'from-amber-600 to-amber-800',
      iconBg: 'bg-amber-500'
    },
    {
      icon: 'ri-price-tag-3-line',
      title: 'Label Paper',
      headline: 'High Tensile Strength',
      description: 'Enhanced durability for die-cutting performance and cost-efficient production.',
      image: 'https://readdy.ai/api/search-image?query=Durable%20label%20paper%20with%20high%20tensile%20strength%20for%20die-cutting%2C%20professional%20adhesive%20label%20material%2C%20industrial%20manufacturing%20photography%2C%20navy%20blue%20and%20gold%20accent%20lighting%2C%20premium%20paper%20product%20showcase&width=600&height=400&seq=label-paper&orientation=landscape',
      color: 'from-slate-600 to-slate-800',
      iconBg: 'bg-slate-500'
    }
  ];

  return (
    <section className="py-24 bg-gradient-to-b from-slate-50 to-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <span className="inline-block px-6 py-2 bg-amber-500/10 border border-amber-500/30 rounded-full text-amber-700 font-semibold text-sm tracking-wider mb-6 whitespace-nowrap">
            MARKET APPLICATIONS
          </span>
          <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-6">
            Engineered for Industry Leaders
          </h2>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto">
            Our FCC technology delivers superior performance across critical paper manufacturing segments
          </p>
        </div>

        {/* Application Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {applications.map((app, index) => (
            <div 
              key={index}
              className="group relative bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-500 hover:-translate-y-2"
            >
              {/* Image Container */}
              <div className="relative h-64 w-full overflow-hidden">
                <img 
                  src={app.image}
                  alt={app.title}
                  className="w-full h-full object-cover object-center group-hover:scale-110 transition-transform duration-700"
                />
                <div className={`absolute inset-0 bg-gradient-to-t ${app.color} opacity-60 group-hover:opacity-50 transition-opacity`}></div>
                
                {/* Icon */}
                <div className="absolute top-6 left-6">
                  <div className={`w-16 h-16 ${app.iconBg} rounded-xl flex items-center justify-center shadow-lg`}>
                    <i className={`${app.icon} text-3xl text-white`}></i>
                  </div>
                </div>

                {/* Title Overlay */}
                <div className="absolute bottom-6 left-6 right-6">
                  <h3 className="text-2xl font-bold text-white">{app.title}</h3>
                </div>
              </div>

              {/* Content */}
              <div className="p-8">
                <h4 className="text-xl font-bold text-slate-900 mb-4 flex items-center">
                  <span className="w-2 h-2 bg-amber-500 rounded-full mr-3"></span>
                  {app.headline}
                </h4>
                <p className="text-slate-600 leading-relaxed">
                  {app.description}
                </p>

                {/* Feature Tags */}
                <div className="mt-6 flex flex-wrap gap-2">
                  <span className="px-3 py-1 bg-slate-100 text-slate-700 text-sm rounded-full font-medium whitespace-nowrap">
                    Cost Efficient
                  </span>
                  <span className="px-3 py-1 bg-slate-100 text-slate-700 text-sm rounded-full font-medium whitespace-nowrap">
                    High Performance
                  </span>
                </div>
              </div>

              {/* Hover Border Effect */}
              <div className="absolute inset-0 border-2 border-transparent group-hover:border-amber-500 rounded-2xl transition-colors pointer-events-none"></div>
            </div>
          ))}
        </div>

        {/* Bottom CTA */}
        <div className="mt-16 text-center">
          <p className="text-lg text-slate-600 mb-6">
            Ready to transform your paper manufacturing process?
          </p>
          <a 
            href="#contact"
            className="inline-flex items-center px-8 py-4 bg-slate-900 text-white font-semibold rounded-lg hover:bg-slate-800 transition-colors whitespace-nowrap cursor-pointer"
          >
            Request Technical Specifications
            <i className="ri-arrow-right-line ml-3 text-xl"></i>
          </a>
        </div>
      </div>
    </section>
  );
}

