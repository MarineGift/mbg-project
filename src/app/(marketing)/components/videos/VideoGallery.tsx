'use client';


import { useState, useEffect } from 'react';

interface Video {
  id: string;
  title: string;
  category: 'company' | 'media' | 'product';
  youtubeUrl: string;
  description: string;
  thumbnail: string;
}

export default function VideoGallery() {
  const [activeCategory, setActiveCategory] = useState<'all' | 'company' | 'media' | 'product'>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [videos, setVideos] = useState<Video[]>([]);
  const videosPerPage = 12;

  // Load videos from localStorage (saved by Admin)
  useEffect(() => {
    const savedVideos = localStorage.getItem('adminVideos');
    if (savedVideos) {
      setVideos(JSON.parse(savedVideos));
    } else {
      // Default video data
      const defaultVideos = [
        {
          id: '1',
          title: 'Company Overview 2024',
          category: 'company' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'MarinebioGroup company introduction video',
          thumbnail: 'https://readdy.ai/api/search-image?query=modern%20biotechnology%20company%20office%20building%20with%20marine%20blue%20corporate%20colors%20and%20professional%20atmosphere&width=320&height=180&seq=1&orientation=landscape'
        },
        {
          id: '2',
          title: 'KBS News Coverage',
          category: 'media' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'KBS news report on our breakthrough technology',
          thumbnail: 'https://readdy.ai/api/search-image?query=KBS%20news%20studio%20with%20reporter%20discussing%20biotechnology%20innovation%20and%20marine%20research%20breakthrough&width=320&height=180&seq=2&orientation=landscape'
        },
        {
          id: '3',
          title: 'Nanofiber Technology Demo',
          category: 'product' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'Demonstration of our advanced nanofiber technology',
          thumbnail: 'https://readdy.ai/api/search-image?query=advanced%20nanofiber%20technology%20laboratory%20demonstration%20with%20microscopic%20fibers%20and%20scientific%20equipment&width=320&height=180&seq=3&orientation=landscape'
        },
        {
          id: '4',
          title: 'Cosmetics Product Line',
          category: 'product' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'Introduction to our natural cosmetics product line',
          thumbnail: 'https://readdy.ai/api/search-image?query=natural%20cosmetics%20products%20display%20with%20elegant%20packaging%20and%20marine-inspired%20ingredients&width=320&height=180&seq=4&orientation=landscape'
        },
        {
          id: '5',
          title: 'SBS Technology Report',
          category: 'media' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'SBS special report on marine biotechnology innovation',
          thumbnail: 'https://readdy.ai/api/search-image?query=SBS%20news%20broadcast%20studio%20with%20technology%20reporter%20discussing%20marine%20biotechnology%20breakthrough&width=320&height=180&seq=5&orientation=landscape'
        },
        {
          id: '6',
          title: 'CEO Interview 2024',
          category: 'company' as const,
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          description: 'CEO discussing company vision and future plans',
          thumbnail: 'https://readdy.ai/api/search-image?query=professional%20CEO%20interview%20setting%20with%20modern%20office%20background%20and%20corporate%20atmosphere&width=320&height=180&seq=6&orientation=landscape'
        }
      ];
      setVideos(defaultVideos);
      localStorage.setItem('adminVideos', JSON.stringify(defaultVideos));
    }
  }, []);

  const categories = [
    { key: 'all' as const, label: 'All Videos', icon: 'ri-video-line' },
    { key: 'company' as const, label: 'Company Introduction', icon: 'ri-building-line' },
    { key: 'media' as const, label: 'Media Coverage', icon: 'ri-tv-line' },
    { key: 'product' as const, label: 'Product Showcase', icon: 'ri-product-hunt-line' }
  ];

  const filteredVideos = activeCategory === 'all' 
    ? videos 
    : videos.filter(video => video.category === activeCategory);
  
  const totalPages = Math.ceil(filteredVideos.length / videosPerPage);
  const startIndex = (currentPage - 1) * videosPerPage;
  const currentVideos = filteredVideos.slice(startIndex, startIndex + videosPerPage);

  const handleCategoryChange = (category: 'all' | 'company' | 'media' | 'product') => {
    setActiveCategory(category);
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const openVideo = (youtubeUrl: string) => {
    window.open(youtubeUrl, '_blank');
  };

  const getCategoryLabel = (category: Video['category']) => {
    switch (category) {
      case 'company': return 'Company Introduction';
      case 'media': return 'Media Coverage';
      case 'product': return 'Product Showcase';
      default: return category;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            MarinebioGroup Video Gallery
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Explore our comprehensive video collection showcasing company insights, media coverage, and innovative products
          </p>
        </div>

        {/* Category Tabs */}
        <div className="flex flex-wrap justify-center mb-8 bg-white rounded-lg shadow-sm p-2">
          {categories.map((category) => (
            <button
              key={category.key}
              onClick={() => handleCategoryChange(category.key)}
              className={`flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all whitespace-nowrap cursor-pointer ${
                activeCategory === category.key
                  ? 'bg-blue-600 text-white shadow-md'
                  : 'text-gray-600 hover:text-blue-600 hover:bg-blue-50'
              }`}
            >
              <i className={`${category.icon} text-lg`}></i>
              <span>{category.label}</span>
            </button>
          ))}
        </div>

        {/* Video Grid */}
        {currentVideos.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mb-12">
            {currentVideos.map((video) => (
              <div
                key={video.id}
                className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow cursor-pointer"
                onClick={() => openVideo(video.youtubeUrl)}
              >
                <div className="relative">
                  <img
                    src={video.thumbnail}
                    alt={video.title}
                    className="w-full h-48 object-cover"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.src = 'https://readdy.ai/api/search-image?query=video%20placeholder%20with%20play%20button&width=320&height=180&seq=default&orientation=landscape';
                    }}
                  />
                  <div className="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-20 transition-all flex items-center justify-center">
                    <div className="w-16 h-16 bg-red-600 rounded-full flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity">
                      <i className="ri-play-fill text-white text-2xl ml-1"></i>
                    </div>
                  </div>
                  <div className="absolute top-2 right-2">
                    <span className="text-xs bg-blue-600 text-white px-2 py-1 rounded">
                      {getCategoryLabel(video.category)}
                    </span>
                  </div>
                </div>
                <div className="p-4">
                  <h3 className="font-semibold text-gray-900 mb-2 line-clamp-2">
                    {video.title}
                  </h3>
                  <p className="text-gray-600 text-sm line-clamp-3">
                    {video.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <i className="ri-video-line text-6xl text-gray-300 mb-4"></i>
            <h3 className="text-xl font-medium text-gray-500 mb-2">No videos found</h3>
            <p className="text-gray-400">No videos available in this category.</p>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex justify-center items-center space-x-2">
            <button
              onClick={() => handlePageChange(currentPage - 1)}
              disabled={currentPage === 1}
              className={`px-4 py-2 rounded-lg font-medium transition-colors whitespace-nowrap cursor-pointer ${
                currentPage === 1
                  ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                  : 'bg-white text-gray-700 hover:bg-blue-50 hover:text-blue-600 shadow-sm'
              }`}
            >
              <i className="ri-arrow-left-line mr-1"></i>
              Previous
            </button>

            <div className="flex space-x-1">
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                <button
                  key={page}
                  onClick={() => handlePageChange(page)}
                  className={`w-10 h-10 rounded-lg font-medium transition-colors cursor-pointer ${
                    currentPage === page
                      ? 'bg-blue-600 text-white'
                      : 'bg-white text-gray-700 hover:bg-blue-50 hover:text-blue-600 shadow-sm'
                  }`}
                >
                  {page}
                </button>
              ))}
            </div>

            <button
              onClick={() => handlePageChange(currentPage + 1)}
              disabled={currentPage === totalPages}
              className={`px-4 py-2 rounded-lg font-medium transition-colors whitespace-nowrap cursor-pointer ${
                currentPage === totalPages
                  ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                  : 'bg-white text-gray-700 hover:bg-blue-50 hover:text-blue-600 shadow-sm'
              }`}
            >
              Next
              <i className="ri-arrow-right-line ml-1"></i>
            </button>
          </div>
        )}

        {/* Video Count Info */}
        {filteredVideos.length > 0 && (
          <div className="text-center mt-8 text-gray-600">
            Showing {startIndex + 1}-{Math.min(startIndex + videosPerPage, filteredVideos.length)} of {filteredVideos.length} videos
          </div>
        )}
      </div>
    </div>
  );
}
