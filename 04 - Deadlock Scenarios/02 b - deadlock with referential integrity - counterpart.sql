/*
	============================================================================
	File:		03 - deadlock with referential integrity - counterpart.sql

	Summary:	This demo script is part of the script 02... sql

				THIS SCRIPT IS PART OF THE TRACK:
					Session: Solving Deadlock Scenarios

	Date:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

BEGIN TRANSACTION update_customer
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe',
			c_nationkey = 6
	WHERE	c_custkey = 10;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(NULL, DEFAULT)
	WHERE	object_name = N'[dbo].[customers]'
	ORDER BY
			request_session_id,
			object_name,
			sort_order;

	/*
		Now switch over to the session 02a and execute the
		second statement!
	*/

	SELECT	%%lockres%%,
			n_nationkey,
            n_name,
            n_regionkey,
            n_comment
	FROM	dbo.nations
	WHERE	n_nationkey = 99;
	GO

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(NULL, DEFAULT)
	WHERE	resource_description NOT LIKE N'sys%'
			AND resource_description <> N'get_locking_status'
	ORDER BY
			request_session_id,
			object_name,
			sort_order;
ROLLBACK TRANSACTION
GO