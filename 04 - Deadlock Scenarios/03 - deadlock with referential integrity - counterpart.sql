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

BEGIN TRANSACTION update_customer
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe',
			c_nationkey = 99
	WHERE	c_custkey = 10;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID)
	WHERE	object_name = N'[dbo].[customers]'
	ORDER BY
			object_name,
			sort_order;

	SELECT	*
	FROM	dbo.nations -- WITH (HOLDLOCK)
	WHERE	n_nationkey = 99;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(52)
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
	, @filter_condition = N'object_name = ''customers'' OR object_name = ''nations''';
GO