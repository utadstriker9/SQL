WITH recency as (
  SELECT
    user_id,
    order_datetime
  FROM 
    (
      SELECT
      order_id,
      order_datetime,
      ROW_NUMBER() over(PARTITION by customer_id ORDER BY payment_date DESC) as rn
      FROM -- Insert your table
      WHERE paid_at = 'paid'
        AND status = 'COMPLETED'
    )
  WHERE rn = 1
),

frequency as (
  SELECT 
    user_id,
    COUNT(order_id) as freq,
  FROM -- Insert your table
  WHERE paid_at = 'paid'
    AND status = 'COMPLETED'
  GROUP by 1 
),

monetary as (
  SELECT 
    user_id,
    SUM(gmv) as mon,
  FROM -- Insert your table
  WHERE paid_at = 'paid'
    AND status = 'COMPLETED'
  GROUP by 1 
),

rfm_value as (
  SELECT 
    a.customer_id,
    DATE(a.order_datetime) as last_payment_date,
    DATE_DIFF(CURRENT_DATE, DATE(a.order_datetime), 'DAY') as recency,
    b,freq as frequency,
    c.mon as monetary
  FROM recency a
  LEFT JOIN frequency b 
    ON a.user_id = a.user_id
  LEFT JOIN monetary c
    ON a.user_id = c.user_id
),

rfm as (
  SELECT 
    *, 
    NTILE(5) OVER (ORDER BY recency DESC) as R,
    NTILE(5) OVER (ORDER BY frequency DESC ) as F,
    NTILE(5) OVER (ORDER BY monetary DESC ) as M 
  FROM rfm_value
),

summary as (
  SELECT
    *, 
    CONCAT(R, F, M) as rfm_class
  FROM rfm
)

SELECT 
  user_id,
  rfm_class,
  CASE 
    WHEN REGEXP_CONTAINS(rfm_class, r'^1[1-2][1-2]$') THEN 'Best Customers'
    WHEN REGEXP_CONTAINS(rfm_class, r'^15[1-2]$') THEN 'High-spending New Customers'
    WHEN REGEXP_CONTAINS(rfm_class, r'^11[3-5]$') THEN 'Lowest-Spending Active Loyal Customers'
    WHEN REGEXP_CONTAINS(rfm_class, r'^5[1-2][1-2]$') THEN 'Churned Best Customers'
  ELSE NULL 
  END as rfm_category 
FROM summary
