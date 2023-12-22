-- Paso 1) Obtener todos los apuntes contables y tipos
SELECT
    ac.fecha_creacion AS Fecha,
    COUNT(*) AS "Cantidad de retiros"
FROM apunte_contables ac 
LEFT JOIN tipos_apunte_contables tac ON ac.tipo_id = tac.id
WHERE ac.tipo_id = 65
GROUP BY Fecha
ORDER BY Fecha;