/*
	============================================================================
	File:		04 - deadlock with one object only.sql

	Summary:	The script demonstrates the solution for the deadlock scenario

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
	The core problem is the locking on the nonclustered index!
*/

    /* We lock the resource to prevent other activity */
    UPDATE  dbo.process_status
    SET     istate = 0
    WHERE   scancode = '0000000000'
            AND ship_id = '4711';
	GO

	/*
	Stop the recording by dropping both events for tracking the locks
*/
ALTER EVENT SESSION [read_committed_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO



	SELECT	request_session_id,
            object_name,
            partition_number,
            index_name,
            index_id,
            resource_type,
            resource_subtype,
            resource_description,
            resource_associated_entity_id,
            request_mode,
            request_type,
            request_status,
            blocking_session_id,
            sort_order
	FROM	dbo.get_locking_status(@@SPID, DEFAULT);
	GO
ROLLBACK TRANSACTION;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_committed_locks'
	, @filter_condition = N'activity_id LIKE ''C6C65F77-39CE-470D-ACAC-B8FA1D28D783%''';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO
