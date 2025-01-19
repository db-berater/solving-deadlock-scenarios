USE ERP_Demo;
GO

EXEC sp_drop_indexes @table_name = N'ALL';
EXEC sp_drop_statistics @table_name = N'ALL';
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_uncommitted_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session read_uncommitted_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_uncommitted_locks] ON SERVER;
END
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'read_committed_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session read_committed_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION [read_committed_locks] ON SERVER;
END
GO