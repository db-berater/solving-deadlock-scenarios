/*
	============================================================================
	File:		02 - Repeatable Read.sql

	Summary:	demonstration of Repeatable Read isolation level
				
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

IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [demo] AUTHORIZATION dbo;'
	GO

DROP TABLE IF EXISTS demo.customers;
GO

SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
INTO	demo.customers
FROM	dbo.customers
WHERE	c_custkey < = 50000;
GO

ALTER TABLE demo.customers
ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/*
	What resource are locked when we SELECT data from the table?
*/
BEGIN TRANSACTION;
GO
	SELECT	[c_custkey],
			[c_mktsegment],
			[c_nationkey],
			[c_name],
			[c_address],
			[c_phone],
			[c_acctbal],
			[c_comment]
	FROM	demo.customers WITH (REPEATABLEREAD)
	WHERE	c_custkey <= 20;

	SELECT	request_session_id,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID)
	WHERE	resource_associated_entity_id >= 1000000
			AND resource_description <> N'get_locking_status'
	ORDER BY
			sort_order;
	GO
ROLLBACK TRANSACTION;
GO

/*
	Before you run this query execute the implementation of an extended event

	RUN:	[97 Extended Events]/[02 - repeatable read locks.sql]

	which covers all locks while the SELECT is running.
	You must change the session_id to the session_id of this tab!
*/
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers WITH (REPEATABLEREAD)
WHERE	c_custkey <= 50;
GO

/*
	Stop the recording by dropping both events for tracking the locks
*/
ALTER EVENT SESSION [repeatable_read_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'repeatable_read_locks';
GO

/*
	Clean the enviroment
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'repeatable_read_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [repeatable_read_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [repeatable_read_locks] ON SERVER;
END
GO

EXEC sp_drop_indexes @table_name = N'ALL';
DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA IF EXISTS demo;
GO
