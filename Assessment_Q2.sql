-- Calculates each customer’s average transactions per month based only on months they actually transacted (“active months”),
-- then segments them into frequency categories:
--   High Frequency (≥10 transactions/month)
--   Medium Frequency (3–9 transactions/month)
--   Low Frequency (≤2 transactions/month)
-- This “active-months” method focuses on usage intensity during engagement,
-- ignoring dormant periods to highlight true power users.
SELECT
  frequency_category,
  COUNT(*) AS customer_count,
  ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month
FROM (
  -- Aggregate per customer: total transactions and count of distinct active months
  SELECT
    owner_id,
    COUNT(*) AS total_tx,
    -- Count only months in which the customer transacted
    GREATEST(
      COUNT(DISTINCT DATE_FORMAT(transaction_date, '%Y-%m')),
      1
    ) AS months_active,
    -- Average transactions per active month
    1.0 * COUNT(*) /
      GREATEST(
        COUNT(DISTINCT DATE_FORMAT(transaction_date, '%Y-%m')),
        1
      ) AS avg_tx_per_month,
    -- Assign frequency category based on this active-month average
    CASE
      WHEN COUNT(*) / GREATEST(COUNT(DISTINCT DATE_FORMAT(transaction_date, '%Y-%m')),1) >= 10 THEN 'High Frequency'
      WHEN COUNT(*) / GREATEST(COUNT(DISTINCT DATE_FORMAT(transaction_date, '%Y-%m')),1) >= 3  THEN 'Medium Frequency'
      ELSE 'Low Frequency'
    END AS frequency_category
  FROM savings_savingsaccount
  GROUP BY owner_id
) AS customer_stats
GROUP BY frequency_category
ORDER BY
  FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');