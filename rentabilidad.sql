--13) Calculo Rentabilidad
-- NOTAS:
--  + Utilizar como base una de las consultas existentes es superset:
--      + https://dashboard.commutatio.es/superset/dashboard/30/?native_filters_key=Xyjo8FcNVjLiK-kBrKsKbh9BXEOBqdRS2IWBcRztNrT9t2rs3zJJowUr4JSY-on9
--  + Pero cambiaríamos los valores centrales por tres datos:
--      + El primer dato sería el valor total de la inversión que se obtiene del mos (tabla mos) de la propiedad en el 
--        campo que almacena o con los cálculos que se hacen en este campo:
--          + http://administracion.test/ver-encargo/{sku}
--  + El segundo campo será el Retorno Neto de inversión que se obtendrá sumando los siguientes valores:
--      + Último asiento de alquiler de la propiedad 
--        (si no existiese se utilizaría el valor de alquiler almacenado en la propiedad) * 12
--      + A ese valor se le restaría:
--          + Último asiento de pago de comunidad 
--            (si no existiese se utilizaría el valor de comunidad almacenado en la propiedad) * 12
--          + Último asiento de pago de IBI (si no existiese se utilizaría el valor de IBI almacenado en la propiedad)
--          + Último asiento de pago de seguro (si no existiese se utilizaría el valor de seguro almacenado en la propiedad)
--          + Último asiento de pago de administración 
--            (si no existiese se utilizaría el valor de administración almacenado en la propiedad) * 12
--  + El tercer campo sería el Retorno Neto entre el total de inversión *100 con %
--  + Lo principal son los tres valores pero igual podemos sacar los datos intermedios.
--  + Consulta auxiliar suministrada por Chechu:
--      select 
--          m.propiedad_sku, 
--          m.pago_propiedad_bool, 
--          m.pago_propiedad,
--          m.honorarios_bool, 
--          m.honorarios,
--          m.provision_fondos_bool, 
--          m.provision_fondos ,
--          m.reforma_licencia_bool, 
--          m.reforma_licencia ,
--          m.comision_venta_bool, 
--          m.comision_venta ,
--          m.otros_conceptos_bool, 
--          m.otros_conceptos,
--          p.alquiler_estimado, 
--          p.comunidad, 
--          p.ibi, 
--          p.seguro_estimado, 
--          p.administracion 
--      from mos m, propiedad p  
--      where m.propiedad_sku ='OV-01280-01' and p.sku = m.propiedad_sku

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
    ),    
    Administracion AS (
        SELECT
            ac.*,
            ROW_NUMBER() OVER (PARTITION BY ac.propiedad_id, ac.tipo_id ORDER BY ac.fecha_creacion DESC) AS rn
        FROM
            apunte_contables ac
        WHERE
            ac.tipo_id = 31
    )
SELECT
    -- SKU
    m.propiedad_sku sku,
    -- RENTABILIDAD
    (
        (            
            CASE WHEN ABS(a.importe) > 0 THEN ABS(a.importe) * 12 ELSE ABS(p.alquiler_estimado) * 12 END -
            CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) * 12 ELSE ABS(p.comunidad) * 12 END -
            CASE WHEN ABS(i.importe) > 0 THEN ABS(i.importe) ELSE ABS(p.ibi) END -
            CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) ELSE ABS(p.seguro_estimado) END -
            CASE WHEN ABS(ad.importe) > 0 THEN ABS(ad.importe) * 12 ELSE ABS(p.administracion) END
        ) / 
        (
            CASE WHEN m.pago_propiedad_bool = 'si' THEN m.pago_propiedad ELSE 0 END +
            CASE WHEN m.honorarios_bool = 'si' THEN m.honorarios ELSE 0 END +
            CASE WHEN m.provision_fondos_bool = 'si' THEN m.provision_fondos ELSE 0 END +
            CASE WHEN m.comision_venta_bool = 'si' THEN m.comision_venta ELSE 0 END +
            CASE WHEN m.otros_conceptos_bool = 'si' THEN m.otros_conceptos ELSE 0 END +
            CASE WHEN m.reforma_licencia_bool = 'si' THEN m.reforma_licencia ELSE 0 END
        ) * 100

    ) AS rentabilidad,
    -- TOTAL MOS
    (
        CASE WHEN m.pago_propiedad_bool = 'si' THEN m.pago_propiedad ELSE 0 END +
        CASE WHEN m.honorarios_bool = 'si' THEN m.honorarios ELSE 0 END +
        CASE WHEN m.provision_fondos_bool = 'si' THEN m.provision_fondos ELSE 0 END +
        CASE WHEN m.comision_venta_bool = 'si' THEN m.comision_venta ELSE 0 END +
        CASE WHEN m.otros_conceptos_bool = 'si' THEN m.otros_conceptos ELSE 0 END +
        CASE WHEN m.reforma_licencia_bool = 'si' THEN m.reforma_licencia ELSE 0 END
    ) AS total_mos,
    -- RETORNO NETO    
    (
        CASE WHEN ABS(a.importe) > 0 THEN ABS(a.importe) * 12 ELSE ABS(p.alquiler_estimado) * 12 END -
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) * 12 ELSE ABS(p.comunidad) * 12 END -
        CASE WHEN ABS(i.importe) > 0 THEN ABS(i.importe) ELSE ABS(p.ibi) END -
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) ELSE ABS(p.seguro_estimado) END -
        CASE WHEN ABS(ad.importe) > 0 THEN ABS(ad.importe) * 12 ELSE ABS(p.administracion) END
    ) AS retorno_neto,
    -- ALQUILER
    (
        CASE WHEN ABS(a.importe) > 0 THEN ABS(a.importe) * 12 ELSE ABS(p.alquiler_estimado) * 12 END
    ) AS alquiler,
    -- COMUNIDAD
    (
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) * 12 ELSE ABS(p.comunidad) * 12 END
    ) AS comunidad,
    -- IBI
    (
        CASE WHEN ABS(i.importe) > 0 THEN ABS(i.importe) ELSE ABS(p.ibi) END
    ) AS ibi,
    -- SEGURO
    (
        CASE WHEN ABS(c.importe) > 0 THEN ABS(c.importe) ELSE ABS(p.seguro_estimado) END
    ) AS seguro,
    -- ADMINISTRACION
    (
        CASE WHEN ABS(ad.importe) > 0 THEN ABS(ad.importe) * 12 ELSE ABS(p.administracion) END
    ) AS administracion,
    -- MOS
    m.pago_propiedad_bool,
    m.pago_propiedad,
    m.honorarios_bool,
    m.honorarios,
    m.provision_fondos_bool,
    m.provision_fondos ,
    m.reforma_licencia_bool,
    m.reforma_licencia ,
    m.comision_venta_bool,
    m.comision_venta ,
    m.otros_conceptos_bool,
    m.otros_conceptos,
    -- PROPIEDAD
    p.comunidad comunidad_p,
    p.ibi ibi_p,
    p.seguro_estimado,
    p.administracion administracion_p
FROM mos m
LEFT JOIN propiedad p ON m.propiedad_sku = p.sku
LEFT JOIN Alquiler a ON p.id = a.propiedad_id AND a.rn = 1
LEFT JOIN Comunidad c ON p.id = c.propiedad_id AND c.rn = 1
LEFT JOIN IBI i ON p.id = i.propiedad_id AND i.rn = 1
LEFT JOIN Seguro s ON p.id = s.propiedad_id AND s.rn = 1
LEFT JOIN Administracion ad ON p.id = ad.propiedad_id AND ad.rn = 1;