{{
    config(
        materialized='table'
    )
}}

/*
Processing Efficiency - Clean Approvals Through Settlement

Business Logic:
- Measures % of approved transactions that settled without being put on hold
- Indicates smooth processing vs. interrupted workflows
- Each transaction has at most one 'approved' status
- Higher percentage = more efficient processing
*/

with transaction_approvals as (
    select
        transaction_id,
        status_datetime as approved_datetime
    from {{ ref('fct_transaction_status') }}
    where status_name = 'approved'
),

holds_after_approval as (
    select distinct
        f.transaction_id
    from {{ ref('fct_transaction_status') }} f
    inner join transaction_approvals a
        on f.transaction_id = a.transaction_id
    where f.status_name = 'held'
        and f.status_datetime > a.approved_datetime
),

settlement_status as (
    select distinct
        transaction_id
    from {{ ref('fct_transaction_status') }}
    where status_name in ('settled', 'completed')
),

approved_and_settled as (
    select
        a.transaction_id,
        case
            when h.transaction_id is null then 1
            else 0
        end as is_clean_settlement
    from transaction_approvals a
    inner join settlement_status s
        on a.transaction_id = s.transaction_id
    left join holds_after_approval h
        on a.transaction_id = h.transaction_id
)

select
    count(*) as total_approved_and_settled,
    sum(is_clean_settlement) as clean_settlements,
    count(*) - sum(is_clean_settlement) as settlements_with_holds,
    round(100.0 * sum(is_clean_settlement) / count(*), 2) as clean_settlement_pct,
    round(100.0 * (count(*) - sum(is_clean_settlement)) / count(*), 2) as hold_settlement_pct
from approved_and_settled
