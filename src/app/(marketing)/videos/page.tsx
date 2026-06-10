'use client';

import Header from '../components/Header';
import Footer from '../components/Footer';
import VideoGallery from '../components/videos/VideoGallery';

export default function Videos() {
  return (
    <div className="min-h-screen bg-white" style={{ fontFamily: '"Noto Sans KR", sans-serif' }}>
      <Header />
      <main className="pt-16">
        <VideoGallery />
      </main>
      <Footer />
    </div>
  );
}
