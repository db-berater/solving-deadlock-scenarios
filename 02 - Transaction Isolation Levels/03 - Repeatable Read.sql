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

EXEC dbo.sp_create_indexes_customers;
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
	FROM	dbo.customers WITH (REPEATABLEREAD)
	WHERE	c_custkey <= 10;
	GO

	SELECT	request_session_id,
			resource_type,
			resource_description,
			rk.c_custkey,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID, DEFAULT) AS gls
			OUTER APPLY
			(
				SELECT	TOP (1) c_custkey
				FROM	dbo.customers AS i_c
				WHERE	CAST(i_c.%%lockres%% AS NVARCHAR(128)) = gls.resource_description
			) AS rk
	WHERE	resource_associated_entity_id >= 1000000
			AND resource_description <> N'get_locking_status'
	ORDER BY
			sort_order,
			rk.c_custkey;
	GO
ROLLBACK TRANSACTION;
GO

/*
	Before you run this query execute the implementation of an extended event

	RUN:	[97 Extended Events]/[02 - repeatable read locks.sql]

	which covers all locks while the SELECT is running.
	You must change the session_id to the session_id of this tab!
*/
SELECT	/* batch code */
		[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	dbo.customers WITH (REPEATABLEREAD)
WHERE	c_custkey <= 10;
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
	@xevent_name = N'repeatable_read_locks'
	, @filter_batch_only = 1;
GO

/*
	Repeatable Reads can cause Phantom Reads, too!
*/
DROP TABLE IF EXISTS dbo.demo_customers;
GO

CREATE TABLE dbo.demo_customers
(
	c_custkey		BIGINT		NOT NULL PRIMARY KEY CLUSTERED,
	c_name			VARCHAR(64)	NOT NULL,
	c_mktsegment	VARCHAR(64)	NOT NULL
);
GO

/* We insert the TOP 1000 even c_custkey values into the table */
INSERT INTO dbo.demo_customers WITH (TABLOCK)
(c_custkey, c_name, c_mktsegment)
SELECT	c_custkey,
		c_name,
		c_mktsegment
FROM	dbo.customers
WHERE	c_custkey <= 1000
		AND c_custkey % 2 = 0;
GO

BEGIN TRANSACTION
GO
	SELECT	COUNT_BIG(*)
	FROM	dbo.demo_customers WITH (REPEATABLEREAD)
	WHERE	c_custkey <= 10;

	/* Now we insert another row into the table */
	SELECT	COUNT_BIG(*)
	FROM	dbo.demo_customers WITH (REPEATABLEREAD)
	WHERE	c_custkey <= 10;
COMMIT TRANSACTION;
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

DROP TABLE IF EXISTS dbo.demo_customers;
GO
