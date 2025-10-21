{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ ref('transactions') }}
)

select
    transaction_id,
    customer_id,
    cast(transaction_amount as decimal(10,2)) as transaction_amount,
    cast(transaction_datetime as timestamp) as transaction_datetime
from source_data
