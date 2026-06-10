
export default function TechnologySection() {
  return (
    <section id="technology" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Core Technology
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            From biomass to nanofibers, our innovative 3rd generation technology 
            revolutionizes quality, functionality, and cost simultaneously
          </p>
        </div>

        {/* Technology Process */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-16">
          {/* Bio Mass */}
          <div className="bg-blue-50 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="ri-leaf-line text-2xl text-white"></i>
            </div>
            <h3 className="text-2xl font-bold text-blue-600 mb-4">Bio Mass</h3>
            <p className="text-gray-700 mb-6">
              1st Gen: Sugar-containing biomass<br />
              2nd Gen: Starch materials<br />
              3rd Gen: Lignocellulosic biomass
            </p>
            <div className="grid grid-cols-2 gap-4">
              <img 
                src="https://readdy.ai/api/search-image?query=Sugar%20beet%20and%20wheat%20biomass%20materials%2C%20natural%20organic%20plant%20fibers%2C%20clean%20white%20laboratory%20background%2C%20scientific%20specimen%20display%2C%20high%20quality%20botanical%20samples%20for%20biotechnology%20research&width=200&height=150&seq=biomass-1&orientation=landscape"
                alt="Biomass materials"
                className="rounded-lg object-cover w-full h-24"
              />
              <img 
                src="https://readdy.ai/api/search-image?query=Corn%20and%20barley%20starch%20materials%2C%20agricultural%20biomass%20samples%2C%20pristine%20white%20background%2C%20scientific%20research%20specimens%2C%20natural%20plant-based%20raw%20materials%20for%20nanofiber%20production&width=200&height=150&seq=biomass-2&orientation=landscape"
                alt="Starch materials"
                className="rounded-lg object-cover w-full h-24"
              />
            </div>
          </div>

          {/* Nanoization Process */}
          <div className="bg-green-50 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="ri-microscope-line text-2xl text-white"></i>
            </div>
            <h3 className="text-2xl font-bold text-green-600 mb-4">Nanoization</h3>
            <p className="text-gray-700 mb-6">
              Innovative nanoization process<br />
              transforms marine bio materials into nanofibers
            </p>
            <img 
              src="https://readdy.ai/api/search-image?query=Microscopic%20nanofiber%20structure%20under%20electron%20microscope%2C%20detailed%20fibrous%20network%20pattern%2C%20scientific%20visualization%20of%20marine%20nanofibers%2C%20clean%20white%20background%2C%20high%20magnification%20cellular%20structure&width=300&height=200&seq=nanoization&orientation=landscape"
              alt="Nanoization process"
              className="rounded-lg object-cover w-full h-32 mx-auto"
            />
          </div>

          {/* Quality Applications */}
          <div className="bg-purple-50 rounded-2xl p-8 text-center">
            <div className="w-16 h-16 bg-purple-600 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="ri-star-line text-2xl text-white"></i>
            </div>
            <h3 className="text-2xl font-bold text-purple-600 mb-4">Quality Applications</h3>
            <p className="text-gray-700 mb-6">
              High-quality products across<br />
              cosmetics, diapers, paper, and more
            </p>
            <div className="grid grid-cols-3 gap-2">
              <img 
                src="https://readdy.ai/api/search-image?query=Premium%20cosmetic%20products%20with%20marine%20nanofiber%20technology%2C%20elegant%20skincare%20packaging%2C%20clean%20white%20background%2C%20luxury%20beauty%20products%2C%20professional%20product%20photography&width=150&height=120&seq=cosmetic&orientation=squarish"
                alt="Cosmetics"
                className="rounded-lg object-cover w-full h-20"
              />
              <img 
                src="https://readdy.ai/api/search-image?query=High-tech%20baby%20diaper%20with%20advanced%20nanofiber%20materials%2C%20modern%20infant%20care%20product%2C%20clean%20white%20background%2C%20premium%20baby%20hygiene%20product%2C%20soft%20comfortable%20design&width=150&height=120&seq=diaper&orientation=squarish"
                alt="Diapers"
                className="rounded-lg object-cover w-full h-20"
              />
              <img 
                src="https://readdy.ai/api/search-image?query=Eco-friendly%20paper%20products%20made%20from%20marine%20nanofibers%2C%20sustainable%20paper%20materials%2C%20clean%20white%20background%2C%20environmentally%20conscious%20paper%20goods%2C%20premium%20quality%20texture&width=150&height=120&seq=paper&orientation=squarish"
                alt="Paper"
                className="rounded-lg object-cover w-full h-20"
              />
            </div>
          </div>
        </div>

        {/* Technology Advantages */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-800 rounded-2xl p-12 text-white">
          <div className="text-center mb-12">
            <h3 className="text-3xl font-bold mb-4">Technology Innovation</h3>
            <p className="text-xl text-blue-100">
              Differentiated technology leveraging unique properties of marine bio materials
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-20 h-20 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <i className="ri-award-line text-3xl text-white"></i>
              </div>
              <h4 className="text-xl font-semibold mb-2">Quality Innovation</h4>
              <p className="text-blue-100">
                Achieving high-quality properties 
                impossible with terrestrial plant materials
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-20 h-20 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <i className="ri-settings-line text-3xl text-white"></i>
              </div>
              <h4 className="text-xl font-semibold mb-2">Enhanced Functionality</h4>
              <p className="text-blue-100">
                Maximizing product functionality 
                through nanofiber technology
              </p>
            </div>
            
            <div className="text-center">
              <div className="w-20 h-20 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <i className="ri-money-dollar-circle-line text-3xl text-white"></i>
              </div>
              <h4 className="text-xl font-semibold mb-2">Cost Efficiency</h4>
              <p className="text-blue-100">
                Optimizing production costs 
                through innovative processes
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

