/*

=====================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
=====================================================================

Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions:
  - Truncates the bronze tables before loading data.
  - Uses the 'bulk insert' command to load data from CSV files to bronze tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  exec bronze.load_bronze;
=====================================================================
*/

--Transfering data from data source
create or alter procedure bronze.load_bronze as
begin
print '=============================================';
print 'Loading Bronze Layer';
print '=============================================';

print '---------------------------------------------';
print 'Loading CRM Tables';
print '---------------------------------------------';

print '>> Truncting Table: bronze.crm_cust_info';
truncate table bronze.crm_cust_info;
print '>> Inserting Data Into: bronze.crm_cust_info';
bulk insert bronze.crm_cust_info
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
    rowterminator = '0x0a',
    tablock
);

print '>> Truncting Table: bronze.crm_prd_info';
truncate table bronze.crm_prd_info;
print '>> Inserting Data Into: bronze.crm_prd_info';
bulk insert bronze.crm_prd_info
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
    rowterminator = '0x0a',
    tablock
);

print '>> Truncting Table:bronze.crm_sales_details';
truncate table bronze.crm_sales_details;
print '>> Inserting Data Into: bronze.crm_sales_details';
bulk insert bronze.crm_sales_details
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
	rowterminator = '0x0a',
    tablock
);

print '---------------------------------------------';
print 'Loading ERP Tables';
print '---------------------------------------------';

print '>> Truncting Table:bronze.erp_cust_az12';
truncate table bronze.erp_cust_az12;
print '>> Inserting Data Into: bronze.erp_cust_az12';
bulk insert bronze.erp_cust_az12
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_erp\cust_az12.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
	rowterminator = '0x0a',
    tablock
);

print '>> Truncting Table:bronze.erp_loc_a101';
truncate table bronze.erp_loc_a101;
print '>> Inserting Data Into: bronze.erp_loc_a101';
bulk insert bronze.erp_loc_a101
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_erp\loc_a101.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
	rowterminator = '0x0a',
    tablock
);

print '>> Truncting Table:bronze.erp_px_cat_g1v2';
truncate table bronze.erp_px_cat_g1v2;
print '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
bulk insert bronze.erp_px_cat_g1v2
from 'C:\SQL2025\sql-data-warehouse-project-main\datasets\source_erp\px_cat_g1v2.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
	rowterminator = '0x0a',
    tablock
);
end
