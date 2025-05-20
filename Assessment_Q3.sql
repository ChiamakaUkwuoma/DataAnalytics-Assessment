-- Flags all active Savings and Investment plans with no inflow in the last 365 days.
-- Active Savings:     p.is_regular_savings = 1 AND p.status_id = 1
-- Active Investments: p.is_a_fund         = 1 AND p.status_id = 1
-- Inactivity is measured as days since the last deposit (for Savings)
-- or since the last charge/start date (for Investments).
SELECT
  plan_id,
  owner_id,
  type,
  last_transaction_date,
  inactivity_days
FROM (
  /* ----- Savings Section ----- */
  SELECT
    spa.plan_id,
    spa.owner_id,
    'Savings' AS type,
    MAX(spa.transaction_date) AS last_transaction_date,
    -- days since last successful deposit
    DATEDIFF(CURDATE(), MAX(spa.transaction_date))  AS inactivity_days
  FROM savings_savingsaccount AS spa
  JOIN plans_plan AS p
    ON p.id = spa.plan_id
  WHERE
    spa.transaction_status IN ('success','successful','monnify_success')
    AND p.is_regular_savings = 1 -- only regular savings products
    AND p.status_id         = 1 -- only funded/active plans
  GROUP BY
    spa.plan_id,
    spa.owner_id
  HAVING
    -- keep only those with no deposit in the last year
    MAX(spa.transaction_date) < CURDATE() - INTERVAL 365 DAY

  UNION ALL

  /* ----- Investment Section ----- */
  SELECT
    p.id AS plan_id,
    p.owner_id,
    'Investment' AS type,
    -- pick the most recent inflow date: last charge if it exists, otherwise start_date
    GREATEST(
      COALESCE(p.last_charge_date, p.start_date),
      p.start_date
    ) AS last_transaction_date,
    -- days since that inflow date
    DATEDIFF(
      CURDATE(),
      GREATEST(
        COALESCE(p.last_charge_date, p.start_date),
        p.start_date
      )
    ) AS inactivity_days
  FROM plans_plan AS p
  WHERE
    p.is_a_fund = 1
    AND p.status_id = 1
    -- filter out any plan with an inflow in the past year
    AND GREATEST(
          COALESCE(p.last_charge_date, p.start_date),
          p.start_date
        ) < CURDATE() - INTERVAL 365 DAY
) AS combined_inactive
ORDER BY
  inactivity_days DESC; -- longest inactive first