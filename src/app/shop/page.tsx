import { createClient } from '@supabase/supabase-js'
import { Storefront } from '@/components/web/sections/Storefront'
import type { Product } from '@/lib/web/types'

function webClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  )
}

export default async function ShopPage() {
  const sb = webClient()

  // Get site
  const { data: site } = await sb
    .schema('web')
    .from('sites')
    .select('*')
    .eq('slug', 'marinebiogroup')
    .single()

  if (!site) {
    return <div className="p-8 text-center">Site not found</div>
  }

  // Get products
  const { data: products } = await sb
    .schema('web')
    .from('products')
    .select('*')
    .eq('site_id', site.id)
    .eq('status', 'active')

  // Get images for each product
  const productList = (products || []) as Product[]
  for (const product of productList) {
    const { data: images } = await sb
      .schema('web')
      .from('product_images')
      .select('*')
      .eq('product_id', product.id)
      .order('sort_order', { ascending: true })
    product.images = images as any
    product.image = images?.[0]?.url || null
  }

  const section = {
    id: 'shop-storefront',
    type: 'storefront',
    config: { title: 'Our Products', show_categories: true },
  }

  return (
    <Storefront
      section={section as any}
      site={site as any}
      products={productList}
    />
  )
}