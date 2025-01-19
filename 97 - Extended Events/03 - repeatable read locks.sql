/*============================================================================
	File:		02 - read committed locks.sql

	Summary:	creates an Extended Event to track all locks from a SELECT
				against a resource in READ COMMITTED isolation level
				
				THIS SCRIPT IS PART OF THE TRACK:
					Session: Solving Deadlock Scenarios

	Date:		January 2025

	SQL Server Version: >= 2016
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE master;
GO

/*
	NOTE:		RUN THIS SCRIPT IN SQLCMD MODUS!!!

	Explanation of variables:
	EventName:	Name of the Extended Event session

	session_id:		session_id to track
*/
:SETVAR EventName			repeatable_read_locks
:SETVAR	session_id			76

PRINT N'-------------------------------------------------------------';
PRINT N'| Installation script by db Berater GmbH                     |';
PRINT N'| https://www.db-berater.de                                  |';
PRINT N'| Uwe Ricken - uwe.ricken@db-berater.de                      |';
PRINT N'-------------------------------------------------------------';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'$(EventName)')
BEGIN
	RAISERROR (N'dropping existing extended event session $(EventName)...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [$(EventName)] ON SERVER;
END
GO

RAISERROR (N'creating extended event session $(EventName)...', 0, 1) WITH NOWAIT;
CREATE EVENT SESSION [$(EventName)] ON SERVER 
ADD EVENT sqlserver.sql_batch_starting
(
	ACTION (sqlserver.session_id)
	WHERE
	(
		sqlserver.is_system = 0
		AND sqlserver.session_id = $(session_id)
	)
),
ADD EVENT sqlserver.sql_batch_completed
(
	ACTION (sqlserver.session_id)
	WHERE
	(
		sqlserver.is_system = 0
		AND sqlserver.session_id = $(session_id)
	)
),
ADD EVENT sqlserver.lock_acquired
(
	ACTION (sqlserver.session_id)
	WHERE 
		sqlserver.is_system = 0
		AND sqlserver.session_id = $(session_id)
		AND
		(
			mode = 1		/* SCH_S */
			OR mode = 2		/* SCH_M */
			OR mode = 3		/* S */
			OR mode = 4		/* U */
			OR mode = 5		/* X */
			OR mode = 6		/* IS */
			OR mode = 7		/* IU */
			OR mode = 8		/* X */
		)
),
ADD EVENT sqlserver.lock_released
(
	ACTION (sqlserver.session_id)
	WHERE 
		sqlserver.is_system = 0
		AND sqlserver.session_id = $(session_id)
		AND
		(
			mode = 1		/* SCH_S */
			OR mode = 2		/* SCH_M */
			OR mode = 3		/* S */
			OR mode = 4		/* U */
			OR mode = 5		/* X */
			OR mode = 6		/* IS */
			OR mode = 7		/* IU */
			OR mode = 8		/* X */
		)
)
ADD TARGET package0.ring_buffer (SET max_events_limit = 0, max_memory = 10240)
WITH
(
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY= 1 SECONDS,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=OFF
);
GO

ALTER EVENT SESSION $(EventName) ON SERVER STATE = START;
GO