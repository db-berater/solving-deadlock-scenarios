USE ERP_Demo;
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

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'repeatable_read_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session repeatable_read_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION repeatable_read_locks ON SERVER;
END
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'serializable_locks')
BEGIN
	RAISERROR (N'dropping existing extended event session serializable_locks...', 0, 1) WITH NOWAIT;
	DROP EVENT SESSION serializable_locks ON SERVER;
END
GO