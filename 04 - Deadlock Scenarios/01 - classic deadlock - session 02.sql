/*
	============================================================================
	File:		01 - classic deadlock - session 02.sql

	Summary:	This demo is based on a typical scenario of different call stacks
				from two concurrent processes accessing the same resources.

				This script is for the SECOND session which gets in concurrency
				with 01 - classic deadlock - session 01.sql

				THIS SCRIPT IS PART OF THE TRACK:
					Session: Solving Deadlock Scenarios

	Date:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/

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

	/* What locks do we have on objects with this session? */
	;WITH l
	AS
	(
		SELECT	DISTINCT
				request_session_id,
				resource_type,
				resource_description,
				request_mode,
				request_type,
				request_status,
				sort_order
		FROM	dbo.get_locking_status(@@SPID)
		WHERE	resource_description <> N'get_locking_status'
				AND resource_associated_entity_id > 100
	)
	SELECT	request_session_id,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	l
	ORDER BY
			request_session_id,
			sort_order;
	GO

	/*
		Now go back to the 01 - classic deadlock - session 01.sql to process
		the next step
	*/
	
	UPDATE	dbo.customers
	SET		c_name = 'db Berater GmbH'
	WHERE	c_custkey = 10;
ROLLBACK TRANSACTION update_customers;
GO