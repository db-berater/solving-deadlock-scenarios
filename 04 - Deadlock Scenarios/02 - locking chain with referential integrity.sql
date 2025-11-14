/*
	============================================================================
	File:		02 - locking chain with referential integrity.sql

	Summary:	This demo shows the locking chain when referential integrity
				is implemented!

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
	First we implement the referential integrity between the following tables:
	- dbo.customers
	- dbo.nations
*/
EXEC dbo.sp_create_indexes_customers;
EXEC dbo.sp_create_indexes_nations;
EXEC dbo.sp_create_foreign_keys
	@master_table = N'dbo.nations',
	@detail_table = N'dbo.customers';
GO

/*
	Before you start this demo, implement the extended event 
	./97 - extended events/02 - read committed locks.sql
*/
BEGIN TRANSACTION
GO
	/* batch code */
	UPDATE	dbo.customers
	SET		c_nationkey = 6
	WHERE	c_custkey = 10;
	GO

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
	, @filter_batch_only = 1;
GO
