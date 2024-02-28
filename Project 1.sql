-- ANALYZING TRAFFIC SOURCES --


-- Traffic sources and traffic source conversion rates :

select
	utm_source,
	utm_campaign,
    http_referer,
    (count(distinct o.order_id)/count(distinct w.website_session_id))*100 as CVR
from website_sessions as w left join orders as o on w.website_session_id = o.website_session_id 
where w.created_at < '2012-04-14' 
group by utm_source,
	utm_campaign,
	http_referer
order by CVR desc;

-- Gsearch volume trends :

select * from website_sessions;
select
	min(date(created_at)) as week_start_date,
	count(website_session_id)
from website_sessions
where utm_source = 'gsearch' and 
	utm_campaign = 'nonbrand' and
	created_at < '2012-05-10'
group by week(created_at);

-- Gsearch device level performance :

select 
	device_type,
    count(distinct w.website_session_id) as sessions,
    count(distinct o.order_id) as orders,
    (count(distinct o.order_id)/count(distinct w.website_session_id)) as session_to_order_conv_rate
from website_sessions as w left join orders as o on w.website_session_id = o.website_session_id
where w.created_at < '2012-05-11' and
	utm_source = 'gsearch' and
    utm_campaign = 'nonbrand'
group by 1
order by 2 desc;

-- Gsearch device level trends : (Pivot Table)

select 
	min(date(created_At)) as week_start_date,
	count(distinct case when device_type = 'desktop' then website_session_id else null end) as dtop_sessions,
    count(distinct case when device_type = 'mobile' then website_session_id else null end) as mob_sessions
from website_sessions
where created_at < '2012-06-09'and
	 created_at > '2012-04-15' and
     utm_source = 'gsearch' and
     utm_campaign = 'nonbrand'
group by week(created_at);


-- ANALYZING WEBSITE PERFORMANCE --


-- Analyzing top website pages & entry pages :

create temporary table first_pageview
select 
	website_session_id,
    min(website_pageview_id) as min_pv_id
from website_pageviews
group by website_session_id;

select 
	website_pageviews.pageview_url as landing_page, 
    count(distinct first_pageview.website_Session_id) as sessions_hitting_this_lander
from first_pageview
	left join website_pageviews
    on first_pageview.min_pv_id = website_pageviews.website_pageview_id
group by
	website_pageviews.pageview_url
    order by 2 desc;

-- Top website pages :

select 
	pageview_url,
    count(distinct website_pageview_id) as sessions
from website_pageviews
where created_At < '2012-06-09'
group by pageview_url
order by 2 desc;

-- Top entry pages :

create temporary table x
select
	website_session_id,
    min(website_pageview_id) as p
from website_pageviews
where created_At < '2012-06-12'
group by 1;

select
	y.pageview_url,
    count(x.website_Session_id) as sessions_hitting_this_landing_page
from x left join website_pageviews as y on x.p = y.website_pageview_id
where y.created_At < '2012-06-12'
group by y.pageview_url
order by 2;

-- Bounce rate analysis :

create temporary table a
select 
	website_session_id,
    min(website_pageview_id) as min
from website_pageviews
where created_At < '2012-06-14'
group by website_session_id;

create temporary table b
select 
	website_pageviews.pageview_url,
    a.website_session_id
from a left join website_pageviews on a.min = website_pageviews.website_pageview_id
where created_At < '2012-06-14';

select * from b;	

create temporary table c
select 
    b.website_session_id,
    b.pageview_url,
    count(website_pageviews.website_pageview_id) as bs
from b left join website_pageviews on b.website_session_id = website_pageviews.website_Session_id
where created_At < '2012-06-14'
group by b.website_Session_id, b.pageview_url
having bs = 1;

select * from c;

select
	count(distinct b.website_session_id) as sessions,
    count(c.bs) as bounced_Sessions,
    count(c.bs)/count(distinct b.website_session_id) as bounce_rate
from b left join c on b.website_session_id = c.website_Session_id
group by b.pageview_url;

-- Help analyzing LP test :

select 
	pageview_url,
    created_At
from website_pageviews
where pageview_url = '/lander-1'
order by created_at asc;

		-- /Timeline for comparision : 2012-06-19 to 2012-07-28/ --

create temporary table d
select 
	website_pageviews.website_Session_id,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews join website_Sessions on website_pageviews.website_Session_id = website_Sessions.website_Session_id
where website_Sessions.created_at between '2012-06-19' and '2012-07-28'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by website_pageviews.website_Session_id;

create temporary table e 
select 
	website_pageviews.pageview_url as landing_page,
    d.website_session_id as ss
from d left join website_pageviews on d.website_session_id = website_pageviews.website_session_id
where pageview_url = '/home' or 
pageview_url = '/lander-1';

select * from e;

create temporary table f
select 
	e.landing_page,
	e.ss,
    count(website_pageviews.website_pageview_id) as cc
from e left join website_pageviews on e.ss = website_pageviews.website_Session_id 
group by e.ss, e.landing_page 
having cc = 1;

select * from f;

select 
	e.landing_page,
    count(e.ss) as total_Sessions,
    count(f.ss) as bounced_Sessions,
    count(f.ss)/count(e.ss) as bounce_rate
from e left join f on e.ss = f.ss
group by e.landing_page ;

-- Landing page trend analysis --

select 
	utm_Source,
    utm_campaign
from website_sessions
group by utm_source, utm_campaign ;

create temporary table g
select 
	website_Sessions.created_At,
	website_pageviews.website_session_id,
    min(website_pageview_id)
from website_pageviews join website_sessions on website_pageviews.website_Session_id = website_sessions.website_session_id
where website_Sessions.created_At between '2012-06-01' and '2012-08-31'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by website_pageviews.website_session_id;

select * from g;

create temporary table h
select
	g.created_At,
	website_pageviews.pageview_url,
    g.website_Session_id
from g left join website_pageviews on g.website_Session_id = website_pageviews.website_Session_id 
where pageview_url in ('/home', '/lander-1');

select * from h;

create temporary table j
select
	min(date(h.created_At)) as wsd1,
    count(h.website_Session_id) as c1
from h
group by week(h.created_At);

select * from j;

create temporary table l
select
	min(date(h.created_At)) as wsd4,
    count(h.website_Session_id) as hs
from h
where h.pageview_url = '/home'
group by week(h.created_At);

select * from l;

create temporary table m
select
	min(date(h.created_At)) as wsd5,
    count(h.website_Session_id) as ls
from h
where h.pageview_url = '/lander-1'
group by week(h.created_At);

select * from m;

create temporary table n
select 
	min(date(h.created_At)) as week_start_date
from h
group by week(created_At);

select * from n;

create temporary table o
select
	n.week_start_date,
    m.ls
from n left join m on n.week_Start_date = m.wsd5;

select * from o;
    
create temporary table i
select 
	h.created_At,
    h.pageview_url,
    h.website_Session_id,
    count(website_pageviews.website_pageview_id) as c
from h left join website_pageviews on h.website_Session_id = website_pageviews.website_Session_id
group by h.website_Session_id, h.pageview_url,h.created_At
having  c=1;

select * from i;

create temporary table k
select
	min(date(i.created_At)) as wsd2,
    count(i.website_session_id) as c2
from i
group by week(i.created_at);

select * from k;

  -- Half output done --
select 
	j.wsd1 as week_start_date,
    k.c2/j.c1 as bounce_rate,
    l.hs as home_sessions,
    ifnull(o.ls, 0) as lander_sessions
from j join k on j.wsd1 = k.wsd2
join l on l.wsd4 = k.wsd2
left join o on o.week_start_date = l.wsd4 
order by 1;


-- Building conversion funnels --


create temporary table a
select 
	website_session_id,
    max(products_page) as products_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(thankyou_page) as thankyou
from
(
select 
	website_sessions.website_Session_id,
    website_pageviews.pageview_url,
    case when pageview_url = '/lander-1' then 1 else 0 end as lander1_page,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_Sessions left join website_pageviews on website_Sessions.website_session_id = website_pageviews.website_Session_id
where website_Sessions.created_At > '2012-08-05'
and website_Sessions.created_At < '2012-09-05'
and utm_source = 'gsearch'
and website_pageviews.pageview_url in ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
group by website_sessions.website_Session_id, website_pageviews.pageview_url
) as pageview_level
group by website_session_id ;

select * from a;

select 
	count(website_Session_id),
    count(distinct case when products_made_it = 1 then website_Session_id else null end)/count(website_Session_id) as to_products ,
    count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end)/count(distinct case when products_made_it = 1 then website_Session_id else null end) as to_mrfuzzy,
    count(distinct case when cart_made_it = 1 then website_session_id else null end)/count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_cart,
    count(distinct case when shipping_made_it = 1 then website_session_id else null end)/count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when billing_made_it = 1 then website_session_id else null end)/count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_billing,
    count(distinct case when thankyou = 1 then website_session_id else null end)/count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_thankyou
from a ; 


-- Analyzing conversion funnel tests --


select 
	created_at,
	website_Session_id,
    pageview_url 
from website_pageviews
where pageview_url in ('/billing-2') ;

-- Date timeline : '2012-09-10' to '2012-11-10' and 1st session of billing 2 : 25325 --

create temporary table a
select
	website_Session_id,
    max(billing_page) as billing_done,
    max(billing_2_page) as billing_2_done,
    max(orders) as orders_placed
from
(
select 
	created_at,
	website_session_id,
    pageview_url,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/billing-2' then 1 else 0 end as billing_2_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as orders
from website_pageviews 
where created_at between '2012-09-10' and '2012-11-10'
group by created_at, website_session_id, pageview_url  
order by website_session_id 
) as a
group by website_session_id ;

select * from a;

select 
    count(distinct case when billing_done = 1 then website_Session_id else null end) as billing_sessions,
    count(distinct case when orders_placed = 1 and billing_done = 1 then website_Session_id else null end) as orders_billing,
    count(distinct case when orders_placed = 1 and billing_done = 1 then website_Session_id else null end)/count(distinct case when billing_done = 1 then website_Session_id else null end) as ratio_1,
    count(distinct case when billing_2_done = 1 then website_Session_id else null end) as billing_2_sessions,
    count(distinct case when orders_placed = 1 and billing_2_done = 1 then website_Session_id else null end) as orders_billing_2,
    count(distinct case when orders_placed = 1 and billing_2_done = 1 then website_Session_id else null end)/count(distinct case when billing_2_done = 1 then website_Session_id else null end) as ratio_2
from a ;
    

-- PROJECT 1 --


-- 1 : Monthly trends for gsearch sessions and orders --

create temporary table a
select
	date_format(website_sessions.created_At, '%M %Y') as Dates,
    count(website_sessions.website_session_id) Sessions_gsearch
from website_sessions
where utm_source = 'gsearch'
and website_sessions.created_at < '2012-11-27'
group by date_format(website_sessions.created_At, '%M %Y') ;

select * from a;

create temporary table b
select
	date_format(website_sessions.created_At, '%M %Y') as Dates_2,
    count(order_id) as Orders
from website_sessions left join orders on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
and website_sessions.created_at < '2012-11-27'
group by date_format(website_sessions.created_At, '%M %Y') ;

select * from b;    

select 
	a.dates as 'Date',
	a.sessions_gsearch as 'Total sessions of gsearch',	
    b.orders as 'Monthly orders',
    b.orders/a.sessions_gsearch as 'Conversion rate'
from a join b on a.dates = b.dates_2 ;

-- 2 : Monthly trends for gsearch sessions and orders but this time splitting out brand and nonbrand campaign separately --

select utm_source, utm_campaign from website_Sessions  where utm_source = 'gsearch' group by utm_Source, utm_campaign ;

select 
	date_format(website_sessions.created_at, '%M %Y') as Dates,
    website_Sessions.utm_source as Source,
    utm_campaign as Campaign_type,
    count(website_sessions.website_session_id) as Sessions,
    count(order_id) as Orders,
    count(order_id)/count(website_sessions.website_session_id) as 'Concersion rate'
from website_sessions left join orders on website_Sessions.website_session_id = orders.website_Session_id
where utm_source = 'gsearch'
and website_sessions.created_at < '2012-11-27'
group by date_format(website_sessions.created_at, '%M %Y'), utm_campaign ;

-- 3 : gsearch & nonbrand monthly sessions and orders split by device type used --

select
	date_format(website_sessions.created_at, '%M %Y') as 'Date',
	website_Sessions.device_type as 'Device used',
	count(website_sessions.website_Session_id) as Session_count,
    count(order_id) as Order_count,
    count(order_id)/count(website_sessions.website_Session_id) as 'Conversion rate'
from website_Sessions left join orders on website_Sessions.website_session_id = orders.website_Session_id
where utm_Source = 'gsearch'
and utm_campaign = 'nonbrand'
and website_sessions.created_at < '2012-11-27'
group by date_format(website_sessions.created_at, '%M %Y'), website_Sessions.device_type ; 
  
-- 4 : Monthly trends for gsearch alongside monthly trends from other channels --

select utm_source from website_Sessions group by 1 ;

select
	date_format(website_sessions.created_at, '%M %Y') as 'Date',
    website_Sessions.utm_source as Source,
    count(website_sessions.website_Session_id) as Session_count,
    count(order_id) as Order_count,
    count(order_id)/count(website_sessions.website_Session_id) as 'Conversion rate'
from website_Sessions left join orders on website_Sessions.website_session_id = orders.website_Session_id
where website_sessions.created_at < '2012-11-27'
group by 1, 2 ;

-- 5 : First 8 months session to order conversion rates --

select 
	date_format(website_sessions.created_at, '%M %Y') as 'Date',
    count(website_sessions.website_session_id) as 'Total sessions',
    count(order_id) as 'Total orders',
    count(order_id)/count(website_sessions.website_session_id) as 'Session to order conversion rate'
from website_sessions left join orders on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1 ;

-- 6 : For the gsearch lander test, estimating the revenue that test has earned us. Also looking at the increase in CVR from the test and using non brand sessions and revenue since then to calculate incremental value --

select 
	min(website_pageviews.website_pageview_id)
from website_pageviews
where pageview_url = '/lander-1' ;

create temporary table a1
select 
	website_pageviews.website_session_id as sessions,
    min(website_pageviews.website_pageview_id) as min_id
from website_pageviews join website_sessions on website_Sessions.website_session_id = website_pageviews.website_session_id
where website_pageviews.website_pageview_id >= 23504
and website_Sessions.created_At < '2012-11-27'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand' 
group by 1 ;

select * from a1;

create temporary table a2
select
	a1.sessions as sessions,
    pageview_url
from a1 left join website_pageviews on a1.min_id = website_pageviews.website_pageview_id
where pageview_url in ('/home','/lander-1')
and website_pageviews.created_At < '2012-11-27' ;

select * from a2 ;

create temporary table a3
select 
	a2.sessions as Sessions,
    a2.pageview_url as Url,
    orders.order_id as Order_id
from a2 left join orders on a2.sessions = orders.website_session_id ;

select * from a3 ;

select 
	a3.url as 'Landing page',
    count(distinct a3.sessions) as Sessions,
    count(distinct a3.order_id) as Orders,
    count(distinct a3.order_id)/count(distinct a3.sessions) as CVR
from a3
group by a3.url ;

		-- .0322 for /home vs .0405 for /lander-1
		-- .0083 additional orders per session

select 
	max(website_sessions.website_session_id)
from website_sessions left join website_pageviews on website_pageviews.website_Session_id = website_sessions.website_Session_id
where utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
and pageview_url = '/home'
and website_Sessions.created_At < '2012-11-27' ;

		-- Max website session_id = 17145

select 
	count(website_Session_id) as sessions_since_test
from website_Sessions
where created_At < '2012-11-27'
and website_Session_id > 17145
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand' ;

		-- 22,792 website sessions since the test
		-- .0083 incremental conversion = 202 orders sicne 7/29
		-- Roughly 4 months, so around 50 extra orders per month

-- 7 : Full conversion funnel for both the landing pages (/home & /lander-1) to orders --

select pageview_url from website_pageviews group by pageview_url ;

create temporary table a
select 
	website_session_id,
    max(home_page) as home_page,
    max(lander1_page) as lander1_page,
    max(products_page) as products_made_it,
    max(mrfuzzy_page) as mrfuzzy_made_it,
    max(cart_page) as cart_made_it,
    max(shipping_page) as shipping_made_it,
    max(billing_page) as billing_made_it,
    max(thankyou_page) as thankyou
from
(
select 
	website_sessions.website_Session_id,
    website_pageviews.pageview_url,
    case when pageview_url = '/home' then 1 else 0 end as home_page,
    case when pageview_url = '/lander-1' then 1 else 0 end as lander1_page,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_Sessions left join website_pageviews on website_Sessions.website_session_id = website_pageviews.website_Session_id
where website_Sessions.created_At > '2012-06-19'
and website_Sessions.created_At < '2012-07-28'
and website_Sessions.utm_source = 'gsearch'
and website_Sessions.utm_campaign = 'nonbrand'
and website_pageviews.pageview_url in ('/home', '/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
group by website_sessions.website_Session_id, website_pageviews.pageview_url
order by website_Sessions.website_session_id
) as pageview_level
group by website_Session_id ;

select * from a ;

select 
	website_pageviews.pageview_url,
	count(distinct case when home_page = 1 then a.website_Session_id else null end) as home_page,
    count(distinct case when lander1_page = 1 then a.website_Session_id else null end) as lander1_page,
    count(distinct case when products_made_it = 1 then a.website_Session_id else null end) as products,
    count(distinct case when mrfuzzy_made_it = 1 then a.website_Session_id else null end) as mrfuzzy,
    count(distinct case when cart_made_it = 1 then a.website_Session_id else null end) as cart,
    count(distinct case when shipping_made_it = 1 then a.website_Session_id else null end) as shipping,
    count(distinct case when billing_made_it = 1 then a.website_Session_id else null end) as billing,
    count(distinct case when thankyou = 1 then a.website_Session_id else null end) as thankyou
from a left join website_pageviews on a.website_session_id = website_pageviews.website_session_id
where website_pageviews.pageview_url in ('/home', '/lander-1')
group by 1 ;

-- 8 : Quantifying impact of billing test, lift generated from test b/w SEP 10 to NOV 10 in terms of revenue per billing session and then showing number of billing page sessions for the past month to understand monthly impact -- 

create temporary table x
select
	session_id,
    url,
    max(billing) as billing,
    max(billing_2) as billing_2
from
(
select
	website_sessions.website_session_id as Session_id,
    website_pageviews.pageview_url as Url,
    case when pageview_url = '/billing' then 1 else 0 end as Billing,
    case when pageview_url = '/billing-2' then 1 else 0 end as Billing_2
from website_sessions join website_pageviews on website_sessions.website_session_id = website_pageviews.website_session_id
where pageview_url in ('/billing', '/billing-2')
and website_sessions.created_at between '2012-09-10' and '2012-11-10' 
) as x
group by session_id, url 
order by session_id ;

select * from x;

create temporary table y
select
	url as Segment,
	count(distinct case when billing = 1 then session_id else null end) as 'Billing sessions',
    count(distinct case when billing_2 = 1 then session_id else null end) as 'Billing_2 sessions',
    sum(orders.price_usd) as Amount
from x left join orders on x.session_id = orders.website_Session_id
group by url ;

select * from y;

select
	14997/657
from y ;

select 
	20495.90/654
from y ;

-- Billing sessions - 657, Total amount in billing sessions - $ 14997, Amount/Billing sessions - $ 22.83
-- Billing-2 sessions -  654, Total amount in billing-2 sessions - $ 20495.90, Amount/billing-2 sessions - $ 31.34
-- Lift for new version (Billing-2) - $ 8.51

select
	count(website_session_id) as Sessions_since_past_month
from website_pageviews 
where created_At between '2012-10-27' and '2012-11-27'
and pageview_url in ('/billing', '/billing-2') ;

-- 1193 sessions past month that hits the Billing or Billing-2 page
-- Lift - $ 8.51 per billing session
-- Value of billing test lift - $ 10,152.43 over past month
 

	


    

        



    







    







    
	

















    


	
	
	



















    







