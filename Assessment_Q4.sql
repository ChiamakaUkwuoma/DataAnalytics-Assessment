-- Goal: Estimate CLV per customer based on tenure and full transaction volume (inflows + outflows).
-- Approach:
--   1) Union savings inflows and withdrawal outflows into one “transactions” stream.
--   2) Aggregate total count and sum of values in one scan.
--   3) Compute tenure in months since signup (min 1).
--   4) Apply CLV formula: (tx/month)*12 * (avg_tx_value * 0.001).
--   5) Order by highest estimated CLV.

WITH transactions AS (
  -- Combine deposits and withdrawals into a single list of transaction values
  SELECT
    owner_id,
    confirmed_amount AS tx_value
  FROM savings_savingsaccount
  UNION ALL
  SELECT
    owner_id,
    amount_withdrawn AS tx_value
  FROM withdrawals_withdrawal
),

tx_stats AS (
  SELECT
    owner_id,
    COUNT(*) AS total_transactions, -- total inflows+outflows
    SUM(tx_value) AS sum_tx_value -- sum of all transaction values (kobo)
  FROM transactions
  GROUP BY owner_id -- one pass over the unioned data
)

SELECT
  u.id AS customer_id,
  COALESCE(
    NULLIF(u.name, ''), -- use display name if set…
    CONCAT(u.first_name, ' ', u.last_name) -- …otherwise first+last
  ) AS name,

  -- Tenure in full months since signup (minimum 1 to avoid div/0)
  GREATEST(
    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()),
    1
  ) AS tenure_months,

  tx.total_transactions, -- raw count of all transactions

  -- CLV formula:
  -- (transactions/month) * 12 * (average_tx_value * 0.001)
  ROUND(
    (
      tx.total_transactions
      / GREATEST(TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()), 1)
    ) * 12 -- annualize rate
    * (
      (tx.sum_tx_value / tx.total_transactions) -- avg transaction value (kobo)
      * 0.001 -- profit margin of 0.1%
    ),
    2  -- round to 2 decimal places
  ) AS estimated_clv
FROM users_customuser AS u
JOIN tx_stats AS tx
  ON tx.owner_id = u.id
ORDER BY estimated_clv DESC; -- highest‐value customers first