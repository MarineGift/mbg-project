'use client';


import { useState } from 'react';

export default function ProductsSection() {
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [selectedProduct, setSelectedProduct] = useState<number | null>(null);

  const categories = ['All', 'Cosmetics', 'Bio-SAP', 'Paper'];

  const products = [
    {
      category: "Cosmetics",
      title: "Natural Soap",
      description: "Premium natural soap enriched with marine nanofibers for gentle cleansing and superior moisturizing properties.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/15eac05385e1d4b27684af717747e642.jpeg",
      features: ["Natural Ingredients", "Deep Cleansing", "Moisturizing"],
      detailedInfo: {
        overview: "Our natural soap combines traditional soap-making techniques with cutting-edge marine nanofiber technology to deliver exceptional cleansing while maintaining skin's natural moisture balance.",
        keyBenefits: [
          "Gentle cleansing without stripping natural oils",
          "Rich lather with marine mineral benefits",
          "Suitable for all skin types including sensitive skin",
          "Long-lasting formula with natural preservation",
          "Eco-friendly biodegradable ingredients"
        ],
        ingredients: "Marine nanofibers, Coconut oil, Olive oil, Shea butter, Natural glycerin, Essential oils",
        usage: "Wet hands and soap, create lather, gently massage onto skin, rinse thoroughly with water."
      }
    },
    {
      category: "Cosmetics",
      title: "Face Mask",
      description: "Revitalizing face mask with marine collagen and nanofiber technology for deep hydration and anti-aging benefits.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/96f5a33690dc1d43dc4bf8612039bd07.jpeg",
      features: ["Deep Hydration", "Anti-Aging", "Skin Brightening"],
      detailedInfo: {
        overview: "Our advanced face mask harnesses marine collagen and nanofiber technology to provide intensive hydration and visible anti-aging results in just 15 minutes.",
        keyBenefits: [
          "Instant hydration boost lasting 48 hours",
          "Reduces fine lines and wrinkles",
          "Improves skin elasticity and firmness",
          "Brightens and evens skin tone",
          "Dermatologically tested for safety"
        ],
        ingredients: "Marine collagen, Marine nanofibers, Hyaluronic acid, Vitamin C, Peptides, Botanical extracts",
        usage: "Apply evenly to clean face, leave for 15-20 minutes, remove gently and massage remaining essence into skin."
      }
    },
    {
      category: "Cosmetics",
      title: "Sun Screen",
      description: "Advanced sun protection with marine nanofiber technology offering broad-spectrum UV defense and skin nourishment.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/2512458350bcd76c09ab3d2828086115.jpeg",
      features: ["Broad Spectrum Protection", "Water Resistant", "Non-Greasy Formula"],
      detailedInfo: {
        overview: "Our innovative sunscreen combines superior UV protection with marine nanofiber technology to shield skin while providing continuous nourishment and hydration.",
        keyBenefits: [
          "SPF 50+ broad-spectrum UVA/UVB protection",
          "Water-resistant for up to 80 minutes",
          "Lightweight, non-greasy formula",
          "Enriched with marine antioxidants",
          "Suitable for face and body application"
        ],
        ingredients: "Zinc oxide, Titanium dioxide, Marine nanofibers, Vitamin E, Aloe vera, Marine algae extract",
        usage: "Apply generously 15 minutes before sun exposure. Reapply every 2 hours or after swimming/sweating."
      }
    },
    {
      category: "Cosmetics",
      title: "Tone Up",
      description: "Brightening tone-up cream with marine nanofibers for instant skin illumination and long-lasting radiance.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/2a87d3ae034f8ec6d4c3174af6225cd7.jpeg",
      features: ["Instant Brightening", "Natural Glow", "Long-Lasting"],
      detailedInfo: {
        overview: "Our tone-up cream utilizes marine nanofiber technology to instantly brighten and illuminate skin while providing long-term skin improvement benefits.",
        keyBenefits: [
          "Instant skin brightening and illumination",
          "Creates natural, healthy glow",
          "Evens out skin tone and texture",
          "Provides light coverage for imperfections",
          "Contains skin-improving marine nutrients"
        ],
        ingredients: "Marine nanofibers, Niacinamide, Pearl powder, Vitamin C, Light-reflecting particles, Marine peptides",
        usage: "Apply evenly to clean face as the last step of skincare routine. Can be used alone or under makeup."
      }
    },
    {
      category: "Bio-SAP",
      title: "High-Performance Diapers",
      description: "Diapers made with nanofiber technology offering superior absorption and breathability.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/7a649bcc17f0b84791334de5ef7e8b99.jpeg",
      features: ["Ultra-High Absorption", "Excellent Breathability", "Skin-Friendly"],
      detailedInfo: {
        overview: "Revolutionary diaper technology using marine nanofibers to provide exceptional absorption capacity while maintaining optimal breathability for baby's comfort and health.",
        keyBenefits: [
          "Absorbs up to 40% more liquid than conventional diapers",
          "Advanced breathability prevents diaper rash",
          "Hypoallergenic materials safe for sensitive skin",
          "Leak-proof protection for up to 12 hours",
          "Eco-friendly biodegradable components"
        ],
        ingredients: "Marine nanofiber core, Soft cotton blend, Hypoallergenic adhesives, Breathable outer layer",
        usage: "Change regularly every 3-4 hours or when soiled. Ensure proper fit for maximum comfort."
      }
    },
    {
      category: "Paper",
      title: "Cost Saving Paper Filler",
      description: "An eco-friendly paper additive that applies innovative technology to reduce pulp usage through revolutionary microfiber processing technology.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/716e4de89aa85deee92f835203edc8cd.png",
      features: ["Pulp Usage Reduction", "Cost Effective", "Eco-Friendly Technology"],
      detailedInfo: {
        overview: "A revolutionary paper additive technology that enables the production of high-quality paper while significantly reducing conventional pulp usage through innovative microfiber processing technology.",
        keyBenefits: [
          "Reduces pulp usage by up to 30%",
          "Significantly saves paper production costs",
          "Improves paper strength and quality",
          "Implements eco-friendly paper manufacturing process",
          "Perfect compatibility with existing paper manufacturing equipment"
        ],
        ingredients: "Marine microfiber technology, Natural binding agents, Eco-friendly processing compounds, Sustainable fiber enhancers",
        usage: "Add as an additive to existing paper manufacturing process and mix with pulp. Recommended addition amount is 5-15% of total raw materials."
      }
    },
    {
      category: "Bio-SAP",
      title: "Advanced Sanitary Pads",
      description: "Revolutionary sanitary pads with marine nanofiber technology for superior comfort and protection.",
      image: "https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/0555cc65db223230da04aec830267327.jpeg",
      features: ["Ultra-Thin Design", "Maximum Absorption", "Odor Control"],
      detailedInfo: {
        overview: "Our advanced sanitary pads utilize marine nanofiber technology to provide exceptional protection, comfort, and confidence during menstrual cycles.",
        keyBenefits: [
          "Ultra-thin design with maximum absorption capacity",
          "Advanced odor control technology",
          "Soft, breathable top layer for comfort",
          "Leak-proof protection for up to 8 hours",
          "Hypoallergenic and dermatologically tested"
        ],
        ingredients: "Marine nanofiber core, Soft cotton top sheet, Breathable back sheet, Natural odor control agents",
        usage: "Change every 4-6 hours or as needed. Dispose of responsibly in waste bins."
      }
    }
  ];

  const filteredProducts = selectedCategory === 'All' 
    ? products 
    : products.filter(product => product.category === selectedCategory);

  const openProductDetail = (index: number) => {
    setSelectedProduct(index);
  };

  const closeProductDetail = () => {
    setSelectedProduct(null);
  };

  const scrollToContact = () => {
    closeProductDetail();
    const contactSection = document.getElementById('contact');
    if (contactSection) {
      contactSection.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section id="products" className="py-20 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Innovative Products
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Discover high-quality products across various industries 
            powered by marine nanofiber technology
          </p>
        </div>

        {/* Category Filter */}
        <div className="flex justify-center mb-12">
          <div className="bg-white rounded-full p-2 shadow-lg">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-6 py-3 rounded-full font-semibold transition-all whitespace-nowrap cursor-pointer ${
                  selectedCategory === category
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-gray-600 hover:text-blue-600 hover:bg-blue-50'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        {/* Products Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-4 gap-8 mb-16" data-product-shop>
          {filteredProducts.map((product, index) => (
            <div key={index} className="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
              <div className="relative">
                <img 
                  src={product.image}
                  alt={product.title}
                  className="w-full h-64 object-cover object-top"
                />
                <div className="absolute top-4 left-4">
                  <span className="bg-blue-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                    {product.category}
                  </span>
                </div>
              </div>
              
              <div className="p-6">
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  {product.title}
                </h3>
                <p className="text-gray-600 mb-4 leading-relaxed text-sm">
                  {product.description}
                </p>
                
                <div className="space-y-2 mb-6">
                  {product.features.map((feature, featureIndex) => (
                    <div key={featureIndex} className="flex items-center text-sm text-gray-700">
                      <i className="ri-check-line text-green-500 mr-2"></i>
                      {feature}
                    </div>
                  ))}
                </div>
                
                <button 
                  onClick={() => openProductDetail(index)}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold transition-colors whitespace-nowrap cursor-pointer"
                >
                  Learn More
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* CTA Section */}
        <div className="bg-white rounded-2xl p-12 text-center shadow-lg">
          <h3 className="text-3xl font-bold text-gray-900 mb-4">
            Need a Custom Solution?
          </h3>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            We provide optimized marine nanofiber technology solutions 
            tailored to your business needs
          </p>
          <button 
            onClick={() => {
              const contactSection = document.getElementById('contact');
              if (contactSection) {
                contactSection.scrollIntoView({ behavior: 'smooth' });
              }
            }}
            className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-lg text-lg font-semibold transition-colors whitespace-nowrap cursor-pointer"
          >
            Request Consultation
          </button>
        </div>
      </div>

      {/* Product Detail Modal */}
      {selectedProduct !== null && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="relative">
              <button
                onClick={closeProductDetail}
                className="absolute top-4 right-4 z-10 bg-gray-100 hover:bg-gray-200 rounded-full p-2 cursor-pointer"
              >
                <i className="ri-close-line text-xl"></i>
              </button>
              
              <div className="p-8">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                  <div>
                    <img
                      src={filteredProducts[selectedProduct].image}
                      alt={filteredProducts[selectedProduct].title}
                      className="w-full h-80 object-cover object-top rounded-xl"
                    />
                  </div>
                  
                  <div>
                    <div className="mb-4">
                      <span className="bg-blue-600 text-white px-3 py-1 rounded-full text-sm font-medium">
                        {filteredProducts[selectedProduct].category}
                      </span>
                    </div>
                    
                    <h2 className="text-3xl font-bold text-gray-900 mb-4">
                      {filteredProducts[selectedProduct].title}
                    </h2>
                    
                    <p className="text-gray-600 mb-6 leading-relaxed">
                      {filteredProducts[selectedProduct].detailedInfo.overview}
                    </p>
                    
                    <div className="mb-6">
                      <h3 className="text-xl font-semibold text-gray-900 mb-3">Key Benefits</h3>
                      <ul className="space-y-2">
                        {filteredProducts[selectedProduct].detailedInfo.keyBenefits.map((benefit, index) => (
                          <li key={index} className="flex items-start text-gray-700">
                            <i className="ri-check-line text-green-500 mr-2 mt-1"></i>
                            {benefit}
                          </li>
                        ))}
                      </ul>
                    </div>
                    
                    <div className="mb-6">
                      <h3 className="text-xl font-semibold text-gray-900 mb-3">Key Ingredients</h3>
                      <p className="text-gray-700">{filteredProducts[selectedProduct].detailedInfo.ingredients}</p>
                    </div>
                    
                    <div className="mb-8">
                      <h3 className="text-xl font-semibold text-gray-900 mb-3">Usage Instructions</h3>
                      <p className="text-gray-700">{filteredProducts[selectedProduct].detailedInfo.usage}</p>
                    </div>
                    
                    <button 
                      onClick={scrollToContact}
                      className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold transition-colors whitespace-nowrap cursor-pointer"
                    >
                      Contact for More Information
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}

