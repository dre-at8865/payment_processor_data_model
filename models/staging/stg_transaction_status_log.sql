{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ ref('transaction_status_log') }}
),

date_boundaries as (
    select
        -- Minimum valid date (configurable via dbt var)
        '{{ var("min_valid_timestamp", "2020-01-01") }}'::timestamp as min_valid_date,
        -- Maximum valid date (dynamic, allows dates up to end of current year)
        (extract(year from current_date) + 1 || '-01-01')::timestamp as max_valid_date
),

cleaned as (
    select
        transaction_id,
        case 
            when lower(status) = 'complete' then 'completed'
            else lower(status)
        end as status,
        -- Handle corrupt timestamps - filter out invalid dates (dynamic boundaries)
        case 
            when try_cast(status_datetime as timestamp) is null then null
            when cast(status_datetime as timestamp) < (select min_valid_date from date_boundaries) then null
            when cast(status_datetime as timestamp) >= (select max_valid_date from date_boundaries) then null
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
