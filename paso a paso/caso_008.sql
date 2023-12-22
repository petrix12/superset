-- Paso 1) Obtener todos los apuntes contables
SELECT * FROM (
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
) AS apuntes

-- Paso 2) Join con la tabla cuentas para traerse la cuenta
SELECT * FROM (
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
) AS apuntes
LEFT JOIN cuentas c ON c.id = apuntes.cuenta_id

-- Paso 3) Filtra cuentas
SELECT * FROM (
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
) AS apuntes
LEFT JOIN cuentas c ON c.id = apuntes.cuenta_id
WHERE c.cuenta LIKE '501%' AND c.cuenta != '5010063'

-- Paso 4) Agrupar por fecha y sumar el importe
SELECT 
    apuntes.fecha AS Fecha,
    SUM(apuntes.importe) AS Saldo
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
) AS apuntes
LEFT JOIN cuentas c ON c.id = apuntes.cuenta_id
WHERE c.cuenta LIKE '501%' AND c.cuenta != '5010063'
GROUP BY apuntes.fecha

-- Paso 5) Mostrar saldos acumulados
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
    WHERE c.cuenta LIKE '501%' AND c.cuenta != '5010063'
)
SELECT Fecha, SaldoAcumulado FROM apuntes_con_saldo;

-- Paso 6) Agrupar el resultado anterior por fecha
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
    WHERE c.cuenta LIKE '501%' AND c.cuenta != '5010063'
)
SELECT Fecha, MAX(SaldoAcumulado) AS SaldoAcumulado
FROM apuntes_con_saldo
GROUP BY Fecha
ORDER BY Fecha;
