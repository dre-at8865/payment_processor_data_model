{{
    config(
        materialized='table'
    )
}}

/*
CTO (Customer Transaction Obligation) by Country

Business Logic:
- CTO is the total amount from all "approved" transactions
- Each transaction has at most one 'approved' status event
- Includes approved transactions regardless of final outcome
*/

with approved_transactions as (
    select
        f.transaction_id,
        f.customer_id,
        f.transaction_amount
    from {{ ref('fct_transaction_status') }} f
    where f.status_name = 'approved'
),

cto_summary as (
    select
        c.country_code,
        count(distinct a.transaction_id) as approved_transaction_count,
        sum(a.transaction_amount) as cto_amount,
        avg(a.transaction_amount) as avg_transaction_amount
    from approved_transactions a
    inner join {{ ref('dim_customer') }} c
        on a.customer_id = c.customer_id
    group by c.country_code
)

select
    country_code,
    approved_transaction_count,
    round(cto_amount, 2) as cto_amount,
    round(avg_transaction_amount, 2) as avg_transaction_amount,
    round(100.0 * cto_amount / sum(cto_amount) over (), 2) as pct_of_total_cto
from cto_summary
order by cto_amount desc
