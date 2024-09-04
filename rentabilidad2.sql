WITH 
    Alquiler AS (
        SELECT
            ac.*,
            ROW_NUMBER() OVER (PARTITION BY ac.propiedad_id, ac.tipo_id ORDER BY ac.fecha_creacion DESC) AS rn
        FROM
            apunte_contables ac
        WHERE
            ac.tipo_id = 25
    ),
    Comunidad AS (
        SELECT
            ac.*,
            ROW_NUMBER() OVER (PARTITION BY ac.propiedad_id, ac.tipo_id ORDER BY ac.fecha_creacion DESC) AS rn
        FROM
            apunte_contables ac
        WHERE
            ac.tipo_id = 26
    ),
    IBI AS (
        SELECT
            ac.*,
            ROW_NUMBER() OVER (PARTITION BY ac.propiedad_id, ac.tipo_id ORDER BY ac.fecha_creacion DESC) AS rn
        FROM
            apunte_contables ac
        WHERE
            ac.tipo_id = 29
    ),
    Seguro AS (
        SELECT
            ac.*,
            ROW_NUMBER() OVER (PARTITION BY ac.propiedad_id, ac.tipo_id ORDER BY ac.fecha_creacion DESC) AS rn
        FROM
            apunte_contables ac
        WHERE
            ac.tipo_id = 30
    )
SELECT
    -- SKU
    m.propiedad_sku SKU,
    -- Nombre
    up.name Nombre,
    -- Apellidos
    CONCAT_WS(' ', IFNULL(up.apellido1, ''), IFNULL(up.apellido2, '')) Apellidos,
    -- Dirección
    CONCAT_WS('', IFNULL(p.calle, ''), ' ', IFNULL(p.numero, ''), ' - ', IFNULL(p.piso, ''), ' ', IFNULL(p.puerta, '')) 'Dirección',
    -- Fecha de escritura
    p.fecha_escritura 'Fecha de escritura',
    -- Días
    DATEDIFF(CURDATE(), p.fecha_escritura) 'Días',
    -- Años
    FORMAT(DATEDIFF(CURDATE(), p.fecha_escritura) / 365.25, 2) 'Años',
    -- RENTABILIDAD
    FORMAT((
        (            
            CASE WHEN ABS(a.importe) > 0 AND COALESCE(p.alquiler_habitaciones, 0) = 0 THEN ABS(a.importe) * 12 ELSE ABS(p.alquiler_estimado) * 12 END -
            CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) * 12 ELSE ABS(p.comunidad) * 12 END -
            CASE WHEN ABS(i.importe) > 0 AND 
            (
                SELECT COUNT(*) AS 'total de asientos' 
                FROM apunte_contables ac 
                WHERE ac.tipo_id = 29 AND p.id = ac.propiedad_id
            ) > 1
            THEN ABS(i.importe) ELSE IFNULL(ABS(p.ibi), 0) END -
            CASE WHEN ABS(s.importe) > 0 THEN ABS(s.importe) ELSE 200 END -
            (ABS(tpc.administracion) * 12)
        ) / 
        (
            CASE WHEN m.pago_propiedad_bool = 'si' THEN IFNULL(m.pago_propiedad, 0) ELSE 0 END +
            CASE WHEN m.honorarios_bool = 'si' THEN IFNULL(m.honorarios, 0) ELSE 0 END +
            CASE WHEN m.provision_fondos_bool = 'si' THEN IFNULL(m.provision_fondos,  0) ELSE 0 END +
            CASE WHEN m.comision_venta_bool = 'si' THEN IFNULL(m.comision_venta, 0) ELSE 0 END +
            CASE WHEN m.otros_conceptos_bool = 'si' THEN IFNULL(m.otros_conceptos, 0) ELSE 0 END +
            CASE WHEN m.reforma_licencia_bool = 'si' THEN IFNULL(m.reforma_licencia, 0) ELSE 0 END
        ) * 100

    ), 2) 'Rentabilidad (%)',
    -- TOTAL MOS
    FORMAT((
        CASE WHEN m.pago_propiedad_bool = 'si' THEN IFNULL(m.pago_propiedad, 0) ELSE 0 END +
        CASE WHEN m.honorarios_bool = 'si' THEN IFNULL(m.honorarios, 0) ELSE 0 END +
        CASE WHEN m.provision_fondos_bool = 'si' THEN IFNULL(m.provision_fondos, 0) ELSE 0 END +
        CASE WHEN m.comision_venta_bool = 'si' THEN IFNULL(m.comision_venta, 0) ELSE 0 END +
        CASE WHEN m.otros_conceptos_bool = 'si' THEN IFNULL(m.otros_conceptos, 0) ELSE 0 END +
        CASE WHEN m.reforma_licencia_bool = 'si' THEN IFNULL(m.reforma_licencia, 0) ELSE 0 END
    ), 2) 'Total inversión (€)',
    -- RETORNO NETO    
    FORMAT((
        CASE WHEN ABS(a.importe) > 0 AND COALESCE(p.alquiler_habitaciones, 0) = 0 THEN ABS(a.importe) * 12 ELSE ABS(p.alquiler_estimado) * 12 END -
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) * 12 ELSE ABS(p.comunidad) * 12 END -
        CASE WHEN ABS(i.importe) > 0 AND 
        (
            SELECT COUNT(*) AS 'total de asientos' 
            FROM apunte_contables ac 
            WHERE ac.tipo_id = 29 AND p.id = ac.propiedad_id
        ) > 1
        THEN ABS(i.importe) ELSE IFNULL(ABS(p.ibi), 0) END -
        CASE WHEN ABS(s.importe) > 0 THEN ABS(s.importe) ELSE 200 END -
        (ABS(tpc.administracion) * 12)
    ), 2) 'Retorno neto (€)',
    -- ALQUILER
    FORMAT((
        /* CASE WHEN ABS(a.importe) > 0 AND NOT NULL p.alquiler_habitaciones THEN ABS(a.importe) ELSE ABS(p.alquiler_estimado) END */
        CASE WHEN ABS(a.importe) > 0 AND COALESCE(p.alquiler_habitaciones, 0) = 0 THEN ABS(a.importe) ELSE ABS(p.alquiler_estimado) END
    ), 2) 'Alquiler mensual (€)',
    -- COMUNIDAD
    FORMAT((
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) ELSE ABS(p.comunidad) END
    ), 2) 'Comunidad mensual (€)',
    -- IBI
    FORMAT((
        /* CASE WHEN ABS(i.importe) > 0 THEN ABS(i.importe) ELSE ABS(p.ibi) END */
        CASE WHEN ABS(i.importe) > 0 AND 
        (
            SELECT COUNT(*) AS 'total de asientos' 
            FROM apunte_contables ac 
            WHERE ac.tipo_id = 29 AND p.id = ac.propiedad_id
        ) > 1
        THEN ABS(i.importe) ELSE IFNULL(ABS(p.ibi), 0) END
    ), 2) 'IBI (€)',
    -- SEGURO
    FORMAT((
        CASE WHEN ABS(s.importe) > 0 THEN ABS(s.importe) ELSE 200 END
    ), 2) 'Seguro (€)',
    -- ADMINISTRACION
    ABS(tpc.administracion) 'Administracion mensual (€)',
    p.m2_construidos M2,
    p.habitaciones Hab,
    p.banos 'Baños',
    p.garaje Garaje,
    p.trastero Trastero
FROM mos m
LEFT JOIN propiedad p ON m.propiedad_sku = p.sku
LEFT JOIN usuarios_publicos up ON p.usuario_publico_id = up.id
LEFT JOIN tarifasparacompra tpc ON tpc.id = 1
LEFT JOIN Alquiler a ON p.id = a.propiedad_id AND a.rn = 1
LEFT JOIN Comunidad c ON p.id = c.propiedad_id AND c.rn = 1
LEFT JOIN IBI i ON p.id = i.propiedad_id AND i.rn = 1
LEFT JOIN Seguro s ON p.id = s.propiedad_id AND s.rn = 1
WHERE p.activo = 1
ORDER BY p.fecha_escritura DESC;