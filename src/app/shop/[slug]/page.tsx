import { resolveSiteBySlug, loadProduct } from '@/lib/web/tenant';
import { SiteChrome } from '@/components/web/SiteChrome';

export const dynamic = 'force-dynamic';

export default async function ProductPage({ params }: { params: { slug: string } }) {
  const site = await resolveSiteBySlug('marinebiogroup');
  if (!site) return <div>Site not found</div>;

  const product = await loadProduct(site.id, params.slug);
  if (!product) return <div className="text-center p-8">Product not found</div>;

  return (
    <SiteChrome site={site}>
      <div className="max-w-4xl mx-auto px-6 py-12">
        <div className="grid grid-cols-2 gap-8">
          <div>
            {product.images?.[0] ? (
              <img src={product.images[0].url} alt={product.name} className="w-full rounded-lg" />
            ) : (
              <div className="w-full aspect-square bg-gray-200 rounded-lg flex items-center justify-center">No image</div>
            )}
          </div>
          <div>
            <h1 className="text-3xl font-bold mb-4">{product.name}</h1>
            <div className="text-3xl font-bold mb-6">${product.base_price?.toFixed(2)}</div>
            {product.description && <p className="mb-8">{product.description}</p>}
            <button className="w-full bg-blue-600 text-white py-3 rounded hover:bg-blue-700">Add to Cart</button>
            <a href="/shop" className="block mt-6 text-center text-blue-600">Back to Shop</a>
          </div>
        </div>
      </div>
    </SiteChrome>
  );
}