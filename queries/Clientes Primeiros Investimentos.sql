
SELECT 
    'Clientes Primeiros Investimentos' AS base,
    '${qualasemana}' AS semana,
    TRUNC(DATE_TRUNC('MONTH', mes_uso_parcial)) AS dat_mes,
    novo_no_servico,
    COUNT(DISTINCT idt_safepay_user) AS idt_safepay_user
FROM (
    SELECT
        a.*,
        b.mes_uso,
        b.mes_uso_retencao,
        c.contador_c,
        CASE WHEN b.aux_retencao = 1 THEN 1 ELSE 0 END AS retido,
        CASE WHEN c.contador_c = 1 THEN 1 ELSE 0 END AS novo_no_servico,
        CASE WHEN retido = 0 AND novo_no_servico = 0 THEN 1 ELSE 0 END AS reativado
    FROM (
        -- Base de IDs de clientes por mês de uso
        SELECT 
            DISTINCT idt_safepay_user,
            DATE_TRUNC('month', dat_reference) AS mes_uso_parcial
        FROM dax.analytical_customer_transactions
        WHERE idt_financial_service IN (21051,21061,21081,21071,21091,21094)
          AND DATE_PART('day', dat_reference) <= '${diacred}'::INT8
        GROUP BY 1,2
    ) a
    LEFT JOIN (
        -- Retenção: verifica se o usuário usou no mês anterior
        SELECT  
            DISTINCT idt_safepay_user,
            DATE_TRUNC('month', dat_reference) AS mes_uso,
            ADD_MONTHS(DATE_TRUNC('month', dat_reference), 1) AS mes_uso_retencao,
            1 AS aux_retencao
        FROM dax.analytical_customer_transactions
        WHERE idt_financial_service IN (21051,21061,21081,21071,21091,21094)
        GROUP BY 1,2,3
    ) b ON a.idt_safepay_user = b.idt_safepay_user
       AND DATE_TRUNC('month', a.mes_uso_parcial) = b.mes_uso_retencao
    LEFT JOIN (
        -- Histórico para saber se é o primeiro uso
        SELECT 
            idt_safepay_user,
            DATE_TRUNC('month', dat_reference) AS mes_uso,
            ROW_NUMBER() OVER (PARTITION BY idt_safepay_user ORDER BY DATE_TRUNC('month', dat_reference)) AS contador_c
        FROM dax.analytical_customer_transactions
        WHERE idt_financial_service IN (21051,21061,21081,21071,21091,21094)
    ) c ON a.idt_safepay_user = c.idt_safepay_user 
        AND DATE_TRUNC('month', a.mes_uso_parcial) = c.mes_uso
)
WHERE mes_uso_parcial IN ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
GROUP BY 1,2,3,4
ORDER BY 3 DESC;



