# DataAnalytics-Assessment

## Q1

This particular [question's solution](./Assessment_Q1.sql) required that the query

- Finds customers who have at least one funded savings transaction
- And at least one funded investment plan, sorted by total deposits.

To achieve an efficient solution, breaking the query into bits made it much more easier to evaluate:

- Aggregate funded savings per customer
- Aggregate funded investment plans per customer where we check for at least one investment product and if it is funded or not
- Sort customers by their total deposits, check if their name is present otherwise, use their first+last name
- Display the higest deposit customers first.

### Challenges faced for Q1

- _Identifying the correct status flags_: I inspected the tables and ran diagnostic queries to determine which columns and values truly indicate “funded” products. I discovered that savings transactions use
`transaction_status IN ('success','successful','monnify_success')` and investment plans use `is_a_fund = 1 AND status_id = 1`.

- _Empty initial result set_: My first filter for investments returned zero rows, so I iterated on the flag logic until I found the correct combination that yielded 44 customers.

## Q2

This [solution](./Assessment_Q2.sql) required:

- Calculate the average number of transactions per customer per month and categorize them:
  - "High Frequency" (≥10 transactions/month)
  - "Medium Frequency" (3-9 transactions/month)
  - "Low Frequency" (≤2 transactions/month)

To give an exciting, efficient, and simple solution:

- I created an aggregate of the total transactions and count of distinct active months for each customer
- Checked the average transactions for each active month
- Created a category to tract this activity on an active-month average

### Challenges faced for Q2

- _Defining `“per month”`_: I tested both averaging over the entire calendar-month span and counting only “active months.” Seeing the different segment sizes, I chose the active-months approach to highlight true usage intensity.

- _Balancing clarity and performance_: I started with a clear multi-CTE solution, then optimized it into a single aggregation query once the logic was validated.

## Q3

The [solution](./Assessment_Q3.sql) for this question was to:

- Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days).

To achieve this, I started by:

- First I created a savings section that calculates the days since last successful deposit for a customer. Also filtering for customers with only regular savings products and funded/active plans. Kept only customers with no deposit in the last year.
- Next was the investments, and I needed to pick the most recent inflow date: last charge if it exists, otherwise start_date, then filter out any plan with an inflow in the past year with the longest inactive customers as the first output.

### Challenges faced for Q3

- _Different inflow logic per product type_:  I handled savings plans by their last deposit date and investment plans by whichever was `later—last_charge_date` or `start_date—using GREATEST(COALESCE(...), start_date)`.

- _Ensuring only active plans_:  I joined back to plans_plan for savings to apply `is_regular_savings = 1` AND `status_id = 1`, ensuring I didn’t flag closed or archived plans.

## Q4

[Solution](./Assessment_Q4.sql) to the following:

- For each customer, assuming the `profit_per_transaction` is 0.1% of the transaction value, calculate:
  - Account tenure (months since signup)
  - Total transactions
  - Estimated CLV (Assume: `CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction`)
  - Order by estimated CLV from highest to lowest

To achieve an efficient solution, breaking the query into bits made it much more easier to evaluate:

- First combined deposits and withdrawals into a single list of transaction values
- Checked for total inflows+outflows and a sum of all transaction values (kobo)
- Categorized them with their display name if available them or first+last name if that's not available.
- Checked for the tenures in full momths and extracted a raw count of all the transactions that would be used in the CLV formula.
- Calculated the rate, average transaction volume and added a profit margin of 0.1%, rounded off to 2 decimal places.
- Ensured the result is displayed with the highest value first.
