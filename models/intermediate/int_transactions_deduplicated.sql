{{
    config(
        materialized='view'
    )
}}

/*
Intermediate Model: Deduplicate Transactions

Business Rule:
- Some transaction_ids appear multiple times with different amounts/timestamps
- Analysis shows status_log entries correlate with the EARLIEST transaction_datetime (within 1-3 seconds)
- Later records appear to be retries/corrections without corresponding status events
- Therefore, we keep the first transaction by datetime to match with status_log

Data Quality Issue:
- 1 duplicate record
- 4 transaction_ids reused
*/

with transactions as (
    select * from {{ ref('stg_transactions') }}
),

deduplicated as (
    select
        transaction_id,
        customer_id,
        transaction_amount,
        transaction_datetime,
        row_number() over (
            partition by transaction_id 
            order by transaction_datetime  -- Keep earliest - matches status_log timing
        ) as row_num
    from transactions
)

select
    transaction_id,
    customer_id,
    transaction_amount,
    transaction_datetime
from deduplicated
where row_num = 1
