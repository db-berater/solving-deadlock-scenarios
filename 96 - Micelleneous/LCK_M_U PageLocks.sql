	UPDATE	demo.customers
	SET		c_custkey = 10
	WHERE	c_name = 'Uwe'
	GO

ALTER EVENT SESSION [read_committed_locks] ON SERVER
	DROP EVENT sqlserver.lock_acquired,
	DROP EVENT sqlserver.lock_released;
GO

/* ... and read the data from the ring buffer */
EXEC dbo.sp_read_xevent_locks
	@xevent_name = N'read_committed_locks';
GO

SELECT	*
FROM	sys.dm_db_page_info(DB_ID(), 1, 422644, N'Detailed');