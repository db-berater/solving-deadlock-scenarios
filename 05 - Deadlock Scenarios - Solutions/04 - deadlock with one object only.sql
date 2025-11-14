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
	By making the HEAP Table a clustered table with the - actual - Non Clustered Index
	as the key attributes for the clustered index, the problem is gone!
*/
IF EXISTS
(
	SELECT	*
	FROM	sys.indexes
	WHERE	name = N'nix_process_status_scancode_ship_id'
			AND OBJECT_ID = OBJECT_ID(N'dbo.process_status', N'U')
)
	DROP INDEX nix_process_status_scancode_ship_id ON dbo.process_status;
	GO

CREATE CLUSTERED INDEX cuix_process_status_scancode_ship_id
ON dbo.process_status
(
	scancode,
	ship_id
);
GO

EXEC dbo.sp_deactivate_query_store;
GO

/*
	run the extended event "02 - read committed locks.sql"
	again, before we start the transaction again.
*/

BEGIN TRANSACTION
GO
	UPDATE  /* batch code */
			dbo.process_status
	SET     istate = 0
	WHERE   scancode = '0000000000'
			AND ship_id = '4711';
	GO
ROLLBACK TRANSACTION;
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

/* Clean the kitchen */
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session [read_committed_locks]...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO
