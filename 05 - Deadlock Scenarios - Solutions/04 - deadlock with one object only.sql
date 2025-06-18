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



	SELECT	*
	FROM	dbo.get_locking_status(@@SPID);
	GO
ROLLBACK TRANSACTION;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_committed_locks'
	, @filter_condition = N'activity_id LIKE ''C6C65F77-39CE-470D-ACAC-B8FA1D28D783%''';
GO