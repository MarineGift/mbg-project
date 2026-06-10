
export default function AboutSection() {
  const values = [
    {
      icon: "ri-lightbulb-line",
      title: "Innovation",
      description: "Creating new possibilities through continuous research and development"
    },
    {
      icon: "ri-leaf-line",
      title: "Sustainability",
      description: "Preparing for the future with eco-friendly technology"
    },
    {
      icon: "ri-award-line",
      title: "Quality",
      description: "Providing the highest quality products and services"
    },
    {
      icon: "ri-global-line",
      title: "Global",
      description: "Leading the world market with advanced technology"
    }
  ];

  return (
    <section id="about" className="py-20 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            About Us
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Discover MarinebioGroup, turning the infinite possibilities 
            of marine biotechnology into reality
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center mb-16">
          {/* Company Story */}
          <div>
            <h3 className="text-3xl font-bold text-gray-900 mb-6">
              Our Vision
            </h3>
            <p className="text-lg text-gray-600 mb-6 leading-relaxed">
              MarinebioGroup believes in the infinite potential of marine biomass materials 
              and aims to enrich human life through this technology. 
              We don't just create products; we provide solutions for a sustainable future.
            </p>
            <p className="text-lg text-gray-600 mb-8 leading-relaxed">
              Based on our world-unique marine nanofiber technology, 
              we develop innovative products across various fields, 
              from cosmetics to industrial materials.
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <button className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold transition-colors whitespace-nowrap cursor-pointer">
                Download Company Brochure
              </button>
              <button className="border-2 border-blue-600 text-blue-600 hover:bg-blue-600 hover:text-white px-6 py-3 rounded-lg font-semibold transition-colors whitespace-nowrap cursor-pointer">
                View Investment Information
              </button>
            </div>
          </div>

          {/* Company Image */}
          <div>
            <img 
              src="https://readdy.ai/api/search-image?query=Modern%20biotechnology%20company%20headquarters%20building%2C%20sleek%20corporate%20architecture%20with%20glass%20facade%2C%20professional%20business%20environment%2C%20clean%20contemporary%20design%2C%20blue%20and%20white%20color%20scheme%2C%20corporate%20campus%20with%20landscaping&width=600&height=400&seq=company-building&orientation=landscape"
              alt="Company overview"
              className="rounded-2xl shadow-lg object-cover w-full h-96 object-top"
            />
          </div>
        </div>

        {/* Company Values */}
        <div className="bg-white rounded-2xl p-12 shadow-lg">
          <div className="text-center mb-12">
            <h3 className="text-3xl font-bold text-gray-900 mb-4">
              Core Values
            </h3>
            <p className="text-xl text-gray-600">
              Values and philosophy that MarinebioGroup pursues
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {values.map((value, index) => (
              <div key={index} className="text-center">
                <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <i className={`${value.icon} text-2xl text-blue-600`}></i>
                </div>
                <h4 className="text-xl font-semibold text-gray-900 mb-3">
                  {value.title}
                </h4>
                <p className="text-gray-600 leading-relaxed">
                  {value.description}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Timeline */}
        <div className="mt-16">
          <div className="text-center mb-12">
            <h3 className="text-3xl font-bold text-gray-900 mb-4">
              Company History
            </h3>
          </div>

          <div className="space-y-8">
            <div className="flex items-center">
              <div className="w-24 text-right mr-8">
                <span className="text-2xl font-bold text-blue-600">2026</span>
              </div>
              <div className="w-4 h-4 bg-blue-600 rounded-full mr-8"></div>
              <div className="flex-1">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">Company Establishment - Global Headquarter&nbsp;</h4>
                <p className="text-gray-600">Marinebio Group Inc. Established in Austin, Texas. FCC Global Patent Submit - USA, EU, Japan, China, India, Indonesia.</p>
              </div>
            </div>

            <div className="flex items-center">
              <div className="w-24 text-right mr-8">
                <span className="text-2xl font-bold text-blue-600">2025</span>
              </div>
              <div className="w-4 h-4 bg-blue-600 rounded-full mr-8"></div>
              <div className="flex-1">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">Global Expansion</h4>
                <p className="text-gray-600">Acquired patents for marine nanofiber extraction and processing technology</p>
              </div>
            </div>

            <div className="flex items-center">
              <div className="w-24 text-right mr-8">
                <span className="text-2xl font-bold text-blue-600">2024</span>
              </div>
              <div className="w-4 h-4 bg-blue-600 rounded-full mr-8"></div>
              <div className="flex-1">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">&nbsp;Technology&nbsp;Innovation</h4>
                <p className="text-gray-600">Launched first commercial product in the cosmetics sector</p>
              </div>
            </div>

            <div className="flex items-center">
              <div className="w-24 text-right mr-8">
                <span className="text-2xl font-bold text-blue-600">2022</span>
              </div>
              <div className="w-4 h-4 bg-blue-600 rounded-full mr-8"></div>
              <div className="flex-1">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">First Product Launch</h4>
                <p className="text-gray-600">Entered international markets and established global partnerships</p>
              </div>
            </div>

            <div className="flex items-center">
              <div className="w-24 text-right mr-8">
                <span className="text-2xl font-bold text-blue-600">2014</span>
              </div>
              <div className="w-4 h-4 bg-blue-600 rounded-full mr-8"></div>
              <div className="flex-1">
                <h4 className="text-xl font-semibold text-gray-900 mb-2">Core Technology Development</h4>
                <p className="text-gray-600">Completed 3rd generation biomass technology and multi-field applications</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

