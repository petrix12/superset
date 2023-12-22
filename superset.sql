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

--7) Saldo cuenta cliente (tabla): Saldo actual de cuenta clientes (501). 
-- Podemos mostrar nombre, apellidos, mail, teléfono, número de cuenta y saldo. Ojo, 
-- tomar la fecha_creación no el created_at
SELECT
    c.cuenta AS "Número de cuenta",
    up.name AS "Nombre",
    up.apellido1 AS "Primer apellido",
    up.apellido2 AS "Segundo apellido",
    up.email AS "Correo electrónico",
    up.telefono AS "Teléfono",
    COALESCE(SUM(ac.total_importe), 0) AS "Saldo actual"
FROM cuentas c
LEFT JOIN usuarios_publicos up ON c.cliente_id = up.id
LEFT JOIN (
    SELECT
        cuenta_id,
        SUM(importe) AS total_importe
    FROM (
        SELECT
            id,
            importe,
            cuenta_debe_id AS cuenta_id
        FROM apunte_contables
        UNION ALL
        SELECT
            id,
            (importe * (-1)) AS importe,
            cuenta_haber_id AS cuenta_id
        FROM apunte_contables
    ) AS subconsulta
    GROUP BY cuenta_id
) AS ac ON c.id = ac.cuenta_id
WHERE c.cliente_id IS NOT NULL
GROUP BY c.id, c.cliente_id, c.cuenta, up.name, up.apellido1, up.apellido2, up.email, up.telefono;

--8) Saldo histórico diario (gráfico de líneas): Suma total diaria de todos los saldos de todas las 
-- cuentas cliente menos la de Santi. 
WITH apuntes_con_saldo AS (
    SELECT 
        ap.fecha AS Fecha,
        SUM(ap.importe) OVER (ORDER BY ap.fecha) AS SaldoAcumulado
    FROM (
        SELECT
            fecha_creacion AS fecha,
            importe AS importe,
            cuenta_debe_id AS cuenta_id
        FROM apunte_contables
        UNION
        SELECT
            fecha_creacion AS fecha,
            (importe * (-1)) AS importe,
            cuenta_haber_id AS cuenta_id
        FROM apunte_contables    
    ) AS ap
    LEFT JOIN cuentas c ON c.id = ap.cuenta_id
    WHERE c.cliente_id IS NOT NULL AND c.cuenta != '5010063'
)
SELECT Fecha, MAX(SaldoAcumulado) AS SaldoAcumulado
FROM apuntes_con_saldo
GROUP BY Fecha
ORDER BY Fecha;

-- 9) Cantidad de retiros diarios (Gráfico de lineas): Número diario de asientos de retiro en las cuentas cliente. 
-- Ojo, tomar la fecha_creación no el created_at
SELECT
    fecha_creacion AS Fecha,
    COUNT(*) AS "Cantidad de retiros"
FROM apunte_contables
WHERE tipo_id = 65
GROUP BY Fecha
ORDER BY Fecha;

-- 10) Importe total de los retiros diarios (Gráfico de lineas): Suma diaria del importe total de los 
-- retiros realizados ese día en los asientos
SELECT
    fecha_creacion AS Fecha,
    SUM(ABS(importe)) AS TotalImportePositivo
FROM
    apunte_contables
WHERE
    tipo_id = 65
GROUP BY
    fecha_creacion
ORDER BY
    fecha_creacion;

-- 11) Tasa diaria de retiro (Gráfico de lineas): Obtener el valor diario de la suma de todos los 
-- retiros del día dividido entre el saldo total de todos los clientes (Importe total de los retiros 
-- diarios/Saldo histórico diario * 100) Es un porcentaje %
WITH apuntes_con_saldo AS (
    -- Consulta 1: Calcula Saldo Acumulado
    SELECT 
        ap.fecha AS Fecha,
        SUM(ap.importe) OVER (ORDER BY ap.fecha) AS SaldoAcumulado
    FROM (
        SELECT
            fecha_creacion AS fecha,
            importe AS importe,
            cuenta_debe_id AS cuenta_id
        FROM apunte_contables
        UNION
        SELECT
            fecha_creacion AS fecha,
            (importe * (-1)) AS importe,
            cuenta_haber_id AS cuenta_id
        FROM apunte_contables    
    ) AS ap
    LEFT JOIN cuentas c ON c.id = ap.cuenta_id
    WHERE c.cliente_id IS NOT NULL AND c.cuenta != '5010063'
),
total_importe_positivo AS (
    -- Consulta 2: Calcula Total Importe Retiro
    SELECT
        fecha_creacion AS Fecha,
        SUM(ABS(importe)) AS TotalImportePositivo
    FROM
        apunte_contables
    WHERE
        tipo_id = 65
    GROUP BY
        fecha_creacion
)
-- Consulta 3: Combina las consultas anteriores y calcula la Tasa
SELECT
    a.Fecha AS Fecha,
    (t.TotalImportePositivo / a.SaldoAcumulado) AS "Tasa de retiro"
FROM apuntes_con_saldo a
INNER JOIN total_importe_positivo t ON a.Fecha = t.Fecha
ORDER BY a.Fecha;


-- 12) Tasa diaria de depositos (Gráfico de lineas): Obtener el valor diario de la suma de todos los 
-- depositos del día dividido entre el saldo total de todos los clientes (Importe total de los depositos 
-- diarios/Saldo histórico diario * 100) Es un porcentaje %
WITH apuntes_con_saldo AS (
    -- Consulta 1: Calcula Saldo Acumulado
    SELECT 
        ap.fecha AS Fecha,
        SUM(ap.importe) OVER (ORDER BY ap.fecha) AS SaldoAcumulado
    FROM (
        SELECT
            fecha_creacion AS fecha,
            importe AS importe,
            cuenta_debe_id AS cuenta_id
        FROM apunte_contables
        UNION
        SELECT
            fecha_creacion AS fecha,
            (importe * (-1)) AS importe,
            cuenta_haber_id AS cuenta_id
        FROM apunte_contables    
    ) AS ap
    LEFT JOIN cuentas c ON c.id = ap.cuenta_id
    WHERE c.cliente_id IS NOT NULL AND c.cuenta != '5010063'
),
total_importe_positivo AS (
    -- Consulta 2: Calcula Total Importe Deposito
    SELECT
        fecha_creacion AS Fecha,
        SUM(ABS(importe)) AS TotalImportePositivo
    FROM
        apunte_contables
    WHERE
        tipo_id = 40
    GROUP BY
        fecha_creacion
)
-- Consulta 3: Combina las consultas anteriores y calcula la Tasa
SELECT 
    a.Fecha AS Fecha,
    (t.TotalImportePositivo / a.SaldoAcumulado) AS "Tasa de retiro"
FROM apuntes_con_saldo a
INNER JOIN total_importe_positivo t ON a.Fecha = t.Fecha
ORDER BY a.Fecha;





