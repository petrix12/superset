SELECT p.precio_vendedor - ap.total_adquisicion as "Plusvalía latentes"
FROM activo_participado ap, propiedad p 
WHERE p.id = ap.activo_id AND ap.publicado = 1;