/*
Singular Test: Detect Invalid Timestamps

This test identifies records with timestamps outside reasonable business boundaries.
Fails if any status_datetime values are:
- Before min_valid_timestamp (default: 2020-01-01, configurable via dbt var)
- After current year + 1 (dynamic, catches future dates automatically)

Usage:
  dbt test --select assert_no_invalid_timestamps
  
  # Override minimum date:
  dbt test --select assert_no_invalid_timestamps --vars '{"min_valid_timestamp": "2021-01-01"}'
*/

with source_data as (
    select 
        transaction_id,
        status,
        status_datetime,
        extract(year from status_datetime) as year
    from {{ ref('stg_transaction_status_log') }}
),

date_boundaries as (
    select
        -- Configurable minimum date
        '{{ var("min_valid_timestamp", "2020-01-01") }}'::timestamp as min_valid_date,
        -- Allow dates up to end of current year (dynamic)
        (extract(year from current_date) + 1 || '-01-01')::timestamp as max_valid_date
)

select
    sd.transaction_id,
    sd.status,
    sd.status_datetime,
    sd.year,
    db.max_valid_date as current_boundary
from source_data sd
cross join date_boundaries db
where 
    sd.status_datetime < db.min_valid_date
    or sd.status_datetime >= db.max_valid_date
