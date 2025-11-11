/*
	============================================================================
	File:		04 - Serializable Read.sql

	Summary:	demonstration of Serializable Read isolation level
				
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

/*
	We create a table with EVEN key attributes (2, 4, ...)
*/
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
WHERE	c_custkey < = 100
		AND c_custkey % 2 = 0;
GO

ALTER TABLE demo.customers
ADD CONSTRAINT pk_demo_customers PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
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
	FROM	demo.customers WITH (SERIALIZABLE)
	WHERE	c_custkey BETWEEN 6 AND 10;
	GO

	;WITH l
	AS
	(
		SELECT	%%lockres%%		AS	resource_description,
				c_custkey
		FROM	demo.customers WITH (READCOMMITTED)
	)
	SELECT	gls.request_session_id,
			gls.resource_type,
			gls.resource_description,
			gls.request_mode,
			gls.request_type,
			gls.request_status,
			CASE WHEN l.c_custkey IS NULL
				 THEN 0
				 ELSE l.c_custkey
			END						AS	c_custkey
	FROM	dbo.get_locking_status(@@SPID, DEFAULT) AS gls
			LEFT JOIN l
			ON (gls.resource_description = l.resource_description)
	WHERE	gls.resource_associated_entity_id >= 1000000
			AND gls.resource_description <> N'get_locking_status'
	ORDER BY
			c_custkey;
COMMIT TRANSACTION;
GO

/*
	To see the locking hierarchy in the serializable transaction level
	execute the extended event monitoring for read committed locks
	./97 - Extended Events/04 - serializable locks.sql
*/
SELECT	/* batch code */
		c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	demo.customers WITH (SERIALIZABLE)
WHERE	c_custkey = 10;
GO

ALTER EVENT SESSION [serializable_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'serializable_locks'
	, @filter_batch_only = 1;
GO

SELECT	/* batch code */
		c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
FROM	demo.customers WITH (SERIALIZABLE)
WHERE	c_custkey BETWEEN 5 AND 10;
GO

ALTER EVENT SESSION [serializable_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'serializable_locks'
	, @filter_batch_only = 1;
GO

/*
	Clean the enviroment!
*/
WHILE @@TRANCOUNT > 0
	ROLLBACK TRANSACTION;
GO

DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA IF EXISTS demo;
GO