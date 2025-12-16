WITH meses AS (
    SELECT CAST('2024-01-01' AS DATE) AS mes_ref UNION ALL
    SELECT '2024-02-01' UNION ALL
    SELECT '2024-03-01' UNION ALL
    SELECT '2024-04-01' UNION ALL
    SELECT '2024-05-01' UNION ALL
    SELECT '2024-06-01' UNION ALL
    SELECT '2024-07-01' UNION ALL
    SELECT '2024-08-01' UNION ALL
    SELECT '2024-09-01' UNION ALL
    SELECT '2024-10-01' UNION ALL
    SELECT '2024-11-01' UNION ALL
    SELECT '2024-12-01' UNION ALL
    SELECT '2025-01-01' UNION ALL
    SELECT '2025-02-01' UNION ALL
    SELECT '2025-03-01' UNION ALL
    SELECT '2025-04-01' UNION ALL
    SELECT '2025-05-01' UNION ALL
    SELECT '2025-06-01' UNION ALL
    SELECT '2025-07-01' UNION ALL
    SELECT '2025-08-01' UNION ALL
    SELECT '2025-09-01' UNION ALL
    SELECT '2025-10-01' UNION ALL
    SELECT '2025-11-01' UNION ALL
    SELECT '2025-12-01' UNION ALL
    SELECT '2026-01-01'
),
meses_validos AS (
    SELECT m.mes_ref
    FROM meses m
    WHERE m.mes_ref <= DATE_TRUNC('month', CURRENT_DATE)
),
dp_por_mes AS (
    SELECT
        DATE_TRUNC('month', dp.dat_dia)::date AS mes_ref,
        MAX(dp.dat_dia) AS ultimo_util
    FROM investimentos.dim_periodo_investimentos dp
    WHERE dp.flg_util = 1
      AND dp.dat_dia < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY 1
),
dam_por_mes AS (
    SELECT
        DATE_TRUNC('month', dam.dat_reference)::date AS mes_ref,
        MAX(dam.dat_reference) AS ultimo_dam
    FROM dax.analytical_customer_transactions dam
    WHERE dam.idt_financial_service IN (21053,21063,21083,21073,21093,21096)
      AND dam.dat_reference >= DATE '2024-01-01'
      AND dam.dat_reference <= CURRENT_DATE
    GROUP BY 1
),
cortes_por_mes AS (
    SELECT
        mv.mes_ref,
        CASE
            WHEN mv.mes_ref = DATE_TRUNC('month', CURRENT_DATE) THEN (
                SELECT MAX(dam.dat_reference)
                FROM dax.analytical_customer_transactions dam
                WHERE DATE_TRUNC('month', dam.dat_reference)::date = mv.mes_ref
                  AND date_part('day', dam.dat_reference) <= ${dia}
                  AND dam.idt_financial_service IN (21053,21063,21083,21073,21093,21096)
            )
            ELSE dp.ultimo_util
        END AS dia_corte
    FROM meses_validos mv
    LEFT JOIN dp_por_mes dp ON dp.mes_ref = mv.mes_ref
),
clientes_produtos_mes AS (
    SELECT
        DATE_TRUNC('month', dam.dat_reference)::date AS mes_ref,
        dam.cod_customer AS customer_id,
        COUNT(DISTINCT CASE dam.idt_financial_service
            WHEN 21063 THEN 'Tesouro Direto'
            WHEN 21083 THEN 'Fundos de Investimentos'
            WHEN 21073 THEN 'Renda Variável'
            WHEN 21093 THEN 'RF3'
            WHEN 21096 THEN 'Compromissada'
            WHEN 21053 THEN 'CDB'
            ELSE 'OUTROS'
        END) AS qtd_produtos_cliente
    FROM dax.analytical_customer_transactions dam
    JOIN cortes_por_mes cut
      ON DATE_TRUNC('month', dam.dat_reference)::date = cut.mes_ref
     AND dam.dat_reference = cut.dia_corte
    WHERE dam.idt_financial_service IN (21053,21063,21083,21073,21093,21096)
      AND dam.dat_reference >= DATE '2024-01-01'
      AND dam.dat_reference <  DATE '2026-01-01'
    GROUP BY 1,2
),
todos_clientes_meses AS (
    SELECT DISTINCT
        c.customer_id,
        m.mes_ref
    FROM clientes_produtos_mes c
    CROSS JOIN meses_validos m
),
marcacoes_posicao AS (
    SELECT
        t.customer_id,
        t.mes_ref,
        COALESCE(cpm.qtd_produtos_cliente, 0) AS qtd_produtos,
        CASE WHEN cpm.mes_ref IS NOT NULL THEN 1 ELSE 0 END AS posicionado
    FROM todos_clientes_meses t
    LEFT JOIN clientes_produtos_mes cpm
      ON cpm.customer_id = t.customer_id
     AND cpm.mes_ref     = t.mes_ref
),
recorrencia_mes_a_mes AS (
    SELECT
        mp.*,
        CASE
            WHEN posicionado = 1
             AND LAG(posicionado) OVER (PARTITION BY customer_id ORDER BY mes_ref) = 1
             AND LAG(mes_ref)    OVER (PARTITION BY customer_id ORDER BY mes_ref) = ADD_MONTHS(mes_ref, -1)
            THEN 0 ELSE 1
        END AS inicio_grupo
    FROM marcacoes_posicao mp
),
grupos AS (
    SELECT *,
        SUM(inicio_grupo) OVER (
            PARTITION BY customer_id
            ORDER BY mes_ref
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS grupo
    FROM recorrencia_mes_a_mes
),
faixa_completa AS (
    SELECT
        g.customer_id,
        g.mes_ref,
        g.posicionado,
        g.qtd_produtos,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, grupo
            ORDER BY mes_ref
        ) AS meses_consecutivos
    FROM grupos g
    WHERE posicionado = 1
),
clientes_com_faixas AS (
    SELECT
        fc.customer_id,
        fc.mes_ref,
        fc.qtd_produtos,
        CASE
            WHEN fc.meses_consecutivos BETWEEN 1 AND 3  THEN 'Até 3 meses'
            WHEN fc.meses_consecutivos BETWEEN 4 AND 6  THEN 'Até 6 meses'
            WHEN fc.meses_consecutivos BETWEEN 7 AND 9  THEN 'Até 9 meses'
            WHEN fc.meses_consecutivos BETWEEN 10 AND 12 THEN 'Até 12 meses'
            WHEN fc.meses_consecutivos > 12            THEN 'Acima de 12 meses'
        END AS faixa_consistencia
    FROM faixa_completa fc
),
agregado_faixas AS (
    SELECT
        mes_ref,
        SUM(CASE WHEN faixa_consistencia = 'Até 3 meses'  THEN 1 ELSE 0 END) AS ate_3_meses,
        SUM(CASE WHEN faixa_consistencia = 'Até 6 meses'  THEN 1 ELSE 0 END) AS ate_6_meses,
        SUM(CASE WHEN faixa_consistencia = 'Até 9 meses'  THEN 1 ELSE 0 END) AS ate_9_meses,
        SUM(CASE WHEN faixa_consistencia = 'Até 12 meses' THEN 1 ELSE 0 END) AS ate_12_meses,
        SUM(CASE WHEN faixa_consistencia = 'Acima de 12 meses' THEN 1 ELSE 0 END) AS acima_12_meses
    FROM clientes_com_faixas
    GROUP BY mes_ref
),
agregado_final AS (
    SELECT
        mp.mes_ref,
        COUNT(DISTINCT mp.customer_id) AS qtd_clientes_posicao,
        SUM(mp.qtd_produtos)          AS qtd_produtos
    FROM marcacoes_posicao mp
    WHERE mp.posicionado = 1
    GROUP BY mp.mes_ref
)
SELECT
    mv.mes_ref,
    COALESCE(af.qtd_clientes_posicao, 0) AS qtd_clientes_posicao,
    COALESCE(af.qtd_produtos, 0)         AS qtd_produtos,
    COALESCE(fx.ate_3_meses, 0)          AS ate_3_meses,
    COALESCE(fx.ate_6_meses, 0)          AS ate_6_meses,
    COALESCE(fx.ate_9_meses, 0)          AS ate_9_meses,
    COALESCE(fx.ate_12_meses, 0)         AS ate_12_meses,
    COALESCE(fx.acima_12_meses, 0)       AS acima_12_meses
FROM meses_validos mv
LEFT JOIN agregado_final  af ON af.mes_ref = mv.mes_ref
LEFT JOIN agregado_faixas fx ON fx.mes_ref = mv.mes_ref
ORDER BY mv.mes_ref;

