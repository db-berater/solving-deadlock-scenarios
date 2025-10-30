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
WHERE	c_custkey < = 10000;
GO

ALTER TABLE demo.customers
ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
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
	FROM	demo.customers
	
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
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	demo.customers;
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
	, @filter_condition = N'activity_id >= ''0ABA4573-4E6F-48A2-B435-50CC77C991B4-93''';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO

/*
	Demonstration of phantom reads...
*/
DECLARE	@move_location TABLE
(
	transaction_id	INT				NOT NULL	IDENTITY (1, 1),
	file_id			SMALLINT		NOT NULL,
	page_id			BIGINT			NOT NULL,
	slot_id			SMALLINT		NOT NULL,
	c_custkey		BIGINT			NOT NULL,
	c_name			VARCHAR(25)		NOT NULL
);

INSERT INTO @move_location
(file_id, page_id, slot_id, c_custkey, c_name)
SELECT	pc.file_id,
		pc.page_id,
		pc.slot_id,
		[c_custkey],
		[c_name]
FROM	demo.customers
		CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
WHERE	c_name LIKE 'Uwe%';


/* Now we update Uwe */
UPDATE	demo.customers
SET		c_custkey = 100000
WHERE	c_name LIKE 'Uwe%';

INSERT INTO @move_location
(file_id, page_id, slot_id, c_custkey, c_name)
SELECT	pc.file_id,
		pc.page_id,
		pc.slot_id,
		[c_custkey],
		[c_name]
FROM	demo.customers
		CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
WHERE	c_name LIKE 'Uwe%';

UPDATE	demo.customers
SET		c_custkey = 10
WHERE	c_name LIKE 'Uwe%';

INSERT INTO @move_location
(file_id, page_id, slot_id, c_custkey, c_name)
SELECT	pc.file_id,
		pc.page_id,
		pc.slot_id,
		[c_custkey],
		[c_name]
FROM	demo.customers
		CROSS APPLY sys.fn_PhysLocCracker(%%physloc%%) AS pc
WHERE	c_name LIKE 'Uwe%';

SELECT	transaction_id,
		file_id,
		page_id,
		slot_id,
		c_custkey,
		c_name
FROM	@move_location
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
WHILE @rc <= 2000
BEGIN
	INSERT INTO #record_count([rows])
	SELECT	COUNT_BIG(*)
	FROM	demo.customers;

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
DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA IF EXISTS demo;
GO

EXEC sp_drop_indexes @table_name = N'ALL';
GO