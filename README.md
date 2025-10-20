Dojo Analytics Engineering Task

Task 1: Data Modelling
Classic Star Schema centered on transaction status events.

1.1 Fact and Dimension Tables
fct_transaction_status (Fact):

Grain: One row per transaction status change (e.g., one row for 'approved', another for 'settled' for the same transaction).

Purpose: Captures the complete lifecycle of a transaction, enabling analysis of time-between-steps and conversion funnels.

Key Columns: transaction_status_key (PK), date_key (FK), customer_key (FK), status_key (FK), transaction_id (Degenerate Dimension), transaction_amount, time_from_previous_status_sec.

dim_customer (Dimension):

Grain: One row per customer.

Key Columns: customer_key (PK), customer_id (Natural Key), country_code (Cleaned).

dim_status (Dimension):

Grain: One row per unique, cleaned status.

Key Columns: status_key (PK), status_name (e.g., 'Completed'), is_terminal_status (Boolean).

dim_date (Dimension):

Grain: One row per day.

Key Columns: date_key (PK), full_date, day_of_week, month, year.

1.2 Schema Diagram
Code snippet

erDiagram
    fct_transaction_status {
        bigint transaction_status_key PK
        int date_key FK
        int customer_key FK
        int status_key FK
        varchar transaction_id
        decimal transaction_amount
        int time_from_previous_status_sec
    }
    dim_date { int date_key PK }
    dim_customer { int customer_key PK }
    dim_status { int status_key PK }

    fct_transaction_status }|--|| dim_date : "belongs to"
    fct_transaction_status }|--|| dim_customer : "belongs to"
    fct_transaction_status }|--|| dim_status : "has"
1.3 Discussion Points
EDA uncovered several critical data quality issues that must be resolved during transformation:

Data Quality Issues:

Duplicate Transaction Headers: transactions has 151 rows but only 146 unique transaction_ids. This source table must be deduplicated.

Inconsistent Categorical Data: status has both 'complete' and 'completed'. country has 'GBR' and 'GBRR'. These must be conformed in their respective dimension tables.

Corrupt Timestamps: status_datetime has out-of-bounds values (2999-01-11). This requires error handling during type conversion.

Orphan Transactions: 146 unique transactions exist, but only 84 (57.5%) have a status log. This implies over 40% of transactions are "stuck" or the log data is incomplete.

Optimisation:

Read: The fct_transaction_status table must be partitioned by date (e.g., status_date) and clustered by customer_key and status_key for fast analytical queries.

Write: Data should be loaded incrementally into staging tables first, then transformed in parallel into the final dimensional model.