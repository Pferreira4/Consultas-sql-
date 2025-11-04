
select
	trunc(date_trunc('month',a.dt_hr_operacao)) as mes_ref,
	'${semana}' as semana,	
	case when a.tipo_liquidez = 1 then 'CDB Liquidez Diaria'
		 when a.tipo_liquidez = 2 then 'CDB Longo Prazo'
		 when a.tipo_liquidez = 3 then 'CDB Longo Prazo'
	else 'Outros'
	end as Produto,	
	case when a.tipo_operacao = 1 then 'Aplicacao'
	     when a.tipo_operacao = 4 then 'Cancelada'
	else 'Resgate' 	
	end as Indicador,
	sum(a.valor_operacao) as Valor
from investimentos.movement_cdb a
where idt_order_status  = 2
and customer_id not in (select distinct cod_customer_id from dax_mdm.ids_intercompany ii)
and date_trunc('month',a.dt_hr_operacao) in ('2024-10-01','2025-08-01','2025-09-01','2025-10-01')
and date_part(day, a.dt_hr_operacao) between 1 and '${dia}'
group by 1,2,3,4

