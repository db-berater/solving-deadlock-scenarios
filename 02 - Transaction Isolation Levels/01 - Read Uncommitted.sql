/*
	============================================================================
	File:		01 - Read Uncommitted.sql

	Summary:	demonstration of read uncommitted isolation level
				
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
	Run the extended event script: 01 - SCH_S_locks.sql to implement the
	extended event which monitors SCH_S locks!
	Change the session_id variable in the script to this session_id!

	-- Copy the following statement in another query window
	USE ERP_Demo;
	GO

	BEGIN TRANSACTION
	GO
		UPDATE	dbo.customers
		SET		c_name = 'Uwe Ricken'
		WHERE	c_custkey = 10
		OPTION	(MAXDOP 1);
*/

/*
    Let's have a look to the obtained locks from the running spid
    Note:   This function is part of the framework of the demo database
            https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	DISTINCT
		request_session_id,
		resource_type,
		resource_description,
		request_mode,
		request_type,
		request_status,
		blocking_session_id
FROM	dbo.get_locking_status(61)
ORDER BY
		request_session_id;
GO

/* The query will be blocked in READ COMMITTED isolation level */
SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	dbo.customers
WHERE	c_custkey = 10;
GO

/*
	Let's see what read uncommitted isolation level will do.
*/

SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	dbo.customers WITH (NOLOCK)
WHERE	c_custkey = 10;
GO

/*
	Stop the recording by dropping both events for tracking the locks
*/
ALTER EVENT SESSION [read_uncommitted_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_uncommitted_locks',
	@filter_condition = N'activity_id LIKE ''266BC1DA-3E0F-41B5-B890-A935465EDC16%''';
GO

/* Re-Implement the extended event for read uncommitted. */

SELECT	[c_custkey],
		[c_mktsegment],
		[c_nationkey],
		[c_name],
		[c_address],
		[c_phone],
		[c_acctbal],
		[c_comment]
FROM	dbo.customers WITH (READUNCOMMITTED)
WHERE	c_custkey <= 100000
OPTION	(MAXDOP 1);
GO

/*
	Stop the recording by dropping both events for tracking the locks
*/
ALTER EVENT SESSION [read_uncommitted_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_uncommitted_locks',
	@filter_condition = N'activity_id LIKE ''266BC1DA-3E0F-41B5-B890-A935465EDC16%''';
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
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
WHERE	c_custkey <= 10000
OPTION	(MAXDOP 1);
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

/*
	Clean the environment
	- drop the extended event session
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_uncommitted_locks')
	DROP EVENT SESSION [read_uncommitted_locks] ON SERVER 
GO
