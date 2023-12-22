-- Paso 1) Cuenta debe
SELECT
    id,
    importe,
    cuenta_debe_id AS cuenta_id
FROM apunte_contables

-- Paso 2) Cuenta haber
SELECT
    id,
    (importe * (-1)) AS importe,
    cuenta_haber_id AS cuenta_id
FROM apunte_contables

-- Paso 3) Unión de las consultas anteriores
SELECT
    id,
    importe,
    cuenta_debe_id AS cuenta_id
FROM apunte_contables
UNION
SELECT
    id,
    (importe * (-1)) AS importe,
    cuenta_haber_id AS cuenta_id
FROM apunte_contables

-- Paso 4) Agrupar la consulta anterior por cuenta_id
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
GROUP BY cuenta_id;

-- Paso 5) Hacer join con la tabla cuentas para traerse el campo cuenta
SELECT
    c.id AS cuenta_id,
    c.cuenta AS cuenta,
    COALESCE(SUM(ac.total_importe), 0) AS total_importe
FROM cuentas c
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
GROUP BY c.id, c.cuenta;

-- Paso 6) Filtrando la consulta anterior por las cuentas que comiencen por 501:
SELECT
    c.id AS cuenta_id,
    c.cliente_id AS cliente_id,
    c.cuenta AS cuenta,
    COALESCE(SUM(ac.total_importe), 0) AS total_importe
FROM cuentas c
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
WHERE c.cuenta LIKE '501%'
GROUP BY c.id, c.cuenta;

-- Paso 7) Hacer join con la tabla usuarios_publicos y traerse los campos nombre, apellidos, mail y teléfono
SELECT
    c.id AS cuenta_id,
    c.cliente_id AS cliente_id,
    c.cuenta AS cuenta,
    up.name,
    up.apellido1,
    up.apellido2,
    up.email,
    up.telefono,
    COALESCE(SUM(ac.total_importe), 0) AS total_importe
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
WHERE c.cuenta LIKE '501%'
GROUP BY c.id, c.cliente_id, c.cuenta, up.name, up.apellido1, up.apellido2, up.email, up.telefono;

-- Paso 8) Ajustando los campos a mostrar
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
WHERE c.cuenta LIKE '501%'
GROUP BY c.id, c.cliente_id, c.cuenta, up.name, up.apellido1, up.apellido2, up.email, up.telefono;
