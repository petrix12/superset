-- Total participado
SELECT SUM(`SUM(participaciones_circulacion * valor_participacion)`) AS pasivo
FROM (
    SELECT SUM(participaciones_circulacion * valor_participacion)
    FROM commutatio.activo_participado
) AS virtual_table;

-- Importe estimado participes
SELECT 
    -- CONCAT(FORMAT(SUM(total_para_participes), 2, 'de_DE'), ' €') AS "Total para participes"
    SUM(total_para_participes) AS "Total para participes"
FROM (
    SELECT ap.importe_estimado_participes AS total_para_participes
    FROM activo_participado ap
    JOIN propiedad p ON ap.activo_id = p.id
) AS virtual_table;

-- Coste del capital: Total para los partícipes / Pasivo (10 €)
-- Nota: Suma Importe estimado participes / Total participado
SELECT
    (SELECT SUM(total_para_participes) FROM (
        SELECT ap.importe_estimado_participes AS total_para_participes
        FROM activo_participado ap
        JOIN propiedad p ON ap.activo_id = p.id
    ) AS virtual_table) AS "Total para participes",
    (SELECT SUM(`SUM(participaciones_circulacion * valor_participacion)`) FROM (
        SELECT SUM(participaciones_circulacion * valor_participacion)
        FROM commutatio.activo_participado
    ) AS virtual_table) AS pasivo,
    (SELECT SUM(total_para_participes) FROM (
        SELECT ap.importe_estimado_participes AS total_para_participes
        FROM activo_participado ap
        JOIN propiedad p ON ap.activo_id = p.id
    ) AS virtual_table) / (SELECT SUM(`SUM(participaciones_circulacion * valor_participacion)`) FROM (
        SELECT SUM(participaciones_circulacion * valor_participacion)
        FROM commutatio.activo_participado
    ) AS virtual_table) AS FORMAT("Relación Total para participes / pasivo", 2, 'de_DE');