{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ ref('transactions') }}
),

deduplicated as (
    select
        transaction_id,
        customer_id,
        transaction_amount,
        transaction_datetime,
        -- Add row number to identify duplicates
        row_number() over (
            partition by transaction_id 
            order by transaction_datetime
        ) as row_num
    from source_data
),

cleaned as (
    select
        transaction_id,
        customer_id,
        cast(transaction_amount as decimal(10,2)) as transaction_amount,
        cast(transaction_datetime as timestamp) as transaction_datetime
    from deduplicated
    where row_num = 1  -- Keep only the first occurrence of each transaction_id
)

select * from cleaned
