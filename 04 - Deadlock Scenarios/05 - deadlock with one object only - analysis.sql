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
USE ERP_Demo;
GO

/* Check the locking chain for the UPDATE statement */
BEGIN TRANSACTION
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
		FROM	dbo.get_locking_status(NULL)
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
	We stop here and run the process with SQLQueryStress!!!
*/


/*
	For a deeper understanding of the problem we must see the complete
	locking chain when an update happens

	- run the xevent 02 - read committed locks.sql and change the session_id to the current one!
*/
BEGIN TRANSACTION
GO
	UPDATE  dbo.process_status
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
	, @filter_condition = N'activity_id LIKE ''4E319875-85CB-46DF-90C3-C6E182F3501C%''';
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