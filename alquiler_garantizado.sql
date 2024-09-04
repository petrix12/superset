-- Consulta para saber qué propiedades podrán contratar el servicio de alquiler garantizado
SELECT
    -- Candidato
    CASE WHEN 
        -- Condición 1: que tenga contrato
        (i.contrato = 'Si') AND
        -- Condición 2: que no tenga fecha fin de contrato
        (i.fecha_fin_contrato IS NULL) AND
        -- Condición 3: que la fecha del último pago sea menor a 31 días
        (IFNULL(DATEDIFF(CURDATE(), ac.fecha_creacion), 1000) <= 31) AND
        -- Condición 4: que el importe del último pago de alquiler sea ± 3% de la renta mensual
        (IFNULL(ABS(ac.importe), 0) <= IFNULL(i.renta_mensual, 0) * (1.05)) AND
        (IFNULL(ABS(ac.importe), 0) >= IFNULL(i.renta_mensual, 0) * (0.95)) AND
        -- Condición 5: No debe tener un contrato ya vigente de alquiler garantizado, 
        -- salvo que estemos en el mes anterior a su vencimiento 
        (((CURDATE() + INTERVAL 1 MONTH >= ag.fecha_fin) AND (MONTH(ag.fecha_fin) = MONTH(CURDATE()))) OR (ag.fecha_fin IS NULL)) AND
        -- Condición 6: Puede optar a alquiler garantizado
        (p.optar_garantizado = 1)
    THEN 'Si' ELSE 'No' END 'Candidato',
    -- SKU
    m.propiedad_sku 'SKU',
    -- Nombre
    up.name 'Nombre',
    -- Apellidos
    CONCAT_WS(' ', IFNULL(up.apellido1, ''), IFNULL(up.apellido2, '')) 'Apellidos',
    -- Dirección
    CONCAT_WS('', IFNULL(p.calle, ''), ' ', IFNULL(p.numero, ''), ' - ', IFNULL(p.piso, ''), ' ', IFNULL(p.puerta, '')) 'Dirección',
    -- Contrato Alquiler
    IFNULL(i.contrato, 'No') 'Contrato Alquiler',
    -- Fecha fin contrato
    IFNULL(DATE_FORMAT(i.fecha_fin_contrato, '%d-%m-%Y'), '-') 'Fecha fin',
    -- Renta Mensual
    IFNULL(FORMAT(i.renta_mensual, 2), 0) 'Renta mensual (€)',
    -- Último pago
    IFNULL(FORMAT(ABS(ac.importe), 2), 0) 'Último pago (€)',
    -- Fecha de pago
    IFNULL(DATE_FORMAT(ac.fecha_creacion, '%d-%m-%Y'), '-') 'Fecha pago',
    -- Diferencia de días
    IFNULL(DATEDIFF(CURDATE(), ac.fecha_creacion), '-') 'Días',
    -- Optar garantizado
    CASE WHEN 
        p.optar_garantizado = 1
    THEN 'Si' ELSE 'No' END 'Optar garantizado',
    -- Contrato Garantizado
    CASE 
        WHEN ag.estado = 'firmado' THEN 'Si' 
        WHEN ag.estado = 'pendiente' THEN 'En proceso' 
        ELSE 'No' 
    END 'Contrato Garantizado',
    -- Fecha inicio garantizado
    IFNULL(DATE_FORMAT(ag.fecha_inicio, '%d-%m-%Y'), '-') 'Fecha inicio garantizado',
    -- Fecha fin garantizado
    IFNULL(DATE_FORMAT(ag.fecha_fin, '%d-%m-%Y'), '-') 'Fecha fin garantizado',
    -- Tipo garantizado
    IFNULL(ag.tipo, '-') 'Tipo garantizado',
    -- Importe garantizado
    IFNULL(FORMAT(ag.importe, 2), '-') 'Importe garantizado (€)',
    -- Rentabilidad garantizado
    IFNULL(FORMAT(ag.porcentaje, 2), '-') 'Rentabilidad garantizado (%)'
FROM mos m
LEFT JOIN propiedad p ON m.propiedad_sku = p.sku
LEFT JOIN usuarios_publicos up ON p.usuario_publico_id = up.id
LEFT JOIN (
    SELECT 
        *, 
        CASE WHEN i1.fecha_fin_contrato IS NULL THEN 'Si' ELSE 'No' END contrato
    FROM inquilinos i1
    WHERE i1.id = (
        SELECT MAX(i2.id)
        FROM inquilinos i2
        WHERE i2.activo_id = i1.activo_id
    )
) i ON p.id = i.activo_id
LEFT JOIN (
    SELECT
        propiedad_id,
        importe,
        fecha_creacion
    FROM apunte_contables ac1
    WHERE ac1.tipo_id = 25
        AND ac1.id = (
            SELECT MAX(ac2.id)
            FROM apunte_contables ac2
            WHERE ac2.propiedad_id = ac1.propiedad_id AND ac2.tipo_id = 25
        )
) ac ON p.id = ac.propiedad_id
LEFT JOIN (
    SELECT 
        agt.*
    FROM alquiler_garantizados agt
    JOIN (
        SELECT propiedad_id, MAX(id) max_id
        FROM alquiler_garantizados
        GROUP BY propiedad_id
    ) max_ids ON agt.propiedad_id = max_ids.propiedad_id AND agt.id = max_ids.max_id
) ag ON p.id = ag.propiedad_id
WHERE p.activo = 1
ORDER BY p.fecha_escritura DESC;