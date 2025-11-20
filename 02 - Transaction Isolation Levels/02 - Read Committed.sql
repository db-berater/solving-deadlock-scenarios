/*
	============================================================================
	File:		02 - Read Committed.sql

	Summary:	demonstration of Read Committed isolation level
				
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

/* Let's create necessary indexes on dbo.customers for the demos */
EXEC dbo.sp_deactivate_query_store;
EXEC sp_create_indexes_customers;
GO

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
	FROM	dbo.customers
	WHERE	c_custkey <= 1000;
	
	SELECT	request_session_id,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID, DEFAULT)
	WHERE	resource_associated_entity_id >= 1000000
			AND resource_description <> N'get_locking_status';
	GO
COMMIT TRANSACTION;
GO

/*
	Before you run this query execute the implementation of an extended event

	RUN:	[97 Extended Events]/[02 - read committed locks.sql]

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
FROM	dbo.customers
WHERE	c_custkey <= 1000
OPTION	(MAXDOP 1);
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

/*
	The isolation level READ COMMITTED can cause phantom reads.

	Phantom reads occur in database systems when a transaction
	reads a set of rows that satisfy a condition, and then—before 
	the transaction completes—another transaction inserts or deletes 
	rows that also satisfy that condition.

*/
BEGIN
	DROP TABLE IF EXISTS #move_location;

	CREATE TABLE #move_location
	(
		transaction_id	INT				NOT NULL	IDENTITY (1, 1),
		file_id			SMALLINT		NOT NULL,
		page_id			BIGINT			NOT NULL,
		slot_id			SMALLINT		NOT NULL,
		c_custkey		BIGINT			NOT NULL,
		c_name			VARCHAR(25)		NOT NULL
	);

	INSERT INTO #move_location
	(file_id, page_id, slot_id, c_custkey, c_name)
	SELECT	pc.file_id,
			pc.page_id,
			pc.slot_id,
			[c_custkey],
			[c_name]
	FROM	dbo.customers
			CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
	WHERE	c_custkey = 10;


	/* Now we update Uwe */
	UPDATE	dbo.customers
	SET		c_custkey = 2000000
	WHERE	c_custkey = 10;

	INSERT INTO #move_location
	(file_id, page_id, slot_id, c_custkey, c_name)
	SELECT	pc.file_id,
			pc.page_id,
			pc.slot_id,
			[c_custkey],
			[c_name]
	FROM	dbo.customers
			CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
	WHERE	c_custkey = 2000000;

	UPDATE	dbo.customers
	SET		c_custkey = 10
	WHERE	c_custkey = 2000000;

	INSERT INTO #move_location
	(file_id, page_id, slot_id, c_custkey, c_name)
	SELECT	pc.file_id,
			pc.page_id,
			pc.slot_id,
			[c_custkey],
			[c_name]
	FROM	dbo.customers
			CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
	WHERE	c_custkey = 10;

	SELECT	transaction_id,
			file_id,
			page_id,
			slot_id,
			c_custkey,
			c_name
	FROM	#move_location;
END
GO

/*
	Now we run the flip flop of record 10 in a separate transaction
	for 5000 times in SQLQueryStress.

	- Start SQLQueryStress
	- Load the template [98 - Query Stress]/01 - phantom reads.json into SQLQueryStress
	  and execute the batch.
	- When it runs come back and run the next statement
*/
DROP TABLE IF EXISTS #record_count;
GO

CREATE TABLE #record_count ([rows] BIGINT NOT NULL);
GO

DECLARE	@rc INT = 1;
WHILE @rc <= 200
BEGIN
	INSERT INTO #record_count([rows])
	SELECT	COUNT_BIG(*)
	FROM	dbo.customers;

	SET	@rc += 1;
END
GO

SELECT	[rows],
		COUNT_BIG(*)
FROM	#record_count
GROUP BY
		[rows]
ORDER BY
		[rows];
GO

/*
	Clean the environment!
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO

DROP TABLE IF EXISTS #record_count;
DROP SCHEMA IF EXISTS demo;
GO