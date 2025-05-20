-- Finds customers who have at least one funded savings transaction
-- and at least one funded investment plan, sorted by total deposits.
WITH
  -- Aggregate funded savings per customer
  savings AS (
    SELECT
      owner_id,
      COUNT(*)    AS savings_count,
      SUM(amount) AS total_deposits
    FROM savings_savingsaccount
    WHERE transaction_status IN ('success','successful','monnify_success')
    GROUP BY owner_id
  ),

  -- Aggregate funded investment plans per customer
  investments AS (
    SELECT
      owner_id,
      COUNT(*) AS investment_count
    FROM plans_plan
    WHERE is_a_fund  = 1    -- flag for investment products
      AND status_id = 1     -- funded status code
    GROUP BY owner_id
  )

-- Final result: customers in both sets, sorted by their total deposits
SELECT
  u.id                                    AS owner_id,
  COALESCE(
    NULLIF(u.name, ''),                   -- use `name` if present...
    CONCAT(u.first_name, ' ', u.last_name) -- ...otherwise fall back to first+last
  )                                       AS name,
  s.savings_count,
  i.investment_count,
  FORMAT(s.total_deposits, 2)             AS total_deposits
FROM users_customuser u
JOIN savings     s ON s.owner_id      = u.id
JOIN investments i ON i.owner_id      = u.id
ORDER BY s.total_deposits DESC;          -- highest‐deposit customers first