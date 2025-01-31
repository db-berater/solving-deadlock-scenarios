/*
	============================================================================
	File:		01 - classic deadlock 01.sql

	Summary:	This demo is based on a typical scenario of different call stacks
				from two concurrent processes accessing the same resources.

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

/*
	Before the demonstration implement the extended event to record deadlocks
	in the ERP_Demo database!

	[97 - extended events]/04 - deadlock recordings.sql
*/

/*
	Session 1:	Update auf dbo.customers
*/
BEGIN TRANSACTION update_customers;
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe Ricken'
	WHERE	c_custkey = 10;
	GO

	/* What locks do we have on objects with this session? */
	SELECT	resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status,
			blocking_session_id
	FROM	dbo.get_locking_status(@@SPID)
	WHERE	resource_description = N'customers'
			OR object_name = N'[dbo].[customers]'
	ORDER BY
			sort_order;
	GO

	/* After the second transaction has started we process with the next step */
	UPDATE	dbo.nations
	SET		n_name = 'Singapore'
	WHERE	n_nationkey = 2;
ROLLBACK TRANSACTION update_customers;
GO

/*
	Session 2:	Update auf dbo.nations
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

BEGIN TRANSACTION update_customers;
GO
	UPDATE	dbo.nations
	SET		n_name = 'Great Britain'
	WHERE	n_nationkey = 2
	OPTION	(MAXDOP 1);
	GO

	/* After the second transaction has started we process with the next step */
	UPDATE	dbo.customers
	SET		c_name = 'db Berater GmbH'
	WHERE	c_custkey = 10;
ROLLBACK TRANSACTION update_customers;
GO