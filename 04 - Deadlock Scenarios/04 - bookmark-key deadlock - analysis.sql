/*
	============================================================================
	File:		05 - deadlock with one object only - analysis.sql

	Summary:	This demo shows a deadlock with only ONE object involved.

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

EXEC sp_deactivate_query_store;
GO

/* Check the locking chain for the UPDATE statement */
BEGIN TRANSACTION update_process_status
GO
    /* We lock the resource to prevent other activity */
    UPDATE  dbo.process_status
    SET     istate = 1
    WHERE   scancode = '0000000000'
            AND ship_id = '4711';

	/* What locking chain do we have here? */
	;WITH l
	AS
	(
		SELECT	DISTINCT
				request_session_id,
				resource_type,
				resource_description,
				request_mode,
				request_type,
				request_status,
				sort_order
		FROM	dbo.get_locking_status(NULL, DEFAULT)
		WHERE	resource_description <> N'get_locking_status'
				AND resource_associated_entity_id > 100
	)
	SELECT	request_session_id,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	l
	ORDER BY
			request_session_id,
			sort_order;
	GO

	/* After the job is done we unlock our resource */
	UPDATE  dbo.process_status
	SET     istate = 0
	WHERE   scancode = '0000000000'
			AND ship_id = '4711';
ROLLBACK
GO

/*
	For a deeper understanding of the problem we must see the complete
	locking chain when an update happens

	- run the extended event
	./97 - extended events/02 - read committed locks.sql
*/
BEGIN TRANSACTION
GO
	UPDATE  /* batch code */
			dbo.process_status
	SET     istate = 0
	WHERE   scancode = '0000000000'
			AND ship_id = '4711';
	GO
COMMIT TRANSACTION;
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

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO
