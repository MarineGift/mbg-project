'use client';

export default function ResearchSection() {
  const achievements = [
    {
      number: "15+",
      label: "Research Patents",
      description: "Core patents in marine nanofiber technology"
    },
    {
      number: "50+",
      label: "Research Papers",
      description: "Publications in international journals"
    },
    {
      number: "10+",
      label: "Research Partners",
      description: "Collaborations with global institutions"
    },
    {
      number: "3rd Gen",
      label: "Technology Innovation",
      description: "Next-generation biomass technology development"
    }
  ];

  const patents = [
    { no: 1, title: 'Manufacturing Method of Pulp Using Red Algae', category: 'pulp' },
    { no: 2, title: 'A method of manufacturing pulp with low internal gel extract content from red algae', category: 'pulp' },
    { no: 3, title: 'Manufacturing Method of Pulp Using Thick Red Algae', category: 'pulp' },
    { no: 4, title: 'Manufacturing Method of Pulp Using Thin-skinned Red Algae', category: 'pulp' },
    { no: 5, title: 'A method of manufacturing pulp with high internal gel extract content from algae', category: 'pulp' },
    { no: 6, title: 'Pulps manufactured from red algae and their manufacturing methods', category: 'pulp' },
    { no: 7, title: 'Electronic component case using bio-composite material with seaweeds fiber reinforcement', category: 'bio-composite' },
    { no: 8, title: 'Bio-complex materials with red algae fibers as reinforcing materials and bio-complex materials with excellent fiber dispersion using high temperature', category: 'bio-composite' },
    { no: 9, title: 'Korean paper containing red algae fibers', category: 'traditional paper' },
    { no: 10, title: 'Manufacturing Method of Paper Surface Size Agent Using Raincoat from Red Algae', category: 'papermaking' },
    { no: 11, title: 'Manufacturing method of opaque low-volume paper and opaque low-volume paper', category: 'papermaking' },
    { no: 12, title: 'Transparent red algae food wrapper and its manufacturing method', category: 'food packaging' },
    { no: 13, title: 'Bio with low concentrations of toxic substances from red algae — manufacturing of alcohol raw materials and bio-alcohol', category: 'bio-ethanol' },
    { no: 14, title: 'Method for production of methane gas using red algae extract', category: 'methane generation' },
    { no: 15, title: 'An opaque food wrapper using red algae and its manufacturing method', category: 'food packaging' },
    { no: 16, title: 'Pretendable food film using red algae and its manufacturing method', category: 'edible film' },
    { no: 17, title: 'Sheet for mask pack containing seaweeds fiber and its manufacturing method', category: 'cosmetics' },
    { no: 18, title: 'Transparent high density from algae — manufacturing of raw material pulp and transparent high density paper (tracing paper)', category: 'papermaking' },
    { no: 19, title: 'The manufacturing method of RA-PLA and the RA-PLA manufactured thereunder', category: 'bio-plastic' },
    { no: 20, title: 'Dehydrate Red algae low molecular extract and dehydrate drying method', category: 'food additive' },
    { no: 21, title: 'Oil control paper containing marine algae for removing skin oil and the method for manufacturing thereof', category: 'cosmetics' },
    { no: 22, title: 'Paper yarn comprising red algae fiber and method for manufacturing thereof', category: 'fabrics' },
    { no: 23, title: '(PCT) Manufacturing method of pulp using algali or algali residues pulsed with alkali aqueous solution, and paper prepared therefrom', category: 'pulping method', isNew: true },
    { no: 24, title: '(Registered) Manufacturing method of sheet for mask packs containing seaweeds fibers and sheet for mask packs manufactured therefrom', category: 'cosmetic', isNew: true },
  ];

  const sciJournals = [
    { no: 1, description: 'Seo, Y.B., Lee, Y.W., Lee, C.H., You, H.C., Gelidium and their use in papermaking, BIORESOURCE TECHNOLOGY. 101(7):2549-2553, (2010)' },
    { no: 2, description: 'CELL 79-Algae fiber and its biocomposites, ABSTRACTS OF PAPERS OF THE AMERICAN CHEMICAL SOCIETY, 233:790-790 (2007)' },
    { no: 3, description: 'Ku, K.J., Hong, Y.H., Seo, Y.B., Chung, K.S., and Song, K.B., Application of edible Gelidium paper coated with green tea extract for shelf life extension of kimbab, FOOD SCIENCE AND BIOTECHNOLOGY, 17(2):421-424 (2008)' },
    { no: 4, description: 'Lee, M.W., Han, S.O., and Seo, Y.B., Gelidium fibre/poly(butylene succinate) biocomposites: The effect of fibre content on their mechanical and thermal properties, COMPOSITES SCIENCE AND TECHNOLOGY, 68(6):1266-1272 (2008)' },
    { no: 5, description: 'Boo, S.M., Kim, K.M., Hwang, I.K., Yoon, H.S., and Seo, Y.B., Diversity, morphology, and phylogeny of the marine pulp-producing alga gelidiales (rhodophyta), JOURNAL OF BIOTECHNOLOGY, 136:S523-S523 (2008)' },
    { no: 6, description: 'Sim, K.J., Han, S.O., and Seo, Y.B., Dynamic Mechanical and Thermal Properties of Gelidium Fiber Reinforced Poly(lactic acid) Biocomposites, MACROMOLECULAR RESEARCH, 18(5):489-495, (2010)' },
    { no: 7, description: 'Seo, Y.B., Lee, Y.W., Lee, C.H., and Lee, M.W., Optical Properties of Gelidium Fibers, INDUSTRIAL & ENGINEERING CHEMISTRY RESEARCH, 49(20):9830-9833 (2010)' },
    { no: 8, description: 'Jang, S.A., Shin, Y.J., Seo, Y.B. and Song, K.B. Effects of Various Plasticizers and Nanoclays on the Mechanical Properties of Gelidium Film, JOURNAL OF FOOD SCIENCE, 76(3):N30-N34 (2011)' },
    { no: 9, description: 'Seo, Y.B., and Lee, M.W., Use of non-wood fibres (from cattails and Gelidium) and their effects on paper opacity, APPITA JOURNAL, 64(5):445-449, (2011)' },
    { no: 10, description: 'Shin, Y.J., Song, H.Y., Seo, Y.B., and Song, K.B., Preparation of Gelidium Film Containing Grapefruit Seed Extract and Application for the Packaging of Cheese and Bacon, FOOD SCIENCE AND BIOTECHNOLOGY, 21(1): 225-231, (2012)' },
    { no: 11, description: 'Yoon, M.H., Lee, Y.W., Lee, C.H., Seo, Y.B., Simultaneous production of bio-ethanol and bleached pulp from Gelidium, BIORESOURCE TECHNOLOGY, 126:198-201, (2012)' },
    { no: 12, description: 'Bondable and Biodegradable Cellulosic Opacifiers, INDUSTRIAL & ENGINEERING CHEMISTRY RESEARCH, 52(29): 9812-9815, (2013)' },
    { no: 13, description: 'Le Van Hai, Ha Neul Son, Yung Bum Seo, Physical and bio-composite properties of nanocrystalline cellulose from wood, cotton linters, cattail, and Gelidium, CELLULOSE, 22(3):1789-1798, (2015)' },
    { no: 14, description: 'Le Van Hai, Yung Bum Seo, Characterization of cellulose nanocrystal obtained from electron beam treated cellulose fiber, Nordic Pulp and Paper Research J. 32(2):170-178 (2017)' },
    { no: 15, description: 'Yung Bum Seo, Ji Hwan Ahn, Hak Lae Lee, Upgrading waste paper by in-situ calcium carbonate formation, JOURNAL OF CLEANER PRODUCTION, 155(1):212-217, (2017)' },
  ];

  const categoryColors: Record<string, string> = {
    'pulp': 'bg-red-100 text-red-700',
    'bio-composite': 'bg-orange-100 text-orange-700',
    'traditional paper': 'bg-amber-100 text-amber-700',
    'papermaking': 'bg-yellow-100 text-yellow-700',
    'food packaging': 'bg-teal-100 text-teal-700',
    'bio-ethanol': 'bg-green-100 text-green-700',
    'methane generation': 'bg-emerald-100 text-emerald-700',
    'edible film': 'bg-lime-100 text-lime-700',
    'cosmetics': 'bg-pink-100 text-pink-700',
    'cosmetic': 'bg-pink-100 text-pink-700',
    'bio-plastic': 'bg-cyan-100 text-cyan-700',
    'food additive': 'bg-indigo-100 text-indigo-700',
    'fabrics': 'bg-violet-100 text-violet-700',
    'pulping method': 'bg-red-100 text-red-700',
  };

  return (
    <section id="research" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Research & Development
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Through continuous R&D, we unlock new possibilities 
            in marine nanofiber technology
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center mb-16">
          {/* Research Image */}
          <div className="order-2 lg:order-1">
            <img 
              src="https://readdy.ai/api/search-image?query=Advanced%20marine%20biotechnology%20research%20laboratory%2C%20scientists%20working%20with%20microscopes%20and%20nanofiber%20samples%2C%20modern%20scientific%20equipment%2C%20clean%20white%20laboratory%20environment%2C%20professional%20researchers%20in%20lab%20coats%2C%20high-tech%20molecular%20analysis&width=600&height=400&seq=research-lab&orientation=landscape"
              alt="Research and development"
              className="rounded-2xl shadow-lg object-cover w-full h-96 object-top"
            />
          </div>

          {/* Research Content */}
          <div className="order-1 lg:order-2">
            <h3 className="text-3xl font-bold text-gray-900 mb-6">
              World-Class Research Excellence
            </h3>
            <p className="text-lg text-gray-600 mb-8 leading-relaxed">
              MarinebioGroup is a pioneer in marine biomass research, 
              continuously investing in R&D to develop innovative technologies. 
              Our research team collaborates with experts worldwide 
              to lead next-generation nanofiber technology.
            </p>

            <div className="space-y-4">
              <div className="flex items-start">
                <div className="w-8 h-8 bg-teal-100 rounded-full flex items-center justify-center mr-4 mt-1">
                  <i className="ri-flask-line text-teal-600"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-1">Advanced Research Facilities</h4>
                  <p className="text-gray-600">Conducting precise analysis and experiments with state-of-the-art equipment.</p>
                </div>
              </div>

              <div className="flex items-start">
                <div className="w-8 h-8 bg-teal-100 rounded-full flex items-center justify-center mr-4 mt-1">
                  <i className="ri-team-line text-teal-600"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-1">Expert Research Team</h4>
                  <p className="text-gray-600">Top specialists in marine biology, nanotechnology, and materials engineering.</p>
                </div>
              </div>

              <div className="flex items-start">
                <div className="w-8 h-8 bg-teal-100 rounded-full flex items-center justify-center mr-4 mt-1">
                  <i className="ri-global-line text-teal-600"></i>
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-1">Global Collaboration</h4>
                  <p className="text-gray-600">Enhancing technology through joint research with leading universities and institutions worldwide.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Research Achievements */}
        <div className="bg-gradient-to-r from-teal-600 to-teal-800 rounded-2xl p-12 mb-16">
          <div className="text-center mb-12">
            <h3 className="text-3xl font-bold text-white mb-4">
              Research Achievements
            </h3>
            <p className="text-xl text-teal-100">
              Outstanding results from continuous research and development
            </p>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
            {achievements.map((achievement, index) => (
              <div key={index} className="text-center">
                <div className="text-4xl font-bold text-white mb-2">
                  {achievement.number}
                </div>
                <div className="text-xl font-semibold text-teal-100 mb-2">
                  {achievement.label}
                </div>
                <div className="text-sm text-teal-200">
                  {achievement.description}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Government Certification Section */}
        <div className="bg-gradient-to-br from-slate-50 to-teal-50 rounded-2xl p-12 border border-teal-100 mb-16">
          <div className="text-center mb-12">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-teal-100 rounded-full mb-4">
              <i className="ri-government-line text-teal-700 text-2xl"></i>
            </div>
            <h3 className="text-3xl font-bold text-gray-900 mb-4">
              Government-Certified Innovation Technology
            </h3>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Officially recognized as a <strong>New Excellent Technology (NET)</strong> by the 
              <strong> Ministry of Oceans and Fisheries, Republic of Korea</strong> — 
              a testament to our breakthrough in marine biomass innovation.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Certificate Image */}
            <div className="flex justify-center">
              <div className="relative">
                <div className="absolute -inset-3 bg-gradient-to-r from-teal-200 to-teal-400 rounded-2xl opacity-30 blur-sm"></div>
                <img
                  src="https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/0b1e747313b51c08e640e2dca9dfec43.jpeg"
                  alt="Certificate of New Excellent Technology - Ministry of Oceans and Fisheries, Republic of Korea"
                  className="relative rounded-xl shadow-2xl w-full max-w-sm object-cover"
                />
              </div>
            </div>

            {/* Certification Details */}
            <div className="space-y-6">
              <div className="flex items-start space-x-4">
                <div className="w-10 h-10 flex items-center justify-center bg-teal-600 rounded-full shrink-0">
                  <i className="ri-award-line text-white text-lg"></i>
                </div>
                <div>
                  <h4 className="text-lg font-bold text-gray-900 mb-1">New Excellent Technology (NET) Certification</h4>
                  <p className="text-gray-600 text-sm leading-relaxed">
                    Certified under Article 17(1) of the Act on Support of Science and Technology for Oceans and Fisheries. 
                    Certificate Number: <strong>2023-0010</strong>
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="w-10 h-10 flex items-center justify-center bg-teal-600 rounded-full shrink-0">
                  <i className="ri-microscope-line text-white text-lg"></i>
                </div>
                <div>
                  <h4 className="text-lg font-bold text-gray-900 mb-1">Certified Technology</h4>
                  <p className="text-gray-600 text-sm leading-relaxed">
                    Manufacturing technology for a <strong>natural superabsorbent polymer using a chitin-derived nanomesh</strong> — 
                    a world-first innovation derived from marine biomass.
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="w-10 h-10 flex items-center justify-center bg-teal-600 rounded-full shrink-0">
                  <i className="ri-calendar-check-line text-white text-lg"></i>
                </div>
                <div>
                  <h4 className="text-lg font-bold text-gray-900 mb-1">Validity Period</h4>
                  <p className="text-gray-600 text-sm leading-relaxed">
                    Issued on <strong>October 13, 2023</strong> · Valid through <strong>July 9, 2028</strong>
                  </p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="w-10 h-10 flex items-center justify-center bg-teal-600 rounded-full shrink-0">
                  <i className="ri-building-2-line text-white text-lg"></i>
                </div>
                <div>
                  <h4 className="text-lg font-bold text-gray-900 mb-1">Issuing Authority</h4>
                  <p className="text-gray-600 text-sm leading-relaxed">
                    <strong>Minister of Oceans and Fisheries, Republic of Korea</strong> — 
                    the highest governmental body overseeing marine science and technology.
                  </p>
                </div>
              </div>

              <div className="mt-6 p-4 bg-teal-600 rounded-xl text-white">
                <p className="text-sm leading-relaxed">
                  <i className="ri-shield-check-line mr-2"></i>
                  This certification confirms that our chitin-derived nanomesh technology represents a 
                  <strong> nationally recognized breakthrough</strong> in sustainable marine biotechnology, 
                  setting a new global standard for eco-friendly superabsorbent materials.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Patent List Section */}
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="bg-gradient-to-r from-gray-800 to-gray-900 px-8 py-8 text-center">
            <div className="inline-flex items-center justify-center w-14 h-14 bg-white/10 rounded-full mb-4">
              <i className="ri-file-shield-2-line text-white text-2xl"></i>
            </div>
            <h3 className="text-3xl font-bold text-white mb-2">
              Registration and Application Patents
            </h3>
            <p className="text-gray-300 text-base">
              Red Algae Technology Patents — Prof. Seo Yung-Bum / Director Lee Yoon-woo
            </p>
          </div>

          {/* New patents notice */}
          <div className="bg-red-50 border-b border-red-100 px-8 py-3 flex items-center space-x-2">
            <i className="ri-error-warning-line text-red-600"></i>
            <span className="text-sm text-red-700 font-medium">
              No. 23–24: New patents applied by reinforcing existing patents (domestic and PCT international patents)
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200">
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider w-16">No</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Patent Details</th>
                  <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider w-40">Category</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {patents.map((patent) => (
                  <tr
                    key={patent.no}
                    className={`hover:bg-gray-50 transition-colors ${patent.isNew ? 'bg-red-50/40' : ''}`}
                  >
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold ${patent.isNew ? 'bg-red-600 text-white' : 'bg-gray-100 text-gray-600'}`}>
                        {patent.no}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <p className={`text-sm leading-relaxed ${patent.isNew ? 'text-red-700 font-medium' : 'text-gray-700'}`}>
                        {patent.title}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-block text-xs px-2.5 py-1 rounded-full font-medium whitespace-nowrap ${categoryColors[patent.category] || 'bg-gray-100 text-gray-600'}`}>
                        {patent.category}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="px-8 py-5 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
            <div className="flex items-center space-x-2 text-sm text-gray-500">
              <i className="ri-information-line"></i>
              <span>Total <strong className="text-gray-800">24</strong> patents registered and applied</span>
            </div>
            <div className="flex items-center space-x-4 text-xs text-gray-400">
              <span className="flex items-center space-x-1">
                <span className="inline-block w-3 h-3 rounded-full bg-red-600"></span>
                <span>New / PCT International</span>
              </span>
              <span className="flex items-center space-x-1">
                <span className="inline-block w-3 h-3 rounded-full bg-gray-300"></span>
                <span>Registered</span>
              </span>
            </div>
          </div>
        </div>

        {/* SCI Journal List Section */}
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden mt-12">
          <div className="bg-gradient-to-r from-red-700 to-red-900 px-8 py-8 text-center">
            <div className="inline-flex items-center justify-center w-14 h-14 bg-white/10 rounded-full mb-4">
              <i className="ri-article-line text-white text-2xl"></i>
            </div>
            <h3 className="text-3xl font-bold text-white mb-2">
              SCI-grade Journals
            </h3>
            <p className="text-red-200 text-base">
              Related to use of red algae and nanocellulose
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-800 text-white">
                  <th className="px-6 py-4 text-left text-sm font-semibold w-16">No</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold">Description</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {sciJournals.map((journal) => (
                  <tr key={journal.no} className="hover:bg-red-50/30 transition-colors">
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold bg-gray-100 text-gray-600">
                        {journal.no}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm text-gray-700 leading-relaxed">{journal.description}</p>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="px-8 py-5 bg-gray-50 border-t border-gray-200 flex items-center space-x-2 text-sm text-gray-500">
            <i className="ri-information-line"></i>
            <span>총 <strong className="text-gray-800">15</strong>편의 SCI급 국제 학술지 논문 게재</span>
          </div>
        </div>

      </div>
    </section>
  );
}
