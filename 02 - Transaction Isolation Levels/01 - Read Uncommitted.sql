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

	-- Copy the following statement in another query window
	BEGIN TRANSACTION
	GO
		UPDATE	dbo.customers
		SET		c_name = 'Uwe Ricken'
		WHERE	c_custkey = 10
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
FROM	dbo.get_locking_status(75)
ORDER BY
		request_session_id;
GO

/* The query will be blocked in READ COMMITTED isolation level */
SELECT * FROM dbo.customers
WHERE	c_custkey = 10;
GO

SELECT * FROM dbo.customers WITH (NOLOCK)
WHERE	c_custkey = 10;
GO

SELECT * FROM dbo.customers WITH (READUNCOMMITTED)
WHERE	c_custkey = 10;
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

SELECT * FROM dbo.customers
WHERE	c_custkey = 10;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

/*
	Clean the environment
	- drop the extended event session
*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'SCH_S_Locks')
	DROP EVENT SESSION [SCH_S_Locks] ON SERVER 
GO
