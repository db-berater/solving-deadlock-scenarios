CREATE OR ALTER PROCEDURE dbo.sp_read_xevent_locks
	@xevent_name	NVARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	RAISERROR ('Catching the data from the ring_buffer for extended event [%s]', 0, 1, @xevent_name) WITH NOWAIT;
	SELECT	CAST(target_data AS XML) AS target_data
	INTO	#xe_data
	FROM	sys.dm_xe_session_targets AS t
			INNER JOIN sys.dm_xe_sessions AS s
			ON (t.event_session_address = s.address)
	WHERE	s.name = @xevent_name
			AND t.target_name = N'ring_buffer';

	RAISERROR ('Analyzing the data from the ring buffer', 0, 1) WITH NOWAIT;
	SELECT	x.event_data.value ('(@timestamp)[1]', N'DATETIME')									AS	[timestamp],
			x.event_data.value('(@name)[1]', 'VARCHAR(25)')										AS	Even_name,
			x.event_data.value('(data[@name="resource_type"]/text)[1]', 'VARCHAR(25)')			AS	resource_type,
			x.event_data.value('(data[@name="mode"]/text)[1]', 'VARCHAR(10)')					AS	lock_mode,
			x.event_data.value('(data[@name="resource_0"]/value)[1]', 'NVARCHAR(25)')			AS	resource_0,
			x.event_data.value('(data[@name="resource_1"]/value)[1]', 'NVARCHAR(25)')			AS	resource_1,
			x.event_data.value('(data[@name="resource_2"]/value)[1]', 'NVARCHAR(25)')			AS	resource_2,
			OBJECT_NAME
			(
				x.event_data.value('(data[@name="object_id"]/value)[1]', 'INT')
			)																					AS	object_name,
			x.event_data.value('(data[@name="associated_object_id"]/value)[1]', 'NVARCHAR(25)')	AS	associated_object_id
	FROM	#xe_data AS txe
			CROSS APPLY txe.target_data.nodes('//RingBufferTarget/event') AS x (event_data)
END
GO