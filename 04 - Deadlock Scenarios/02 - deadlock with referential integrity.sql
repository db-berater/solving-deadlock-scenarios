/*
	============================================================================
	File:		02 - classic deadlock 01.sql

	Summary:	This demo is based on a scenario where referential integrity
				can cause deadlocks

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
	Let's create the necessary indexes on the following tables
	- dbo.customers (c_custkey) and (c_nationkey)
	- dbo.nations (n_nationkey)
*/
EXEC sp_create_indexes_customers;
EXEC sp_create_indexes_nations;
GO

EXEC sp_create_foreign_keys
	@master_table = N'dbo.nations',
	@detail_table = N'dbo.customers',
	@delete_cascade = 0;
GO

/*
	For a better understanding of the locks we add
	- a new nation = 99
	- customer 10 assigned to the new nation
*/
IF NOT EXISTS (SELECT * FROM dbo.nations WHERE n_nationkey = 99)
BEGIN
	BEGIN TRANSACTION;
		INSERT INTO dbo.nations
		(n_nationkey, n_name, n_regionkey)
		VALUES
		(99, 'new country', 1);

		UPDATE	dbo.customers
		SET		c_nationkey = 99
		WHERE	c_custkey = 10;
	COMMIT TRANSACTION
END
GO

/*
	Start the script to create the extended event first
	[97- Extended Events]/02 - read committed locks.sql
*/
BEGIN TRANSACTION
GO
	DELETE	dbo.nations
	WHERE	n_nationkey = 99;

ROLLBACK TRANSACTION;
GO

/*
	Stop the recording by dropping both events for tracking the locks
*/
ALTER EVENT SESSION [read_committed_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_committed_locks'
	, @filter_condition = N'object_name = ''customers'' OR object_name = ''nations''';
GO

/*
	The counterpart for a deadlock situation is in file
	03 - deadlock with referential integrity - counterpart.sql

	Restart the extended event again!
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session read_committed_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO