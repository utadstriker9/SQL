WITH activity AS (
  SELECT 
    id, 
    FORMAT_DATE('%Y-%m', DATE(period)) as login_activity
  FROM --- fill your data
  GROUP BY id, login_activity
),
cohorts AS (
  SELECT 
    _id, 
    MIN(login_activity) AS cohort
  FROM activity
  GROUP BY id
),
periods AS (
  SELECT 
    login_activity, 
    ROW_NUMBER() OVER(ORDER BY login_activity) AS rn
  FROM(
    SELECT
      DISTINCT(cohort) AS login_activity 
    FROM cohorts
  )
),
cohorts_size AS (
  SELECT
    c.cohort, 
    p.rn AS rn,
    COUNT(DISTINCT(a.id)) AS ids
  FROM cohorts c
  JOIN activity a
      ON a.login_activity = c.cohort AND c.id = a.id
  JOIN periods p
      ON p.login_activity = c.cohort
  GROUP BY cohort, rn
),
retention AS (
  SELECT
    c.cohort, 
    a.login_activity AS period, 
    p.rn AS rn, 
    COUNT(DISTINCT(c.id)) AS ids
  FROM periods p
  JOIN activity a
    ON a.login_activity = p.login_activity
  JOIN cohorts c
    ON c.id = a.id
  GROUP BY cohort, period, num
)

SELECT
  CONCAT(cs.cohort, ' - ', FORMAT("%'d", cs.ids), ' users') AS cohort, 
  r.num - cs.num AS period_lag, 
  r.period as period_label, 
  ROUND(r.ids / cs.ids * 100,2) AS retention, 
  r.ids as rids
FROM retention r
JOIN cohorts_size cs
  ON cs.cohort = r.cohort
-- WHERE cs.cohort >= FORMAT_DATE('%Y-%m', DATE())
ORDER BY cohort, period_lag, period_label
