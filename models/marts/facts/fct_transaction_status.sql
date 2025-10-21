{{
    config(
        materialized='table',
        -- Production optimisation: partition by date_key, cluster by customer_id and status_name
        -- For Snowflake:
        -- cluster_by=['date_key', 'customer_id', 'status_name']
        -- For BQ:
        -- partition_by={'field': 'date_key', 'data_type': 'date'}
        -- cluster_by=['customer_id', 'status_name']
    )
}}

with status_log as (
    select * from {{ ref('stg_transaction_status_log') }}
),

transactions as (
    select * from {{ ref('int_transactions_deduplicated') }}
),

customers as (
    select * from {{ ref('dim_customer') }}
),

statuses as (
    select * from {{ ref('dim_status') }}
),

-- Join status log with transactions to get transaction details
-- Both staging tables are already deduplicated, so we get a clean 1:1 join
final as (
    select
        sl.transaction_id,
        cast(sl.status_datetime as date) as date_key,
        t.customer_id,
        sl.status as status_name,
        t.transaction_amount,
        sl.status_datetime
    from status_log sl
    inner join transactions t
        on sl.transaction_id = t.transaction_id
)

select * from final
order by transaction_id, status_datetime
