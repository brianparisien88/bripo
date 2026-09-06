-- Wishlist — materials/fixtures shopping list, imported from the owner's
-- "House Wishlist" Google Sheet ("Shopping List" tab), snapshot 2026-09-05.
-- Same RLS shape as every other table: members read, owner writes.

create table wishlist_items (
  id         uuid primary key default gen_random_uuid(),
  seq        int not null,          -- import order; owner-editable via drag/renumber later if needed
  label      text not null,
  category   text,
  info       text,                  -- "Additional Information" in the sheet
  price      numeric,               -- "Price / Budget"
  link       text,                  -- "Link / Vendor" — URL(s) or a vendor/product name, free text
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table wishlist_items enable row level security;
create policy wishlist_items_member_read on wishlist_items for select using (public.is_member());
create policy wishlist_items_owner_write on wishlist_items for all using (public.is_owner()) with check (public.is_owner());

insert into wishlist_items (seq, label, category, info, price, link, notes) values
  (1, 'Countertop', 'Kitchen', 'Matte Black Sintered', null, null, 'TBD'),
  (2, 'Backsplash', 'Kitchen', 'Milano Cacao', null, 'https://ceramika.shop/collections/small-tiles/products/milano70-cacao-4x31-cm', null),
  (3, 'Cabinets', 'Kitchen', 'Pelicano Wenge', null, null, 'FD Center'),
  (4, 'Island countertop and facade', 'Kitchen', 'Rosso Levanto (red stone)', null, 'https://drive.google.com/file/d/1dt3ij_SKlR-pg3nPR-tFVM0_XSSau56M/view', null),
  (5, 'Floors', 'Kitchen', 'Concrete finish look', null, 'https://mosagres.store/products/cemento-everest-gris-59-3x119', null),
  (6, 'Kitchen/Living divider shelf', 'Kitchen', 'Pelicano Wenge', null, null, 'FD Center'),
  (7, 'Kitchen sink facet', 'Kitchen', null, null, 'https://idco.com.pa/collections/griferias/products/grifo-p-fregador-d-acero-inoxidable-47-7-25-1-11-4cm-2', null),
  (8, 'Kitchen sink', 'Kitchen', 'Confirm size with Jose
Matte black or gun metal', null, null, null),
  (9, 'TV wall console', 'Living Room', 'Pelicano Wenge', null, null, 'FD Center'),
  (10, 'TV wall lighting', 'Living Room', null, null, null, null),
  (11, 'Office cabinets', 'Office', 'Pelicano Wenge', null, null, 'FD Center'),
  (12, 'Walk-in closet', 'Bedroom', 'TBD', null, null, null),
  (13, 'Bedroom sconce (either side of bed)', 'Bedroom', null, null, null, null),
  (14, 'Bedroom overhead lighting', 'Bedroom', null, null, null, 'Use exisitng weaved baskets?'),
  (15, 'Toilet paper and bowl cleaner storage', 'Bathroom', null, null, 'https://www.amazon.com/Bernkot-Recessed-Bathroom-Remodeling-Stainless/dp/B0F18M166C/ref=sr_1_10?crid=LMY2ORM1I92H&dib=eyJ2IjoiMSJ9.EDd3uMqEXChqGVN4L3MwOlOz3Kr8AsTQAPwWYcl717S_hqh9ELG93_YWVXsdzXk4kbpLwMWcpV13d3ck9yi4bES8D_j7hxM5sXhN-vrB5xGy695u-TPSQGFQR1E2l346y5TWCK3X8vHxo2HCcDpmkFiEzmQC7PI2hLJsRnRwuuaB6pl_YF9Wz0YF5XXL3eP-qTG2A7wfTBsVBbWMUUiDyuBr2eM39Zw90aSOZNt-Qk2turu02bAGkgLyuuL7s66bLQvxg2ZXKn5z6CpM-kjh-7HtmvNeydP6jZfl2pa9-Yg.uNFkev1PKAOxD7WxoSjlM7UAYzyy1b6mpllRxa0yT8w&dib_tag=se&keywords=hidden%2Bbathroom%2Bniche%2Bfor%2Bbathroom%2Btrash&qid=1776344567&sprefix=hidden%2Bbathroom%2Bniche%2Bfor%2Bbathroom%2Btrash%2Caps%2C151&sr=8-10&th=1', null),
  (16, 'Bathroom wall #1, floor and sink
Catalog PDF
Kaledonia (Sintered)', 'Bathroom', 'Kaledonia (Sintered)', null, 'https://drive.google.com/file/d/1dt3ij_SKlR-pg3nPR-tFVM0_XSSau56M/view?usp=sharing', null),
  (17, 'Bathroom wall #2', 'Bathroom', 'Milano Cacao', null, 'https://ceramika.shop/collections/small-tiles/products/milano70-cacao-4x31-cm', null),
  (18, 'Bathroom floors', 'Bathroom', 'Kaledonia (Sintered)', null, 'https://drive.google.com/file/d/1dt3ij_SKlR-pg3nPR-tFVM0_XSSau56M/view?usp=sharing', 'Mosiac/tiled so we can grout in to add anti-slip'),
  (19, 'In Wall Toilet Paper Niche w/Shelf', 'Bathroom', null, null, 'https://www.amazon.com/Bernkot-Recessed-Bathroom-Remodeling-Stainless/dp/B0F18M166C/ref=sr_1_10?crid=LMY2ORM1I92H&dib=eyJ2IjoiMSJ9.EDd3uMqEXChqGVN4L3MwOlOz3Kr8AsTQAPwWYcl717S_hqh9ELG93_YWVXsdzXk4kbpLwMWcpV13d3ck9yi4bES8D_j7hxM5sXhN-vrB5xGy695u-TPSQGFQR1E2l346y5TWCK3X8vHxo2HCcDpmkFiEzmQC7PI2hLJsRnRwuuaB6pl_YF9Wz0YF5XXL3eP-qTG2A7wfTBsVBbWMUUiDyuBr2eM39Zw90aSOZNt-Qk2turu02bAGkgLyuuL7s66bLQvxg2ZXKn5z6CpM-kjh-7HtmvNeydP6jZfl2pa9-Yg.uNFkev1PKAOxD7WxoSjlM7UAYzyy1b6mpllRxa0yT8w&dib_tag=se&keywords=hidden%2Bbathroom%2Bniche%2Bfor%2Bbathroom%2Btrash&qid=1776344567&sprefix=hidden%2Bbathroom%2Bniche%2Bfor%2Bbathroom%2Btrash%2Caps%2C151&sr=8-10&th=1', null),
  (20, 'Linear shower channel grates', 'Bathroom', 'Bronze color', null, null, null),
  (21, 'Bathroom toilet', 'Bathroom', 'Wall hung VS electric
Goal is to have a small footprint that looks tankless', null, 'https://sirenahomestore.com/products/inodoro-inteligente-de-piso-con-bidet-secado-y-control-remoto-700x400x465mm-s-trap-300mm-963e-wc?_pos=10&_fid=5a66aaf3a&_ss=c

https://sirenahomestore.com/collections/inodoros-inteligentes?sort_by=created-descending&filter.v.availability=1&filter.v.price.gte=&filter.v.price.lte=', 'Wall hung - $600-800 ballpark - let''s wait to hear back from Joe and Dad on how much their budget is for this and what model/materials they are recommending, then we can work from there to upgrade their options OR consider the smart/electrical toilet route if their quote is too expensive or we need to trim our budget for other things.

Smart/electric toilets - clean lines, looks like a wall hung but cheaper and easier install'),
  (22, 'Bathroom vanity mirror closet', 'Bathroom', 'Need to discuss with Jose and get it included', null, 'https://www.instagram.com/reel/Dam6dquSWLt/?igsh=cjg5emhjd2FmOGw0', 'Need to find a mirror that will work with this.
Do we need cabinet material for this and Blum hinges?'),
  (23, 'Bathroom Shower Facet set', 'Bathroom', 'Rose Gold', null, 'https://www.aliexpress.us/item/3256807066168879.html?spm=a2g0o.imagesearchproductlist.main.2.1871eGcdeGcdr8&algo_pvid=cf068fa0-554c-4efc-9bda-957b9a776973&algo_exp_id=cf068fa0-554c-4efc-9bda-957b9a776973&pdp_ext_f=%7B%22order%22%3A%229%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21USD%21172.40%2198.17%21%21%21172.40%2198.17%21%40212a6dc917852409282664425e0e1e%2112000039954475349%21sea%21US%21725684574%21ACX%211%210%21n_tag%3A-29919%3Bd%3Ae17bb5ff%3Bm03_new_user%3A-29894%3BpisId%3A5000000210913316&curPageLogUid=PjuAp0RF0MdX&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005007252483631%7C_p_origin_prod%3A&gatewayAdapt=4itemAdapt', null),
  (24, 'Ventilation Fan', 'Bathroom', null, null, 'https://www.amazon.com/Akicon-Bathroom-Exhaust-Dimmable-Nightlight/dp/B0F6CYHXL3/ref=pd_aw_subss_hxwPER_sspa_mw_detail_m_sccl_1_3/146-0878760-0735809?pd_rd_r=aed3565f-fdc1-4d7d-892c-da2b5e5c1c2b&pd_rd_wg=AHIxj&pd_rd_w=28GeZ&pd_rd_i=B0F6CYHXL3&psc=1&sp_csd=d2lkZ2V0TmFtZT1zcF9waG9uZV9kZXRhaWxfdGhlbWF0aWM=

https://es.aliexpress.com/item/1005006947399364.html?spm=a2g0o.productlist.main.35.17754baajMhNcm&algo_pvid=99734887-1a71-47fa-92a7-1677d544cf8e&algo_exp_id=99734887-1a71-47fa-92a7-1677d544cf8e-34&pdp_ext_f=%7B%22order%22%3A%2296%22%2C%22spu_best_type%22%3A%22price%22%2C%22eval%22%3A%221%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2129.99%2117.99%21%21%2129.99%2117.99%21%4021413b0b17852402424996834e0e7c%2112000057398491719%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=ZZpNQIOYjrtD&utparam-url=scene%3Asearch%7Cquery_from%3A%7Cx_object_id%3A1005006947399364%7C_p_origin_prod%3A', null),
  (25, 'Ben Moore Paints
wall - Lacey Pearl
ceiling - Silver Fox
bedroom/hallway wall - Wenge', 'Paint', null, null, null, null),
  (26, 'Exterior door hinges: Confirm the finish with the Windows guy.', 'Doors - Entry', 'Bronze color', null, null, 'Discuss with windows'),
  (27, 'Main entry door - deadbolt/smart lock', 'Doors - Entry', null, null, 'https://carbonestore.com/products/cerradura-inteligente-perilla-de-puerta-cerrojo-smart-lock-5-en-1-llave-huella-contrasena-bluetooth-tuya-app-facil-de-instalar', null),
  (28, 'Interior door hinges: Since we are using an invisible door style, confirm with Joe', 'Doors - Interior', 'Bronze color or black finish
Mainly good quality', null, null, null),
  (29, 'Interior door handle and keyhole', 'Doors - Interior', 'Bronze or matte black/gun metal; color TBD', null, 'https://es.aliexpress.com/item/1005005548539236.html?spm=a2g0o.imagesearchproductlist.main.1.2cf13CY23CY202&algo_pvid=a6789043-5aa0-42bc-b093-de6a9cb30739&algo_exp_id=a6789043-5aa0-42bc-b093-de6a9cb30739&pdp_ext_f=%7B%22order%22%3A%2224%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2167.47%2151.95%21%21%2167.47%2151.95%21%402103835c17836386371712730e267f%2112000056008690970%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=waVS3WTREVBv&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005005548539236%7C_p_origin_prod%3A', null),
  (30, 'Interior door - laundry handle', 'Doors - Interior', null, null, 'https://es.aliexpress.com/item/1005011689508107.html?spm=a2g0o.imagesearchproductlist.main.1.23998ail8ailUT&algo_pvid=03e95202-a70a-431f-864a-47b27bbb180a&algo_exp_id=03e95202-a70a-431f-864a-47b27bbb180a&pdp_ext_f=%7B%22order%22%3A%2245%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2114.11%218.79%21%21%2114.11%218.79%21%402103890917836422702434112e8501%2112000056255112328%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=QRl8kxx3P7GS&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005011689508107%7C_p_origin_prod%3A', null),
  (31, 'Interior door - alternative door handles', 'Doors - Interior', null, null, 'https://es.aliexpress.com/item/1005012658047429.html?spm=a2g0o.imagesearchproductlist.main.1.3c9bh8nWh8nW1u&algo_pvid=98bce947-c560-4852-b4fe-2b783948b524&algo_exp_id=98bce947-c560-4852-b4fe-2b783948b524&pdp_ext_f=%7B%22order%22%3A%22-1%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2167.52%2137.14%21%21%21456.84%21251.26%21%400b884a9917836421355497789e0ee6%2112000058976125706%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=ZWlc6P25cqp5&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005012658047429%7C_p_origin_prod%3A

https://es.aliexpress.com/item/1005005796372223.html?spm=a2g0o.imagesearchproductlist.main.6.44bfnv1Fnv1FGE&algo_pvid=94ea5635-0e8a-4268-9a65-eb885bafe8e0&algo_exp_id=94ea5635-0e8a-4268-9a65-eb885bafe8e0&pdp_ext_f=%7B%22order%22%3A%226%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2150.55%2142.87%21%21%21342.00%21290.02%21%40210381f017836421834814308e10a8%2112000034385139192%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895%3BpisId%3A5000000204863185&curPageLogUid=XU4BTVknev0i&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005005796372223%7C_p_origin_prod%3A', null),
  (32, 'Laundry door - 2-panel foldable door hardware', 'Doors - Interior', null, null, 'https://www.amazon.com/CCJH-Hardware-Doorframe-Mounting-Invisible/dp/B0GFCQ8YYL/ref=sr_1_2?crid=1FTR2VJTOYP3&dib=eyJ2IjoiMSJ9.P8IVeOnvtdCuuw3ZJfMtmGIZiFFWyv24exYkNfJV8KrVJMtEA98kYueNhR2SYUZJhE-WdZbWnnr7ICn-QB-ZSZPddVFWUyPd_nrBR_3wZAFgUQyrTn7U78hva3yTZiVBELJjG7XQ9AeN0Yc1fZWRyJfM2ibSSuJK_4TA7dFZm16BvAdavnDmy1mtaWAWB9GCegRIeFXEOviYRZdZB-xg7mmLFiQvXH_5fLrulA8FcjI9JELxJgQ822AT-76Ec0jQ6niBsT5jal788UN4hHNE_zFhxQ2wl1Tsa2llilKSIrA.a_kESMPMuSHI4Nivgsd90b7f5pJqYcFr20aCCDUD900&dib_tag=se&keywords=180%2Bdegree%2Bfolding%2Bflat%2Bdoor%2Bhardware&qid=1773967839&sprefix=180%2Bdegree%2Bfolding%2Bflat%2Bdoor%2Bhardware%2Caps%2C352&sr=8-2&th=1', null),
  (33, 'Interior invisible doors system', 'Doors - Interior', null, null, 'https://www.amazon.com/Polar-Tangro-Invisible-Hinges-Concealed/dp/B0CKXJM32M?th=1

https://www.amazon.com/-/es/Woodhaven-Plantilla-instalaci%C3%B3n-invisible-herramienta/dp/B0DVTHY546?th=1

https://www.amazon.com/Whiteside-Router-Bits-RU2100-Standard/dp/B000K2BGNS/ref=sr_1_1?c=ts&dib=eyJ2IjoiMSJ9.4dhjMqRWJtLpPjW-mh37dtChjyH5Py9-FY0gGeQzSJ4XTXBc8ufKht1yubdmvr5E-6LISqhoa79zioIAwn2E38hwnynEqvCMU4shfRHio7xXgJIiX-75hN5VoOjzJ4k62z8tqWVYPr1WgzN0itVu5YtJBLRSV4ukJDhkFK2xcMVjQdat6P202xQDGYUOIDN7NrcghInwQHMzu3lGQW6zP8K9qeKGSedNcud1V55iaA0FhEYmpu913In1CzNYa-PLrxS3pPvjU8Uxqzu-Bm9cL2TDIRrPQvRruAcMzlVjkQE.ZT3HGyf0bFhHoH6p5RWiAYCJJgnWkPatqoGqd41en5E&dib_tag=se&keywords=Router+Bits&qid=1773235630&refinements=p_89%3AWhiteside&s=power-hand-tools&sr=1-1&ts_id=3116511', '4 pack hinges for invisible door hardware (need maybe 3 packs) 

Template for doors

Router drill bit

Hinges (10 total)5$160.00
Magnetic Latches3$95.00
Router 
Template1$68.00
Router Bits2$50.00
TOTAL~$373.00'),
  (34, 'Cabinet door hinges in the kitchen and entry way mud/bench area', 'Cabinets', 'Good quality and soft close for everything', null, 'https://www.blum.com/gb/en/products/hingesystems/hinges-onyx/overview/', 'Blum brand from FD center'),
  (35, 'Cabinet shadow gaps', 'Cabinets', 'Black color', null, null, null),
  (36, 'Cabinet pull drawer shadow gap: recessed grip bars', 'Cabinets', 'black color', null, null, null),
  (37, 'Cabinet handles for the invisible fridge', 'Cabinets', 'TBD', null, null, null),
  (38, 'Cabinet pull out organizer', 'Cabinets', 'Need to find smaller one for the thin pullout cabinet in the lowers between the stove and sink', null, 'https://multilaminaspanama.com/products/alacena-columna-201186-6c-400mm', null),
  (39, 'Pullout garbage system', 'Cabinets', null, null, 'https://www.amazon.com/Cabinet-Garbage-Soft-Close-Mounting-Cabinets/dp/B0DL925K2V/ref=sr_1_40?crid=1RRERMLGSQX3M&dib=eyJ2IjoiMSJ9.Xugvyo37yyEj8HeBBRkDfy-skv3aMYNg00yif-Kg4k7-vrAx1IAMJN_B9og-BSdrnXcxFbxrvxVeGXJc1vJHFhf60IaUNlyOKd_g0T5KBN00m6xDpRsMkUCAZWjCXxkxjQ4wJ-gC-kYIVoUSJOVDvD2JVIR1sYgkDxOjcBkIa1RjrTb5RjS3TuffkEKvNmm7tb80ja5nuMe8Wg6uP5RPlaOZU27sF9rq1XN2sMnuGnVTRqjcq6PAFrdBEBvNUxzLWaPlaIoLxpzNK7TaTnhV4NS266rEWzUkydWCYCUf5vU.t0QBIhKNOHiIWBgAy0y3M49dC3wNAqPD9UcH26XW6-k&dib_tag=se&keywords=hidden%2Bkitchen%2Btrash%2Bcan%2Bhardware&qid=1776343737&sprefix=hidden%2Bkitchen%2Btrash%2Bcan%2Bhardwar%2Caps%2C185&sr=8-40&th=1', null),
  (40, 'Pullout coffee station', 'Cabinets', null, null, 'https://www.instagram.com/reel/DW3ebEKDZRy/?igsh=MWl0Njh3a3lxZTF3ZQ%3D%3D', null),
  (41, 'Electrical plate style (floor, wall, underneath middle cabinets)', 'Electrical', 'Color TBD, screwless faceplate design', null, 'https://www.amazon.com/LIDER-Unbreakable-Polycarbonate-Thermoplastic-LSWP-31M-BGD/dp/B0BHN8S27R/ref=sr_1_8?crid=1YOZ2W6Y4010Q&dib=eyJ2IjoiMSJ9.0H3SvVDvZcu_si8BaQkGxwwlTmDyrM57UypabrgVXuAHne2NY3gC14xwCDwAjWq7mg0Qo-lMMxXlbIyfPNPhb8CyZf3FHBO-X7431JwhEkA356UE_W7YKxRbSArJyhkaSXHrR8SDriOBftMM70AndWY5Q8JCQNTPz-jGx6p8aw1KqYd897PlTz6h_QyT9XG_ddxYDrr9VyP8MwFy5Az0onbWLWLcc3iV8ZwTBP3D4QGL-LvDSRVfrrIioBnPXvPlRymcT3y1iMeeY3NeSv-IRuBRnl92uYc_YAJ-qJZsTZI.0oHPbcwVQo-FBft0Xp0b-7RvL1NwqGyGzP63pInIPAw&dib_tag=se&keywords=bronze%2Bbrass%2Bswitch%2Bplates&qid=1783632860&sprefix=bronze%2Bbrass%2Bswitch%2Bplates%2Caps%2C190&sr=8-8&th=1#averageCustomerReviewsAnchor', null),
  (42, 'Electrical - other faceplate/switch options', 'Electrical', null, null, 'https://es.aliexpress.com/item/1005001526489716.html?spm=a2g0o.imagesearchproductlist.main.3.7e34avLoavLof3&algo_pvid=fafa2037-a382-462a-82d9-7e58dc3ef0a1&algo_exp_id=fafa2037-a382-462a-82d9-7e58dc3ef0a1&pdp_ext_f=%7B%22order%22%3A%221492%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2112.20%217.71%21%21%2112.20%217.71%21%4021613be817837920094293589e0f25%2112000016471658570%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895%3BpisId%3A5000000210789359&curPageLogUid=ybkTEanDHZkQ&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005001526489716%7C_p_origin_prod%3A

https://es.aliexpress.com/item/1005012216729948.html?spm=a2g0o.imagesearchproductlist.main.1.1031Hp3IHp3Io1&algo_pvid=e9f7eaf0-e8a0-4648-93e8-1a290d3f9c3d&algo_exp_id=e9f7eaf0-e8a0-4648-93e8-1a290d3f9c3d&pdp_ext_f=%7B%22order%22%3A%22-1%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%219.13%217.30%21%21%2161.60%2149.28%21%400b88489417837921149764353e0f21%2112000057803286627%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=w4TYWK4RUeaj&utparam-url=scene%3Aimage_search%7Cquery_from%3Apc_web_image_search%7Cx_object_id%3A1005012216729948%7C_p_origin_prod%3A

https://es.aliexpress.com/item/1005006856205469.html?spm=a2g0o.productlist.main.8.32fc4t6n4t6nbc&aem_p4p_detail=2026071110510616549611575057550007509231&algo_pvid=42302046-b6be-42f9-94b2-c6f6c90a4f4d&algo_exp_id=42302046-b6be-42f9-94b2-c6f6c90a4f4d-7&pdp_ext_f=%7B%22order%22%3A%2240%22%2C%22eval%22%3A%221%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2110.41%218.02%21%21%2170.27%2154.11%21%4021039a5b17837922666645927eb582%2112000038527624216%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895&curPageLogUid=zI5IQaSL63Rk&utparam-url=scene%3Asearch%7Cquery_from%3A%7Cx_object_id%3A1005006856205469%7C_p_origin_prod%3A&search_p4p_id=2026071110510616549611575057550007509231_2', null),
  (43, 'Social area concrete
Prevent algea or mold growth', 'Outdoor Social Area', null, null, null, 'SikaCem-102 First Seal or Rust-Oleum Concrete Moisture Stop.prevents algea or mold growth'),
  (44, 'Volcanic basalt stone - driveway and under the house', 'Driveway', 'We want the stones to be as dark as possible', null, 'https://www.panablock.com/products/mat-piedra4-20yd

https://www.preval.com.pa/en/la-cantera-de-la-valdeza#', 'Integrated Eco-Grid under stilts and basalt  stones on top.... and around social are or epoxy resin

For driveway, can we do gravel mixed with pavers, both basalt-based.

For the Quarries, ask them if they have "Piedra Boleada" or cut basalt blocks. Often, industrial quarries have "oversize" basalt blocks that can be used as heavy-duty pavers for a fraction of the price of imported stone'),
  (45, 'Fridge', 'Kitchen', null, null, 'https://www.panafoto.com/sbs-nofrost-15-6-cu-ft-silver-inverter-65292-115v-60hz.html', null),
  (46, 'Stove extractor', 'Kitchen', null, null, 'https://drijainternational.com/producto/retractil-touch-76/', null),
  (47, 'Slider Kits', 'Invisible Fridge System', 'These are the "Drag Hinges." Buy 2 packs (they usually come in 2 or 4-packs). Brands like Paxanpax, Spares2go, or UPTTHOW are the standard.', null, 'Universal Integrated Fridge Door Slider Kit', 'Fridge - how to make standard fridge invisible behind standard cabinet doors
https://www.youtube.com/watch?v=nkaaa8IyY6Y - how to video on install and example
Parts table below, we can order from Amazon
Should cost $100 for the parts at the most'),
  (48, 'Outer Hinges', 'Invisible Fridge System', 'These attach the wood to the cabinet box. "Non-mortise" means Joe doesn''t have to carve out the wood—they screw onto the surface.', null, 'Non-Mortise Door Hinge 3.5 inch Black', null),
  (49, 'Tape', 'Invisible Fridge System', 'This is the ONLY tape that will hold the slider to the fridge door without screws. If you use cheap double-sided tape, the panel will fall off in a week.', null, '3M VHB 5952 Heavy Duty Mounting Tape', null),
  (50, 'Ceiling curtain rods recessed into ceiling', 'Curtain System', null, null, 'https://www.doitcenter.com.pa/productos/riel-haupta-de-aluminio-250-cm-inspire-cortineros-92041670-15ad1670

https://pin.it/42X6VIq59

https://carbonestore.com/products/riel-para-cortinas-autoadhesivo-para-techo-deslizamiento-suave-color-negro-se-vende-por-metro-piezas-se-pueden-unir-para-tramos-largos', null),
  (51, 'Shadow gap/floor board (mainly for hallway)', 'Wall', 'Floor board', null, 'https://hopsa.com/products/perfil-vinil-z-shadow-1-2-x-1-2-x-10p-as5510-trimtex?srsltid=AfmBOopCXl78i72A98LjzbufFDhMGoj67FNYs2cBbR8kjP9nvSpqVCTV

https://www.cochezycia.com/perfil-para-borde-acabado-negro-k051-000207', null),
  (52, 'Small LED Hallway lights (sensor activated)', 'Hallway', 'For hallway and bathroom', null, 'https://es.aliexpress.com/item/1005006153796186.html?invitationCode=VDVGY2l2WTB1cFNTZU5Tc2VzZFJCK0orWXdBRUxYSlRYSTBKT3A4S0VMd2pmdlBzNkVmWTlBPT0&srcSns=sns_Copy&spreadType=socialShare&social_params=22129305731&bizType=ProductDetail&spreadCode=VDVGY2l2WTB1cFNTZU5Tc2VzZFJCK0orWXdBRUxYSlRYSTBKT3A4S0VMd2pmdlBzNkVmWTlBPT0&aff_fcid=5fcb07a59bae420db977fc8ef0919f0e-1783791349057-01571-_m0tSv6T&tt=MG&aff_fsk=_m0tSv6T&aff_platform=default&sk=_m0tSv6T&aff_trace_key=5fcb07a59bae420db977fc8ef0919f0e-1783791349057-01571-_m0tSv6T&shareId=22129305731&businessType=ProductDetail&platform=AE&terminal_id=140994c5e9be475b918c5e66e51d6ce9&afSmartRedirect=y&gatewayAdapt=4itemAdapt', null),
  (53, 'Wood grain paint kit', null, null, null, 'https://es.aliexpress.com/item/1005005008505454.html?spm=a2g0o.productlist.main.13.1f3bNDKxNDKxhb&utparam-url=scene%3Asearch%7Cquery_from%3Apc_back_same_best%7Cx_object_id%3A1005005008505454%7C_p_origin_prod%3A&algo_pvid=c61a9e00-ffdc-4eae-9d5d-575baf1d5384&algo_exp_id=c61a9e00-ffdc-4eae-9d5d-575baf1d5384&pdp_ext_f=%7B%22order%22%3A%22509%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21PAB%2114.48%217.14%21%21%2114.48%217.14%21%402101c28d17852404145468735e0fdf%2112000033358245659%21sea%21PA%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3A4e87b6f%3Bm03_new_user%3A-29895%3BpisId%3A5000000212673780', null),
  (54, 'Privacy trees', 'Landscaping', 'Clumping Bamboo (Bambusa multiplex / "Seabreeze")
If you want sharp lines and verticality without messy lower fronds, clumping bamboo provides a striking, modern Japanese/architectural screen.', null, null, null),
  (55, 'Basalt rocks/gravel', null, null, null, 'https://canteralamona.com/', null),
  (56, 'Outdoor sintered stone', 'Outdoor Social Area', null, null, 'https://www.facebook.com/marketplace/item/1771212660558233/?ref=browse_tab&referral_code=marketplace_general&referral_story_type=general_listing&tracking=%7B%22qid%22%3A%22-6324949498456320898%22%2C%22mf_story_key%22%3A%225518031235496742773%22%2C%22top_level_post_id%22%3A%225518031235496742773%22%2C%22commerce_rank_obj%22%3A%22%7B%5C%22target_id%5C%22%3A5518031235496742773%2C%5C%22target_type%5C%22%3A6%2C%5C%22primary_position%5C%22%3A3%2C%5C%22ranking_signature%5C%22%3A985248599308676871%2C%5C%22ranking_region%5C%22%3A%5C%22dkl%5C%22%2C%5C%22ranking_request_id%5C%22%3A2786004534451984238%2C%5C%22commerce_channel%5C%22%3A501%2C%5C%22value%5C%22%3A0.00052852751105092%2C%5C%22upsell_type%5C%22%3A129%2C%5C%22candidate_retrieval_source_map%5C%22%3A%7B%5C%2227698215623180258%5C%22%3A805%2C%5C%2227584725274543251%5C%22%3A805%2C%5C%2227924167460578530%5C%22%3A3001%2C%5C%2227742362295427858%5C%22%3A805%2C%5C%2227869457739412642%5C%22%3A3021%2C%5C%2228318075931206970%5C%22%3A805%7D%2C%5C%22candidate_write_path_source_map%5C%22%3A[]%2C%5C%22delivery_flow_path%5C%22%3Anull%2C%5C%22grouping_info%5C%22%3Anull%2C%5C%22is_prefetch%5C%22%3Afalse%2C%5C%22request_fetch_reason%5C%22%3Anull%7D%22%7D', null);
