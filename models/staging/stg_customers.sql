{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ ref('customers') }}
),

cleaned as (
    select
        customer_id,
        -- Clean up country codes: GBRR -> GBR
        case 
            when country = 'GBRR' then 'GBR'
            else country
        end as country_code
    from source_data
)

select * from cleaned
