{{
    config(
        materialized='table'
    )
}}

with status_log as (
    select * from {{ ref('stg_transaction_status_log') }}
),

transactions as (
    select * from {{ ref('stg_transactions') }}
),

customers as (
    select * from {{ ref('dim_customer') }}
),

statuses as (
    select * from {{ ref('dim_status') }}
),

dates as (
    select * from {{ ref('dim_date') }}
),

-- Join status log with transactions to get transaction details
status_with_transactions as (
    select
        sl.transaction_id,
        sl.status,
        sl.status_datetime,
        t.customer_id,
        t.transaction_amount,
        lag(sl.status_datetime) over (
            partition by sl.transaction_id 
            order by sl.status_datetime
        ) as previous_status_datetime
    from status_log sl
    inner join transactions t
        on sl.transaction_id = t.transaction_id
),

-- Calculate time differences and add row number for uniqueness
final as (
    select
        transaction_id,
        cast(status_datetime as date) as date_key,
        customer_id,
        status as status_name,
        transaction_amount,
        case 
            when previous_status_datetime is not null 
            then cast(extract(epoch from (status_datetime - previous_status_datetime)) as integer)
            else null
        end as time_from_previous_status_sec,
        status_datetime,
        row_number() over (
            partition by transaction_id, status, status_datetime 
            order by status_datetime
        ) as row_num
    from status_with_transactions
)

select * from final
order by transaction_id, status_datetime
