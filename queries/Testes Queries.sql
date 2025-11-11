
--- apartir daqui é só testes


--teste bruna

select
	trunc(date_trunc('month',a.dt_hr_operacao)) as mes_ref,
	'${semana}' as semana,	
	case when a.tipo_liquidez = 1 then 'CDB Liquidez Diaria'
		 when a.tipo_liquidez = 2 then 'CDB Longo Prazo'
		 when a.tipo_liquidez = 3 then 'CDB Longo Prazo'
	else 'Outros'
	end as Produto,	
	CASE
    WHEN papel IN ('CDB AB T2', 'CDB AB T1', 'CDB ESC 5', 'CDB ESC 6', 'CDB ESC 13') THEN produto || ' Turbinado'
    WHEN papel IN ('CDB ESC 9', 'CDB ESC 8', 'CDB ESC 7', 'CDB ESC 11', 'CDB ESC 10', 'CDB ESC 12') THEN 'CDB Retenção'
    WHEN DESCRICAO LIKE '%CDB Cofrinho%' THEN 'cofrinho'
    WHEN papel ILIKE '%AA%' THEN 'Poupar Automático'
    WHEN LIQUIDEZ = 1 AND percentual_cdi >= 120 THEN 'HY'
    WHEN LIQUIDEZ = 1 THEN 'CDB LD'
    ELSE 'CDB SLD'
END AS TIPO_PRODUTO,
	case when a.tipo_operacao = 1 then 'Aplicacao'
	     when a.tipo_operacao = 4 then 'Cancelada'
	else 'Resgate' 	
	end as Indicador,
	sum(a.valor_operacao) as Valor
from investimentos.movement_cdb a
where idt_order_status  = 2
and customer_id not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
and date_trunc('month',a.dt_hr_operacao) in ('2024-10-01','2025-10-01')
and date_part(day, a.dt_hr_operacao) between 1 and '${dia}'
group by 1,2,3,4,5





--teste pablo
-- Liquidez Diária (somente papéis de liquidez, sem CDB 130, Poupar Automático e Cofrinho)
SELECT
    trunc(date_trunc('month', a.dt_hr_operacao)) AS mes_ref,
    '${semana}' AS semana,

    CASE 
        WHEN a.tipo_liquidez = 1 THEN 'CDB Liquidez Diária'
        ELSE 'Outros'
    END AS produto,

    CASE 
        WHEN a.tipo_operacao = 1 THEN 'Aplicacao'
        WHEN a.tipo_operacao = 4 THEN 'Cancelada'
        ELSE 'Resgate'
    END AS indicador,

    SUM(a.valor_operacao) AS valor

FROM investimentos.movement_cdb a
WHERE idt_order_status = 2
  AND a.tipo_liquidez = 1  -- só liquidez diária
  AND customer_id NOT IN (
        SELECT DISTINCT cod_customer_id 
        FROM dax_mdm.ids_intercompany i
  )

  -- 🧹 Exclui Cofrinho, CDB 130 e Poupar Automático
  AND NOT (
        a.papel ILIKE '%AA%'  -- Poupar Automático
        OR a.papel LIKE 'CDB COFR%' 
        OR a.papel IN ('CDB CFFID1','CDB CFFID2') -- Cofrinho
        OR (a.produto LIKE 'CDB 130%' AND a.tipo_liquidez = 1) -- CDB 130
  )

  AND date_trunc('month', a.dt_hr_operacao) IN (
        '2024-10-01',  '2025-10-01'
  )
  AND date_part('day', a.dt_hr_operacao) BETWEEN 1 AND '${dia}'

GROUP BY 1, 2, 3, 4
ORDER BY mes_ref, indicador;


--------------------- RF3 auc medio thirparty VISÃO DIARIA 

(
select
	'RF3 - Emissão Bancária de Terceiros' 					as Produto,
	mes_ref,
	'${semana}'												as semana,
	round(AUC/ total_dias, 2)							 	as AuC_Medio
From (
select
        date(dat_position) as mes_ref,
        count(distinct date_part('day', dat_position)) as total_dias,
        sum(val_updated_gross_financial) as AUC
	from investimentos.thirdparty_fixedincome_position a  --select* from investimentos.thirdparty_fixedincome_position limit 10
	left join dax.ent_customer_psp b on a.idt_customer = b.idt_customer
	where a.idt_customer not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
	and a.dat_position is not null
	and date_part(day,dat_position) <= '${dia}'
	group by 1
	)
where mes_ref >='2025-01-01'
)



---------------- RF3 auc medio thirparty VISÃO MENSAL 
(
select
	'RF3 - Emissão Bancária de Terceiros' 					as Produto,
	mes_ref,
	'${semana}'												as semana,
	round(AUC/ total_dias, 2)							 	as AuC_Medio
From (
	select
		trunc(date_trunc ('month',dat_position))			as mes_ref,
		count(distinct  date_part('day', dat_position))		as total_dias ,
		sum(val_updated_gross_financial) 					as AUC
		
	from investimentos.thirdparty_fixedincome_position a  --select* from investimentos.thirdparty_fixedincome_position limit 10
	left join dax.ent_customer_psp b on a.idt_customer = b.idt_customer
	where a.idt_customer not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
	and a.dat_position is not null
	and date_part(day,dat_position) <= '${dia}'
	group by 1
	)
where mes_ref >='2021-01-01'
)




--- QUEBRA RF3 VISÃO DIARIA

    (
select
	'RF3 - Emissão Bancária de Terceiros' 					as Produto,
	mes_ref,
	'${semana}'												as semana,
	round(AUC/ total_dias, 2)							 	as AuC_Medio
From (
select
        date(dat_position) as mes_ref,
        count(distinct date_part('day', dat_position)) as total_dias,
        sum(val_updated_gross_financial) as AUC
	from investimentos.thirdparty_fixedincome_position a  --select* from investimentos.thirdparty_fixedincome_position limit 10
	left join dax.ent_customer_psp b on a.idt_customer = b.idt_customer
	where a.idt_customer not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
	and a.dat_position is not null
	and date_part(day,dat_position) <= '${dia}'
	and des_product_type <> 'LF'
	group by 1
	)
where mes_ref >='2025-01-01'
)



----- QUEBRA COMPROMISSADA VISÃO DIARIAA
(
select
	'Compromissada' 					as Produto,
	mes_ref,
	'${semana}'												as semana,
	round(AUC/ total_dias, 2)							 	as AuC_Medio
From (
select
        date(dat_position) as mes_ref,
        count(distinct date_part('day', dat_position)) as total_dias,
        sum(val_updated_gross_financial) as AUC
	from investimentos.thirdparty_fixedincome_position a  --select* from investimentos.thirdparty_fixedincome_position limit 10
	left join dax.ent_customer_psp b on a.idt_customer = b.idt_customer
	where a.idt_customer not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
	and a.dat_position is not null
	and date_part(day,dat_position) <= '${dia}'
	and des_product_type = 'LF'
	group by 1
	)
where mes_ref >='2025-01-01'
)



-- Clientes_Produto_Diario tabela nova (novos negocios)
SELECT
    DATE(dam.dat_reference) AS dia_ref,
    '${semana}' AS semana,
    'Fundos de Investimentos' AS Produto,
    'Clientes' AS Indicador,
    COUNT(DISTINCT cod_customer) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE idt_financial_service = 21083
  AND dam.dat_reference BETWEEN '2025-09-01' AND '2025-09-30' 
GROUP BY 1,2,3,4
ORDER BY 1;




-- Clientes que transacionaram no período, usando a FAT de posição
SELECT
    TO_DATE(fic.idt_dat_posicao::VARCHAR, 'YYYYMMDD') AS dia_ref,
    '${semana}' AS semana,
    'Fundos de Investimentos' AS produto,
    'Clientes' AS indicador,
    COUNT(DISTINCT fic.cod_customer_id) AS valor
FROM investimentos.fat_investimentos_cliente_custodia fic
JOIN investimentos.dim_periodo_investimentos dp
  ON dp.dat_dia = TO_DATE(fic.idt_dat_posicao::VARCHAR, 'YYYYMMDD')
 AND dp.flg_util = 1
-- 🔑 join com a tabela de transações para pegar apenas clientes que tiveram movimento
JOIN dax.analytical_customer_transactions act
  ON act.cod_customer = fic.cod_customer_id
 AND act.idt_financial_service = 21083
 AND act.dat_reference BETWEEN DATE '2025-10-01' AND DATE '2025-10-30'
WHERE fic.saldo_atual > 0
  AND TO_DATE(fic.idt_dat_posicao::VARCHAR, 'YYYYMMDD')
      BETWEEN DATE '2025-10-01' AND DATE '2025-10-30'
GROUP BY 1,2,3,4
ORDER BY 1;




--cdb21053

SELECT
    DATE(dam.dat_reference) AS dia_ref,
    '${semana}' AS semana,
    'CDB' AS Produto,
    'Clientes' AS Indicador,
    COUNT(DISTINCT cod_customer) AS Valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
   AND dp.flg_util = 1
WHERE idt_financial_service = 21053
  AND dam.dat_reference BETWEEN '2025-09-01' AND '2025-09-30' 
GROUP BY 1,2,3,4
ORDER BY 1;





---------------------------------------


-- teste cliente posicao visão diaria
SELECT
    dam.dat_reference AS dia_ref,
    '${semana}' AS semana,
    'Ativo Investimento Posicao' AS produto,
    'Cliente_posicao' AS indicador,
    COUNT(DISTINCT cod_customer) AS valor
FROM dax.analytical_customer_transactions dam
JOIN investimentos.dim_periodo_investimentos dp
    ON dp.dat_dia = dam.dat_reference
    AND dp.flg_util = 1
WHERE DATE_TRUNC('month', dam.dat_reference) = DATE '2025-09-01'
  AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
  AND dam.dat_reference IN (
      SELECT dat_reference
      FROM dax.analytical_customer_transactions
      WHERE DATE_TRUNC('month', dat_reference) = DATE '2025-09-01'
        AND idt_financial_service IN (21053,21063,21083,21073,21093,21096)
      GROUP BY dat_reference
  )
GROUP BY 1,2,3,4
ORDER BY 1,3;

a




alterações pablo teste
