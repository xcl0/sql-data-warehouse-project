--==========================
--silver.crm_cust_info
--==========================

--Check for Nulls or Duplicates in primary key
--Expectation: No result
select
cst_id,
count(*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1  or cst_id is null


--Check for unwanted space
--Expectation : No results
select
cst_firstname,
cst_key
from silver.crm_cust_info
where cst_firstname <> trim(cst_firstname) or cst_key <> trim(cst_key);

--Data Standardization & Consistency
select distinct cst_gndr
from silver.crm_cust_info

--Inserting into silver layer
insert into silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date)

select
	cst_id,
	cst_key,
	trim(cst_firstname) as cst_firstname,
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_marital_status)) = 'S' then 'Single'
		 when upper(trim(cst_marital_status)) = 'M' then 'Married'
		 else 'n/a'
	end as cst_marital_status,
	case when upper(trim(cst_gndr)) = 'F' then 'Female'
		 when upper(trim(cst_gndr)) = 'M' then 'Male'
		 else 'n/a'
	end as cst_gndr,
	cst_create_date
	from (
		select
		*,
		row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info
		where cst_id is not null
	)t where flag_last = 1;


--========================
--silver.crm_prd_info
--========================

--Check for Nulls or Duplicates in primary key
--Expectation: No result
select
prd_id,
count(*)
from silver.crm_prd_info
group by prd_id
having count(*) > 1  or prd_id is null

--Check for unwanted space
--Expectation : No results
select
prd_nm
from silver.crm_prd_info
where prd_nm <> trim(prd_nm)

--Data Standardization & Consistency
select distinct prd_line
from silver.crm_prd_info

--Check for invalid date orders (end date needs to be more than start date)
select*
from silver.crm_prd_info
where prd_end_dt < prd_start_dt

--Inserting into silver layer
insert into silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
select
prd_id,
replace(substring(prd_key,1,5),'-','_') as cat_id,
substring(prd_key,7,len(prd_key)) as prd_key,
prd_nm,
coalesce(prd_cost,0) as prd_cost,
case when upper(trim(prd_line)) = 'M' then 'Mountain'
	 when upper(trim(prd_line)) = 'R' then 'Road'
	 when upper(trim(prd_line)) = 'S' then 'Other Sales'
	 when upper(trim(prd_line)) = 'T' then 'Touring'
	else 'n/a'
end as prd_line,
cast(prd_start_dt as date) as prd_start_dt,
cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) -1 as date) as prd_end_dt
from bronze.crm_prd_info


--=========================
--silver.crm_sales_detail
--=========================

select*
from bronze.crm_sales_details

--Check for Invalid Dates
select
nullif (sls_due_dt, 0) sls_due_dt
from bronze.crm_sales_details
where sls_due_dt <= 0 or len(sls_due_dt) <> 8 or sls_due_dt < 19000101

--Check for invalid date orders
select*
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

--Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
select
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
case when sls_sales is null or sls_sales <= 0 or sls_sales <> sls_quantity * abs(sls_price)
	then sls_quantity * abs(sls_price)
	else sls_sales
end as sls_sales,
case when sls_price is null or sls_price <= 0
	 then sls_sales / nullif(sls_quantity, 0)
	else sls_price
end as sls_price
from silver.crm_sales_details
where sls_sales <> sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price

--Inserting into silver layer
insert into silver.crm_sales_details (
	sls_ord_num ,
	sls_prd_key ,
	sls_cust_id ,
	sls_order_dt ,
	sls_ship_dt ,
	sls_due_dt ,
	sls_sales ,
	sls_quantity ,
	sls_price
)
select 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
case when sls_order_dt = 0 or len(sls_order_dt) <> 8 then null
		else cast(cast(sls_order_dt as varchar) as date)
end as sls_order_dt,
case when sls_ship_dt = 0 or len(sls_ship_dt) <> 8 then null
		else cast(cast(sls_ship_dt as varchar) as date)
end as sls_ship_dt,
case when sls_due_dt = 0 or len(sls_due_dt) <> 8 then null
		else cast(cast(sls_due_dt as varchar) as date)
end as sls_due_dt,
case when sls_sales is null or sls_sales <= 0 or sls_sales <> sls_quantity * abs(sls_price)
	then sls_quantity * abs(sls_price)
		else sls_sales
end as sls_sales,
	sls_quantity,
case when sls_price is null or sls_price <= 0
	 then sls_sales / nullif(sls_quantity, 0)
		else sls_price
end as sls_price
from bronze.crm_sales_details

select*
from silver.crm_cust_info

--======================
--silver.erp_cust_az12
--======================

select*
from bronze.erp_cust_az12

--Identify Out-of-Range Dates
select distinct
bdate
from bronze.erp_cust_az12
where bdate < '1926-01-01' or bdate > getdate()

--Investigation 1: Check for unwanted spaces (Problem is not ordinary spaces in this case)
select distinct
gen
from bronze.erp_cust_az12
where gen <> trim(gen)

--Investigation 2: Check string lengths
select distinct
    gen,
    len(gen) AS len_value
from bronze.erp_cust_az12;
--Returned excess number of lengths even though they arent spaces, so there should be some hidden characters

--Investigation 3: Identify hidden characters
select
    gen,
    len(gen) AS len_value,
    ascii(RIGHT(gen, 1)) AS last_char_code
from bronze.erp_cust_az12
where len(gen) > len(trim(gen))
   or len(gen) > 1;
--Result: last_char_code = 13
--Meaning: char(13) = Carriage Return (\r)

--Solution
select distinct
gen,
case when upper(trim(replace(gen, char(13), ''))) IN ('F', 'FEMALE') then 'Female'
     when upper(trim(replace(gen, char(13), ''))) IN ('M', 'MALE') then 'Male'
     else 'n/a'
end as cleaned_gen
from bronze.erp_cust_az12;

--Data Standardization & Consistency
select distinct
gen
from bronze.erp_cust_az12

--Inserting into silver layer
insert into silver.erp_cust_az12 (cid, bdate, gen)
select
case when cid like 'NA%' then substring(cid, 4, len(cid))
	 else cid
end cid,
case when bdate > getdate() then null
	else bdate
end as bdate,
case when upper(trim(replace(gen, char(13), ''))) IN ('F', 'FEMALE') then 'Female'
     when upper(trim(replace(gen, char(13), ''))) IN ('M', 'MALE') then 'Male'
     else 'n/a'
end as gen
from bronze.erp_cust_az12

select*
from silver.erp_cust_az12

--=====================
--silver.erp_loc_a101
--=====================

select*
from silver.crm_cust_info

select*
from bronze.erp_loc_a101

--Check string lengths
select distinct
    cntry,
    len(cntry) AS len_value
from bronze.erp_loc_a101;

--Identify hidden characters
select distinct
    cntry,
    len(cntry) AS len_value,
    ascii(RIGHT(cntry, 1)) AS last_char_code
from bronze.erp_loc_a101
where len(cntry) > len(trim(cntry))
   or len(cntry) > 1;

--Data Standardization & Consistency
select distinct
cntry as old_cntry,
case when trim(replace(cntry, char(13), '')) = 'DE' then 'Germany'
     when trim(replace(cntry, char(13), '')) in ('US', 'USA') then 'United States'
     when trim(replace(cntry, char(13), '')) = '' or cntry is null then 'n/a'
     else trim(replace(cntry, char(13), ''))
end as cntry
from bronze.erp_loc_a101

--Inserting into silver layer
insert into silver.erp_loc_a101
(cid, cntry)
select
replace(cid, '-', '') as cid,
case when trim(replace(cntry, char(13), '')) = 'DE' then 'Germany'
     when trim(replace(cntry, char(13), '')) in ('US', 'USA') then 'United States'
     when trim(replace(cntry, char(13), '')) = '' or cntry is null then 'n/a'
     else trim(replace(cntry, char(13), ''))
end as cntry
from bronze.erp_loc_a101 

--=======================
--silver.erp_px_cat_g1v2
--=======================

--Check for unwanted Spaces
select*
from bronze.erp_px_cat_g1v2
where cat <> trim(cat) or subcat <> trim(subcat) or maintenance <> trim(maintenance)

--Data Standardization & Consistency
select distinct
cat
from bronze.erp_px_cat_g1v2

select distinct
subcat
from bronze.erp_px_cat_g1v2

select distinct
maintenance
from bronze.erp_px_cat_g1v2

--Inserting into silver layer
insert into silver.erp_px_cat_g1v2
(id, cat, subcat, maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2


