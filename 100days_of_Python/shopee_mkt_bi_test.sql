with temp_daily_user as (
    SELECT a.grass_date as report_date,
        b.default_delivery_address_city as location,
        count( distinct(a.user_id)) as total_user,
        count( distinct(a.user_id)) filter (where a.login_platform = 'App') as app_user,
        count( distinct(a.user_id)) filter (where a.login_platform = 'Web') as web_user
    FROM dwd_login_event a
    LEFT JOIN dim_user b on a.user_id = b.user_id
    WHERE a.grass_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 year' 
    GROUP BY 1, 2
)
, temp_daily_metric as(
    SELECT  to_char(to_timestamp(create_timestamp), 'YYYY-MM-DD') ::date as report_date,
        a.buyer_shipping_address_city as location,
        count(distinct(a.buyer_id)) as num_buyer,
        count(distinct(a.order_id)) as num_order,
        sum(a.gmv_usd) as gmv_usd
    FROM order_item_mart a
    GROUP BY 1, 2
)
SELECT coalesce(a.report_date, b.report_date) as report_date,
        coalesce(a.location, b.location) as location,
        a.total_user as total_user,
        a.app_user as app_user,
        a.web_user as web_user,
        b.num_buyer as num_buyer,
        b.num_order as num_order,
        b.gmv_usd as gmv_usd
FROM temp_daily_user a
FULL JOIN temp_daily_metric b on a.report_date = b.report_date and a.location = b.location


    with first_order as (
        SELECT buyer_id,
            DATE_TRUNC('month', min(date(create_datetime))) as first_order_month
        FROM order_item_mart
        GROUP BY 1
    )
    , cohort_orders as (
        SELECT a.buyer_id,
                a.first_order_month,
                date(b.create_datetime) as repeat_order_date
                date(b.create_datetime) - a.first_order_month as num_days
        FROM first_order a
        INNER JOIN order_item_mart b on a.buyer_id = b.buyer_id
    )
    SELECT first_order_month,
            case 
                when num_days <= 30 then '0-30 days'
                when num_days <= 60 then '31-60 days'
                when num_days <= 90 then '61-90 days'
            else '90+ days' end as retained_group,
            count(distinct buyer_id) as num_users
    FROM cohort_orders
    GROUP BY 1, 2

-- Find out top 10 items by orders per earch seller segment by month, together with average selling price/item, min price, max price, and orders and gmv coverage
with get_avg_order as (
    SELECT seller_id,
        count(distinct order_id) / nullif(count( distinct (date(create_datetime))), 0) as avg_daily_order
    FROM order_item_mart 
    WHERE is_net_order = 1
    GROUP BY 1
)
, get_group_seller as (
    SELECT seller_id,
            case when coalesce(avg_daily_order, 0) < 10 then 'Long Tail'
                when coalesce(avg_daily_order, 0) <= 20 then 'Mid Tail'
                else 'Short Tail'
            end as seller_segment
    FROM get_avg_order
)
, get_key_metrics as (
    SELECT  b.seller_segment,
            item_id,
            to_char(date(create_datetime), 'YYYY-MM') as order_month,
            sum(gmv_usd) as total_gmv_usd,
            sum(item_amount) as total_quantity,
            count(distinct order_id) as num_order,
            sum(gmv_usd)/ nullif(sum(item_amount), 0) as avg_price,
            min(gmv_usd) filter (where item_amount = 1) as min_price,
            max(gmv_usd) filter (where item_amount = 1) as max_price

    FROM order_item_mart a
    LEFT JOIN get_group_seller b on a.seller_id = b.seller_id
    WHERE is_net_order = 1 -- only get net order
    GROUP by 1,2,3
)
, get_rank_items as (
    SELECT seller_segment,
            order_month,
            item_id,
            total_gmv_usd,
            total_quantity,
            num_order,
            avg_price,
            min_price,
            max_price,
            rank() over(partition by order_month, seller_segment order by num_order desc) as rank
    FROM get_key_metrics
)

SELECT * 
FROM get_rank_items 
WHERE rank <= 10
order by seller_segment, order_month desc , num_order desc


with buyer_total_spend as (
    SELECT buyer_id,
            sum(gmv_usd) as total_gmv_usd
    FROM order_item_mart
    GROUP BY 1
)
, get_quartiles as (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN group (order by total_gmv_usd) as q1,
        PERCENTILE_CONT(0.50) WITHIN group (order by total_gmv_usd) as q2,
        PERCENTILE_CONT(0.75) WITHIN group (order by total_gmv_usd) as q3
    FROM buyer_total_spend
)
, get_buyer_segment as (
    SELECT buyer_id,
            case when total_gmv_usd >= (SELECT q3 FROM get_quartiles) then 'VIP'
            when total_gmv_usd >= (SELECT q2 FROM get_quartiles) then 'Loyal'
            when total_gmv_usd >= (SELECT q1 FROM get_quartiles) then 'Casual'
            else 'New-commer' end as buyer_segment
    FROM buyer_total_spend
)
SELECT b.buyer_segment,
        a.checkout_channel,
        count(distinct a.buyer_id) as total_buyer,
        count(distinct a.order_id) as total_order,
        sum(a.gmv_usd) as total_gmv
FROM order_item_mart a
LEFT JOIN get_buyer_segment b on a.buyer_id = b.order_id
GROUP BY 1, 2
order by 5 desc