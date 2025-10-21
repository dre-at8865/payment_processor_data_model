{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ ref('transaction_status_log') }}
),

cleaned as (
    select
        transaction_id,
        case 
            when lower(status) = 'complete' then 'completed'
            else lower(status)
        end as status,
        -- Handle corrupt timestamps - filter out invalid dates
        case 
            when try_cast(status_datetime as timestamp) is null then null
            when cast(status_datetime as timestamp) > '2100-01-01' then null
            else cast(status_datetime as timestamp)
        end as status_datetime
    from source_data
),

valid_records as (
    select *
    from cleaned
    where status_datetime is not null  -- Only keep records with valid timestamps
)

-- Remove exact duplicate rows (data quality issue in source)
select distinct
    transaction_id,
    status,
    status_datetime
from valid_records
