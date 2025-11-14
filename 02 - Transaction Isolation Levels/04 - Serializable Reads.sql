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

/*
	Let's first create a demo table with customer key values which are even!
	2, 4, 6, 8, ....
*/
BEGIN
	DROP TABLE IF EXISTS dbo.demo_customers;

	CREATE TABLE dbo.demo_customers
	(
		c_custkey		BIGINT		NOT NULL PRIMARY KEY CLUSTERED,
		c_name			VARCHAR(64)	NOT NULL,
		c_mktsegment	VARCHAR(64)	NOT NULL
	);

	/* We insert the TOP 1000 even c_custkey values into the table */
	INSERT INTO dbo.demo_customers WITH (TABLOCK)
	(c_custkey, c_name, c_mktsegment)
	SELECT	c_custkey,
			c_name,
			c_mktsegment
	FROM	dbo.customers
	WHERE	c_custkey <= 500
			AND c_custkey % 2 = 0;
END
GO

SELECT	c_custkey,
		c_name,
		c_mktsegment
FROM	dbo.demo_customers
GO

BEGIN TRANSACTION;
GO
	SELECT	c_custkey,
			c_name,
			c_mktsegment
	FROM	dbo.demo_customers WITH (SERIALIZABLE)
	WHERE	c_custkey BETWEEN 6 AND 10;
	GO

	;WITH l
	AS
	(
		SELECT	%%lockres%%		AS	resource_description,
				c_custkey
		FROM	dbo.demo_customers WITH (READCOMMITTED)
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
		c_name,
        c_mktsegment
FROM	dbo.demo_customers WITH (SERIALIZABLE)
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
		c_name,
        c_mktsegment
FROM	dbo.demo_customers WITH (SERIALIZABLE)
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

DROP TABLE IF EXISTS dbo.demo_customers;
DROP SCHEMA IF EXISTS demo;
GO