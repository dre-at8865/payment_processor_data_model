{{
    config(
        materialized='table'
    )
}}

with date_spine as (
    select distinct cast(transaction_datetime as date) as date_day
    from {{ ref('stg_transactions') }}
    
    union
    
    select distinct cast(status_datetime as date) as date_day
    from {{ ref('stg_transaction_status_log') }}
)

select
    date_day as date_key,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    extract(day from date_day) as day,
    dayname(date_day) as day_of_week,
    extract(quarter from date_day) as quarter,
    extract(week from date_day) as week_of_year,
    extract(dayofyear from date_day) as day_of_year
from date_spine
order by date_key
