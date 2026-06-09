-- 0005_seed_product_images.sql
-- Seed product images for shop display

-- Natural Soap
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1600857062241-98e5dba7214f?w=500&q=80', 'Natural soap bar with herbs', 1
FROM web.products WHERE name = 'Natural Soap'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1599599810694-b3d1d65157b7?w=500&q=80', 'Handmade organic soap collection', 2
FROM web.products WHERE name = 'Natural Soap'
ON CONFLICT DO NOTHING;

-- Face Mask
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500&q=80', 'Premium face mask treatment', 1
FROM web.products WHERE name = 'Face Mask'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=500&q=80', 'Skincare face mask application', 2
FROM web.products WHERE name = 'Face Mask'
ON CONFLICT DO NOTHING;

-- Sun Screen
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=500&q=80', 'Marine-based sun protection cream', 1
FROM web.products WHERE name = 'Sun Screen'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1609117282536-c8cd2b92b47d?w=500&q=80', 'Natural sunscreen with ocean ingredients', 2
FROM web.products WHERE name = 'Sun Screen'
ON CONFLICT DO NOTHING;

-- Tone Up
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=500&q=80', 'Skin toning serum bottle', 1
FROM web.products WHERE name = 'Tone Up'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=500&q=80', 'Cosmetic tone-up essence', 2
FROM web.products WHERE name = 'Tone Up'
ON CONFLICT DO NOTHING;

-- Marine-Pad Box
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1614730321146-b6fa6a46bcb4?w=500&q=80', 'Marine-Pad biodegradable packaging', 1
FROM web.products WHERE name = 'Marine-Pad Box'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=500&q=80', 'Sustainable ocean-derived product', 2
FROM web.products WHERE name = 'Marine-Pad Box'
ON CONFLICT DO NOTHING;

-- Paper Filler
INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&q=80', 'Eco-friendly paper filler for packaging', 1
FROM web.products WHERE name = 'Paper Filler'
ON CONFLICT DO NOTHING;

INSERT INTO web.product_images (product_id, url, alt, sort_order)
SELECT id, 'https://images.unsplash.com/photo-1596395592519-bbb982cf58d6?w=500&q=80', 'Sustainable packaging material', 2
FROM web.products WHERE name = 'Paper Filler'
ON CONFLICT DO NOTHING;