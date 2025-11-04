
WITH base_produtos_2025 AS (
    -- Produtos: CDBs + outros investimentos
    SELECT
        DATE_TRUNC(
            'month',
            TO_DATE(p.dat_insercao::text, 'YYYYMMDD')
        ) AS mes_ref,
        p.cod_customer_id AS customer_id,
        CASE
            WHEN p.saldo_atual = p.saldo_liquido THEN 'CDB Liquidez Diária'
            ELSE 'CDB Não Diária'
        END AS produto
    FROM investimentos.fat_investimentos_cliente_custodia p
    WHERE TO_DATE(p.dat_insercao::text, 'YYYYMMDD') >= DATE '2024-01-01'
      AND TO_DATE(p.dat_insercao::text, 'YYYYMMDD') < DATE '2026-01-01'

    UNION ALL

    SELECT
        DATE_TRUNC('month', dat_reference) AS mes_ref,
        cod_customer AS customer_id,
        CASE idt_financial_service
            WHEN 21063 THEN 'Tesouro Direto'
            WHEN 21083 THEN 'Fundos de Investimentos'
            WHEN 21073 THEN 'Renda Variável'
            WHEN 21093 THEN 'RF3'
            WHEN 21096 THEN 'Compromissada'
            ELSE 'Outros'
        END AS produto
    FROM dax.analytical_customer_transactions
    
    WHERE idt_financial_service IN (21053,21063,21083,21073,21093,21096)
      AND dat_reference >= DATE '2024-01-01'
      AND dat_reference < DATE '2026-01-01'
),

clientes_posicao_mes AS (
    SELECT
        DATE_TRUNC('month', dam.dat_reference) AS mes_ref,
        dam.cod_customer AS customer_id
    FROM dax.analytical_customer_transactions dam  
    WHERE idt_financial_service IN (21053,21063,21083,21073,21093,21096)
      AND dam.dat_reference >= DATE '2024-01-01'
      AND dam.dat_reference < DATE '2026-01-01'
),

produtos_por_cliente_mes AS (
    SELECT
        cp.mes_ref,
        cp.customer_id,
        COUNT(DISTINCT bp.produto) AS qtd_produtos_cliente
    FROM clientes_posicao_mes cp
    LEFT JOIN base_produtos_2025 bp
        ON bp.mes_ref = cp.mes_ref AND bp.customer_id = cp.customer_id
    GROUP BY 1, 2
    HAVING COUNT(DISTINCT bp.produto) > 0
),

agregado_final AS (
    SELECT
        p.mes_ref,
        COUNT(*) AS qtd_clientes_posicao,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 1 THEN 1 END) AS clientes_1_produto,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 2 THEN 1 END) AS clientes_2_produtos,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 3 THEN 1 END) AS clientes_3_produtos,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 4 THEN 1 END) AS clientes_4_produtos,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 5 THEN 1 END) AS clientes_5_produtos,
        COUNT(CASE WHEN p.qtd_produtos_cliente = 6 THEN 1 END) AS clientes_6_produtos,
        COUNT(CASE WHEN p.qtd_produtos_cliente >= 7 THEN 1 END) AS clientes_7_produtos
    FROM produtos_por_cliente_mes p
    GROUP BY p.mes_ref
)

SELECT
    mes_ref,
    qtd_clientes_posicao,
    (
        clientes_1_produto * 1 +
        clientes_2_produtos * 2 +
        clientes_3_produtos * 3 +
        clientes_4_produtos * 4 +
        clientes_5_produtos * 5 +
        clientes_6_produtos * 6 +
        clientes_7_produtos * 7
    ) AS qtd_produtos,
    clientes_1_produto,
    clientes_2_produtos,
    clientes_3_produtos,
    clientes_4_produtos,
    clientes_5_produtos,
    clientes_6_produtos,
    clientes_7_produtos,
    ROUND(( 
        clientes_1_produto * 1 +
        clientes_2_produtos * 2 +
        clientes_3_produtos * 3 +
        clientes_4_produtos * 4 +
        clientes_5_produtos * 5 +
        clientes_6_produtos * 6 +
        clientes_7_produtos * 7
    ) * 1.0 / qtd_clientes_posicao, 2) AS produto_por_cliente
FROM agregado_final
ORDER BY mes_ref;




