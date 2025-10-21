{{
    config(
        materialized='table'
    )
}}

with status_log as (
    select distinct status from {{ ref('stg_transaction_status_log') }}
)

select
    status as status_name,
    case 
        when status in ('completed', 'cancelled', 'failed', 'declined') then true
        else false
    end as is_terminal_status
from status_log
