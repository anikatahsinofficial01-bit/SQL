select * from sales;

-- Design the date.
with months as (
select  date_format(max(order_date),'%Y-%m-01') as current_month,
		date_sub(date_format(max(order_date),'%Y-%m-01'), interval 1 month) as last_month,
        date_sub(date_format(max(order_date),'%Y-%m-01'), interval 2 month) as before_last_month
  from sales
  ),

customer_order as (
select customer_ID, date_format(order_date,'%Y-%m-01') as month
		from sales 
        group by 1,2
),

customer_segment as (
select c.customer_ID, 
		max(case when c.month = m.current_month then 1 else 0 end) as current_flag,
        max(case when c.month = m.last_month then 1 else 0 end) as last_flag,
        max(case when c.month < m.last_month then 1 else 0 end) as before_last_flag
 from customer_order c 
	cross join months m
    group by 1
),


final_segment as (
select *, 
	case when current_flag = 0 and last_flag = 1 and before_last_flag = 1 then 'Churned'
		 when current_flag = 0 and last_flag = 0 and before_last_flag = 1 then 'Churned'
		 when current_flag = 1 and last_flag = 0 and before_last_flag = 0 then 'New'
		 when current_flag = 1 and last_flag = 0 and before_last_flag = 1 then 'Returning'
         when current_flag = 1 and last_flag = 1 and before_last_flag = 1 then 'Retained'
         else 'Other' end as cs
 from customer_segment
)

select cs, count(*) as total_count, 
			count(*) / (select count(*) from final_segment) * 100 as perct_count
			from final_segment 
            group by 1 with rollup;
        
-- Customer Satisfaction % 

with cte1 as (
select customer_id, delivery_proposed_date, delivery_date ,
		timestampdiff(day,delivery_proposed_date,delivery_date) as lead_day
	from sales
),

cte2 as (
select c.*,
		case when c.lead_day <= 0 then 'Satisfied'
			else 'dissatisfied' end as Customer_Satisfaction_catg
	from cte1 c
)

select c.Customer_Satisfaction_catg, count(*) as total_count,
		count(*) / (Select count(*) from cte1 c) * 100 as percent_Count
 from cte2 c
	group by 1 with rollup ;