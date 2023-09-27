-- 1) Liquidez RESMA (€): Indicar saldo actual 5010063 (SANTI) (10 €)
SELECT
    -- SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) AS importe_debe,
    -- SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END) AS importe_haber,
    (
        SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) -
        SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END)
    ) AS saldo
FROM
    cuentas
LEFT JOIN
    apunte_contables AS ac ON cuentas.id = ac.cuenta_debe_id OR cuentas.id = ac.cuenta_haber_id
WHERE
    cuentas.cuenta = '5010063';

-- €,.2f(12345.432 ⇒ €12,345.43)

-- 2) Tasa de liquidez (%): 5010063 / 5020003 (10 €)
SELECT
    (SELECT
        SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) - 
        SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END)
     FROM cuentas
     LEFT JOIN apunte_contables AS ac ON cuentas.id = ac.cuenta_debe_id OR cuentas.id = ac.cuenta_haber_id
     WHERE cuentas.cuenta = '5010063') AS saldo1,
    
    (SELECT
        SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) - 
        SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END)
     FROM cuentas
     LEFT JOIN apunte_contables AS ac ON cuentas.id = ac.cuenta_debe_id OR cuentas.id = ac.cuenta_haber_id
     WHERE cuentas.cuenta = '5020003') AS saldo2,

    (SELECT
        SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) - 
        SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END)
    FROM cuentas
    LEFT JOIN apunte_contables AS ac ON cuentas.id = ac.cuenta_debe_id OR cuentas.id = ac.cuenta_haber_id
    WHERE cuentas.cuenta = '5010063') / (SELECT
        SUM(CASE WHEN ac.cuenta_debe_id = cuentas.id THEN ac.importe ELSE 0 END) - 
        SUM(CASE WHEN ac.cuenta_haber_id = cuentas.id THEN ac.importe ELSE 0 END)
    FROM cuentas
    LEFT JOIN apunte_contables AS ac ON cuentas.id = ac.cuenta_debe_id OR cuentas.id = ac.cuenta_haber_id
    WHERE cuentas.cuenta = '5020003') AS relacion_sados;

-- 3) Coste del capital (%): Total para los partícipes / Pasivo (10 €)
-- Nota: Suma Importe estimado participes / Total participado
SELECT
    (
        SELECT SUM(total_para_participes) FROM (
            SELECT ap.importe_estimado_participes AS total_para_participes
            FROM activo_participado ap
            JOIN propiedad p ON ap.activo_id = p.id
        ) AS virtual_table
    ) AS "Total para partícipes",
    (
        SELECT SUM(`SUM(participaciones_circulacion * valor_participacion)`) FROM (
            SELECT SUM(participaciones_circulacion * valor_participacion)
            FROM commutatio.activo_participado
        ) AS virtual_table
    ) AS "Pasivo",    
    (
        SELECT SUM(total_para_participes) FROM (
            SELECT ap.importe_estimado_participes AS total_para_participes
            FROM activo_participado ap
            JOIN propiedad p ON ap.activo_id = p.id
        ) AS virtual_table
    ) / 
    (
        SELECT SUM(`SUM(participaciones_circulacion * valor_participacion)`) FROM (
            SELECT SUM(participaciones_circulacion * valor_participacion)
            FROM commutatio.activo_participado
        ) AS virtual_table
    ) AS "Coste del capital";

-- 4) Plusvalías latentes (€): Precio de venta del activo en Commutatio.es - Inmovilizado (10 €)
SELECT SUM(p.precio_vendedor - ap.total_adquisicion) AS "Plusvalías"
FROM activo_participado ap
JOIN propiedad p ON p.id = ap.activo_id
WHERE ap.publicado = 1;

de la tabla activo_participado busca los registros con campo activo_id que coincidan con el campo id de la tabla propiedades y 
donde el campo publicado de la tabla activo_participado sea igual a 1, de los registros coincidentes suma los campos precio_vendedor
de la tabla propiedad y este resultado se le resta la suma de los campos total_adquisicion de la tabla activo_participado

-- Consulta base
SELECT p.sku,p.precio_vendedor - ap.total_adquisicion, p.precio_vendedor, ap.total_adquisicion, ap.* 
FROM activo_participado ap, propiedad p 
WHERE p.id = ap.activo_id AND ap.publicado = 1;

-- 5) % latentes partícipes (€): valor de emisión por participación * % de plusvalía en el programa de emisión * Nº de participaciones en circulación  (10 €)
SELECT SUM(ap.valor_participacion * ap.plusvalia/100 * ap.participaciones_circulacion) AS "Latentes partícipes"
FROM activo_participado ap
WHERE ap.publicado = 1;

-- Consulta base
SELECT 
    ap.valor_participacion * ap.plusvalia/100 * ap.participaciones_circulacion, 
    ap.valor_participacion, 
    ap.plusvalia, 
    ap.participaciones_circulacion, 
    ap.* 
FROM activo_participado ap 
WHERE ap.publicado = 1;

--6) % Plusvalía NETA (%): (Plusvalías latentes - plusvalías latentes para participes)  / coste de adquisición
SELECT 
    SUM(p.precio_vendedor - ap.total_adquisicion) AS "Plusvalías latentes",
    SUM(ap.total_adquisicion) AS "Coste de adquisición",
    SUM(ap.valor_participacion * ap.plusvalia/100 * ap.participaciones_circulacion) AS "Plusvalías latentes para participes",
    (
        (
            SUM(p.precio_vendedor - ap.total_adquisicion) - 
            SUM(ap.valor_participacion * ap.plusvalia/100 * ap.participaciones_circulacion)
        ) / SUM(ap.total_adquisicion)
    ) AS "% Plusvalía NETA"
FROM activo_participado ap
JOIN propiedad p ON p.id = ap.activo_id
WHERE ap.publicado = 1;

-- Plusvalías latentes y Coste de adquisición
SELECT 
    SUM(p.precio_vendedor - ap.total_adquisicion) AS "Plusvalías latentes",
    SUM(ap.total_adquisicion) AS "Coste de adquisición"
FROM activo_participado ap
JOIN propiedad p ON p.id = ap.activo_id
WHERE ap.publicado = 1;

-- Plusvalías latentes para participes
SELECT SUM(ap.valor_participacion * ap.plusvalia/100 * ap.participaciones_circulacion) AS "Plusvalías latentes para participes"
FROM activo_participado ap
WHERE ap.publicado = 1;


