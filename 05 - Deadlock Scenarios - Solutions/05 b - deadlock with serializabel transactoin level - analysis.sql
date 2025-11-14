/*
	============================================================================
	File:		05 b - deadlock with serializable transaction level - analysis.sql

	Summary:	The script dives into the problems with the transaction isolation
				level SERIALIZABLE and deadlocks

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

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO

BEGIN TRANSACTION
GO
	/* Execute the SELECT and check the locks on dbo.demo_table */
	SELECT * FROM dbo.demo_table WHERE c_custkey = 56;
	GO

	/* Run in 05 a the INSERT Statment and check afterwards the locks */

	SELECT	gls.object_name,
			gls.index_name,
			gls.resource_type,
			gls.resource_description,
			lk.c_custkey,
			gls.request_mode,
			gls.request_type,
			gls.request_status
	FROM	dbo.get_locking_status(NULL, DEFAULT) gls
			OUTER APPLY
			(
				SELECT	c_custkey
				FROM	dbo.demo_table
				WHERE	%%lockres%% = gls.resource_description
			) AS lk
	WHERE	request_status <> N'GRANT'
	ORDER BY
			request_session_id,
			sort_order;

	/* and we try to insert the records with c_custkey = 56 */
	INSERT INTO dbo.demo_table (c_custkey, c_name, c_mktsegment)
	VALUES (56, 'Uwe', 'IT Service');


/* Clean the kitchen */
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'serializable_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [serializable_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [serializable_locks] ON SERVER;
END
GO