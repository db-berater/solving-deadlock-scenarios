/*
	============================================================================
	File:		04 - deadlock recordings.sql

	Summary:	creates an Extended Event to track deadlocks in ERP_Demo database
				
				THIS SCRIPT IS PART OF THE TRACK:
					Session: Solving Deadlock Scenarios

	Date:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

/*
	NOTE:		RUN THIS SCRIPT IN SQLCMD MODUS!!!

	Explanation of variables:
	EventName:	Name of the Extended Event session
*/
:SETVAR EventName			deadlock_recordings

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
ADD EVENT sqlserver.xml_deadlock_report
(
    ACTION(sqlserver.database_name)
)
WITH
(
    MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=5 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF
)
GO

RAISERROR (N'starting extended event session $(EventName)...', 0, 1) WITH NOWAIT;
ALTER EVENT SESSION $(EventName) ON SERVER STATE = START;
GO