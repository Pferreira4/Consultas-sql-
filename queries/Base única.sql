
---AUC_Posicao
(
SELECT
    DATE(DATE_TRUNC('month', dam.dat_reference)) AS mes_ref,
    '${semana}' AS semana,
    CASE
        WHEN idt_financial_service IN (21053) THEN 'CDB'
        WHEN idt_financial_service IN (21063) THEN 'Tesouro Direto'
        WHEN idt_financial_service IN (21083) THEN 'Fundos de Investimentos'
        WHEN idt_financial_service IN (21073) THEN 'Renda Variavel'
        WHEN idt_financial_service IN (21093) THEN 'RF3 - Emissao Bancaria de Terceiros'
        WHEN idt_financial_service IN (21096) THEN 'Compromissada'
        ELSE 'outros'
    END AS Produto,
    'AuC_Posicao' AS Indicador,
    SUM(num_transaction_value) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE mes_ref IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND Produto NOT IN ('outros')
  AND dat_reference IN (
        SELECT dia
        FROM (
            SELECT
                DATE_TRUNC('month', dat_reference) AS mes_ref,
                MAX(dat_reference) AS dia
            FROM dax.analytical_customer_transactions
            WHERE DATE_PART('day', dat_reference) <= '${dia}'
              AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
            GROUP BY 1
        )
    )
GROUP BY 1,2,3,4
ORDER BY 1,3
)
UNION ALL
---Clientes_Produto
(
SELECT
    DATE(DATE_TRUNC('month', dam.dat_reference)) AS mes_ref,
    '${semana}' AS semana,
    CASE
        WHEN idt_financial_service IN (21053) THEN 'CDB'
        WHEN idt_financial_service IN (21063) THEN 'Tesouro Direto'
        WHEN idt_financial_service IN (21083) THEN 'Fundos de Investimentos'
        WHEN idt_financial_service IN (21073) THEN 'Renda Variavel'
        WHEN idt_financial_service IN (21093) THEN 'RF3 - Emissao Bancaria de Terceiros'
        WHEN idt_financial_service IN (21096) THEN 'Compromissada'
        ELSE 'outros'
    END AS Produto,
    'Clientes' AS Indicador,
    COUNT(DISTINCT cod_customer) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE mes_ref in ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND Produto NOT IN ('outros')
  AND dat_reference IN (
        SELECT dia
        FROM (
            SELECT
                DATE_TRUNC('month', dat_reference) AS mes_ref,
                MAX(dat_reference) AS dia
            FROM dax.analytical_customer_transactions
            WHERE DATE_PART('day', dat_reference) <= '${dia}'
              AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
            GROUP BY 1
        )
    )
GROUP BY 1,2,3,4
ORDER BY 1,3
)
UNION ALL
---AUC_Medio
(
SELECT
    DATE_TRUNC('month', dam.dat_reference) AS mes_ref,
    '%{semana}' AS semana,
    CASE
        WHEN idt_financial_service IN (21053) THEN 'CDB'
        WHEN idt_financial_service IN (21063) THEN 'Tesouro Direto'
        WHEN idt_financial_service IN (21083) THEN 'Fundos de Investimentos'
        WHEN idt_financial_service IN (21073) THEN 'Renda Variável'
        WHEN idt_financial_service IN (21093) THEN 'RF3 - Emissão Bancária de Terceiros'
        WHEN idt_financial_service IN (21096) THEN 'Compromissada'
        ELSE 'outros'
    END AS Produto,
    'AUC_Medio' AS Indicador,
    ROUND(
        SUM(num_transaction_value) / COUNT(DISTINCT DATE_PART('day', dam.dat_reference)),
        2
    ) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE DATE_PART('day', dam.dat_reference) <= '${dia}'
  AND mes_ref IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND Produto NOT IN ('outros')
GROUP BY 1, 2, 3, 4
ORDER BY 1, 3
)
UNION ALL
---Resgate
(
SELECT
   DATE(DATE_TRUNC('month', dat_reference)) AS mes_ref,
   '${semana}' AS semana,
   CASE
        WHEN idt_financial_service IN (21052) THEN 'CDB'
        WHEN idt_financial_service IN (21062) THEN 'Tesouro Direto'
        WHEN idt_financial_service IN (21082) THEN 'Fundos de Investimentos'
        WHEN idt_financial_service IN (21072) THEN 'Renda Variavel'
        WHEN idt_financial_service IN (21092) THEN 'RF3 - Emissao Bancaria de Terceiros'
        WHEN idt_financial_service IN (21095) THEN 'Compromissada'
        ELSE 'outros'
   END AS Produto,
   'Resgate' AS Indicador,
   SUM(num_transaction_value) AS Valor
FROM dax.analytical_customer_transactions
WHERE DATE_PART('day', dat_reference) <= '${dia}'
  AND mes_ref IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND Produto NOT IN ('outros')
GROUP BY 1,2,3,4
ORDER BY 1,3
)
UNION ALL
---Aplicacao
(
SELECT
   DATE(DATE_TRUNC('month', dat_reference)) AS mes_ref,
   '${semana}' AS semana,
   CASE
        WHEN idt_financial_service IN (21051) THEN 'CDB'
        WHEN idt_financial_service IN (21061) THEN 'Tesouro Direto'
        WHEN idt_financial_service IN (21081) THEN 'Fundos de Investimentos'
        WHEN idt_financial_service IN (21071) THEN 'Renda Variavel'
        WHEN idt_financial_service IN (21091) THEN 'RF3 - Emissao Bancaria de Terceiros'
        WHEN idt_financial_service IN (21094) THEN 'Compromissada'
        ELSE 'outros'
   END AS Produto,
   'Aplicacao' AS Indicador,
   SUM(num_transaction_value) AS Valor
FROM dax.analytical_customer_transactions
WHERE DATE_PART('day', dat_reference) <= '${dia}'
  AND mes_ref IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND Produto NOT IN ('outros')
GROUP BY 1,2,3,4
ORDER BY 1,3
)
UNION ALL
---Cliente Posicao3
(
SELECT
  DATE(DATE_TRUNC('month', dam.dat_reference)) AS mes_ref,
  '${semana}' AS semana,
  'Ativo Investimento Posicao' AS Produto,
  'Cliente_posicao' AS Indicador,
  COUNT(DISTINCT cod_customer) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE DATE_PART('day', dam.dat_reference) <= '${dia}'
  AND mes_ref IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
  AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
  AND dat_reference IN (
        SELECT dia
        FROM (
            SELECT
                DATE_TRUNC('month', dat_reference) AS mes_ref,
                MAX(dat_reference) AS dia
            FROM dax.analytical_customer_transactions
            WHERE DATE_PART('day', dat_reference) <= '${dia}'
              AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
            GROUP BY 1
        )
    )
GROUP BY 1,2,3,4
ORDER BY 1,3
)


