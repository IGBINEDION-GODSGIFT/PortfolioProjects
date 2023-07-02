-- Inspecting datasets
SELECT * FROM sales.transactions;
SELECT * FROM sales.customers;
SELECT * FROM sales.date;
SELECT * FROM sales.markets;
SELECT * FROM sales.products;


-- Create a total sales column in the transaction table
ALTER TABLE transactions ADD COLUMN Total_sales DECIMAL(24,2);

UPDATE transactions SET Total_sales = sales_qty * sales_amount; 

Select distinct Sum(Total_sales) As Total_sales from transactions; 


-- Revenue by Product type
Select ts.order_date, pd.product_type, ts.sales_qty, ts.sales_amount,
ts.Total_sales
From transactions ts
Join products pd
On ts.product_code = pd.product_code
-- Group by ts.order_date
Order by 5 desc;


-- Top Customer (Using RFM)

Create temporary table rfm As
with rfm as
(
SELECT 
    cs.custmer_name, 
    SUM(ts.Total_sales) AS MonetaryValue,
    AVG(ts.Total_sales) AS AvgMonetaryValue,
    COUNT(cs.customer_code) AS Frequency,
    MAX(ts.order_date) AS last_order_date,
    (SELECT MAX(order_date) FROM transactions) AS max_order_date,
    DATEDIFF(MAX(order_date), (SELECT MAX(order_date) FROM transactions)) AS Recency
FROM customers cs 
JOIN transactions ts ON cs.customer_code = ts.customer_code
GROUP BY cs.custmer_name
),
rfm_calc as
(
		select r. *,
		NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
from rfm r
)
select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	concat(CAST(rfm_recency AS signed), CAST(rfm_frequency AS signed), CAST(rfm_monetary AS signed)) AS rfm_cell_string
from rfm_calc c;

Select custmer_name, rfm_recency, rfm_frequency, rfm_monetary,
    CASE
        WHEN rfm_cell_string IN ('111', '112', '121', '122', '123', '132', '211', '212', '114', '141') THEN 'lost_customers'
        WHEN rfm_cell_string IN ('133', '134', '143', '244', '334', '343', '344', '142', '144') THEN 'slipping_away_cannot_lose'
        WHEN rfm_cell_string IN ('311', '411', '331', '241','231', '221', '412', '312', '414') THEN 'new_customers'
        WHEN rfm_cell_string IN ('222', '223', '233', '322', '224') THEN 'potential_churners'
        WHEN rfm_cell_string IN ('323', '333', '321', '422', '332', '432', '431', '421', '423') THEN 'active'
        WHEN rfm_cell_string IN ('433', '434', '443', '444') THEN 'loyal'
    END AS rfm_segment
FROM rfm;   -- All-Out, Relief, Integration Stores, Nomad Stores, Logic Stores, Acclaimed Stores, Flawless Stores are the most active customers
-- There are no loyal customers based on the case statement.

-- Month with highest revenue
Select dt.year, sum(ts.Total_sales) As Total_sales
From date dt Join transactions ts 
On dt.date = ts.order_date
Group by dt.year
Order by 2 desc   -- 2018 is the year with the highest revenue

