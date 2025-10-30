/*
	============================================================================
	File:		03 - deadlock with referential integrity - counterpart.sql

	Summary:	This demo script is part of the script 02... sql

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

BEGIN TRANSACTION update_customer
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe',
			c_nationkey = 6
	WHERE	c_custkey = 10;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID, DEFAULT)
	WHERE	object_name = N'[dbo].[customers]'
	ORDER BY
			object_name,
			sort_order;

	SELECT	%%lockres%%,
			n_nationkey,
            n_name,
            n_regionkey,
            n_comment
	FROM	dbo.nations
	WHERE	n_nationkey = 99;
	GO

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(NULL, DEFAULT)
	WHERE	resource_description NOT LIKE N'sys%'
			AND resource_description <> N'get_locking_status'
	ORDER BY
			request_session_id,
			object_name,
			sort_order;
ROLLBACK TRANSACTION
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
	, @filter_condition = N'activity_id LIKE ''CA0E4BE9-1372-44E3-B4B9-844DCCF7E7F0%''';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session read_committed_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO