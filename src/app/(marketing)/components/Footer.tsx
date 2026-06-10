import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Company Info */}
          <div className="col-span-1 md:col-span-2">
            <div className="mb-4">
              <img 
                src="https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/316a2b7fdbb9930ebedac283acd4ea0e.jpeg" 
                alt="MarinebioGroup Logo" 
                className="h-12 w-auto object-contain"
              />
            </div>
            <p className="text-gray-300 mb-4 leading-relaxed">
              A world-leading research company with unique marine nanofiber technology, 
              developing high-quality products using marine biomass materials.
            </p>
            <div className="flex space-x-4">
              <a href="https://www.linkedin.com/in/yunyoung-heo-a2640a195/" target="_blank" rel="noopener noreferrer" className="text-gray-400 hover:text-blue-400 transition-colors cursor-pointer">
                <i className="fab fa-linkedin text-xl"></i>
              </a>
              <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors cursor-pointer">
                <i className="fab fa-twitter text-xl"></i>
              </a>
              <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors cursor-pointer">
                <i className="fab fa-facebook text-xl"></i>
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li><a href="#technology" className="text-gray-300 hover:text-blue-400 transition-colors cursor-pointer">Technology</a></li>
              <li><a href="#products" className="text-gray-300 hover:text-blue-400 transition-colors cursor-pointer">Products</a></li>
              <li><a href="#research" className="text-gray-300 hover:text-blue-400 transition-colors cursor-pointer">Research</a></li>
              <li><a href="#about" className="text-gray-300 hover:text-blue-400 transition-colors cursor-pointer">About</a></li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h3 className="text-lg font-semibold mb-4">Contact</h3>
            <div className="space-y-2 text-gray-300">
              <div className="flex items-center">
                <i className="ri-mail-line mr-2"></i>
                <span>ceo@marinebiogroup.com</span>
              </div>
              <div className="flex items-center">
                <i className="ri-phone-line mr-2"></i>
                <span>(512) 996-7083</span>
              </div>
              <div className="flex items-center">
                <i className="ri-map-pin-line mr-2"></i>
                <span>1108 Nueces St, Austin, TX 78701, USA</span>
              </div>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-800 mt-8 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p className="text-gray-400 text-sm">
            © 2024 MarinebioGroup. All rights reserved.
          </p>
          <Link 
            href="https://readdy.ai/?origin=logo" 
            className="text-gray-400 hover:text-blue-400 text-sm transition-colors cursor-pointer mt-2 md:mt-0"
          >
            Powered by Readdy
          </Link>
        </div>
      </div>
    </footer>
  );
}
