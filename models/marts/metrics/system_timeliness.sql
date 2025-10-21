{{
    config(
        materialized='table'
    )
}}

/*
System Timeliness - Average Time to Complete Approved Transactions

Business Logic:
- Measures time from "approved" to "completed" status
- Only includes transactions that reached both statuses
- Each transaction has at most one 'approved' and one 'completed' status
- Lower is better (faster processing)
*/

with approved_status as (
    select
        transaction_id,
        status_datetime as approved_datetime
    from {{ ref('fct_transaction_status') }}
    where status_name = 'approved'
),

completed_status as (
    select
        transaction_id,
        status_datetime as completed_datetime
    from {{ ref('fct_transaction_status') }}
    where status_name = 'completed'
),

approval_to_completion as (
    select
        a.transaction_id,
        a.approved_datetime,
        c.completed_datetime,
        extract(epoch from (c.completed_datetime - a.approved_datetime)) as time_to_complete_sec
    from approved_status a
    inner join completed_status c
        on a.transaction_id = c.transaction_id
)

select
    count(distinct transaction_id) as completed_transaction_count,
    round(avg(time_to_complete_sec), 0) as avg_time_to_complete_sec,
    round(avg(time_to_complete_sec) / 60, 1) as avg_time_to_complete_min,
    round(avg(time_to_complete_sec) / 3600, 2) as avg_time_to_complete_hours,
    round(min(time_to_complete_sec), 0) as min_time_to_complete_sec,
    round(max(time_to_complete_sec), 0) as max_time_to_complete_sec,
    round(percentile_cont(0.5) within group (order by time_to_complete_sec), 0) as median_time_to_complete_sec,
    round(percentile_cont(0.95) within group (order by time_to_complete_sec), 0) as p95_time_to_complete_sec
from approval_to_completion
