/*
	============================================================================
	File:		01 - Preparation of demo databases.sql

	Summary:	This script restores the database ERP_Demo from
				the backup medium for distribution of data.
				
				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE master;
GO

/*
	Make sure you've executed the script 00 - dbo.sp_restore_erp_demo.sql
	before you run this code!
*/
EXEC dbo.sp_restore_ERP_demo @query_store = 1;
GO

/* reset the sql server default settings for the demos */
EXEC ERP_Demo.dbo.sp_set_sql_server_defaults;
GO

SELECT * FROM ERP_Demo.dbo.get_database_help_info();
SELECT * FROM ERP_Demo.dbo.get_object_help_info(NULL);
GO

USE ERP_Demo;
GO

CREATE OR ALTER PROCEDURE dbo.sp_read_xevent_locks
	@xevent_name		NVARCHAR(128),
	@filter_condition	NVARCHAR(1024) = NULL
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

	SELECT	x.event_data.value ('(action[@name="attach_activity_id"]/value)[1]', 'VARCHAR(40)')			AS	activity_id,
			x.event_data.value ('(@timestamp)[1]', N'DATETIME')											AS	[timestamp],
			x.event_data.value('(@name)[1]', 'VARCHAR(25)')												AS	event_name,
			x.event_data.value ('(data[@name="batch_text"]/value)[1]', 'VARCHAR(MAX)')					AS	batch_text,
			x.event_data.value('(data[@name="resource_type"]/text)[1]', 'VARCHAR(25)')					AS	resource_type,
			x.event_data.value('(data[@name="mode"]/text)[1]', 'VARCHAR(10)')							AS	lock_mode,
			x.event_data.value('(data[@name="resource_0"]/value)[1]', 'NVARCHAR(25)')					AS	resource_0,
			x.event_data.value('(data[@name="resource_1"]/value)[1]', 'NVARCHAR(25)')					AS	resource_1,
			x.event_data.value('(data[@name="resource_2"]/value)[1]', 'NVARCHAR(25)')					AS	resource_2,
			OBJECT_NAME
			(
				CASE WHEN ISNULL(x.event_data.value('(data[@name="object_id"]/value)[1]', 'INT'), 0) = 0
					 THEN i.object_id
					 ELSE x.event_data.value('(data[@name="object_id"]/value)[1]', 'INT')
				END
			)																					AS	object_name,
			x.event_data.value('(data[@name="associated_object_id"]/value)[1]', 'NVARCHAR(25)')	AS	associated_object_id,
			i.index_id,
			i.name																				AS	index_name
	INTO	#temp_result
	FROM	#xe_data AS txe
			CROSS APPLY txe.target_data.nodes('//RingBufferTarget/event') AS x (event_data)
			LEFT JOIN sys.partitions AS p
			ON
			(
				TRY_CAST(x.event_data.value('(data[@name="associated_object_id"]/value)[1]', 'NVARCHAR(25)') AS BIGINT) = p.hobt_id
			)
			LEFT JOIN sys.indexes AS i
			ON
			(
				p.object_id = i.object_id
				AND p.index_id = i.index_id
			)

	IF @filter_condition IS NOT NULL
	BEGIN
		DECLARE	@sql_stmt NVARCHAR(MAX) = N'SELECT	activity_id,
		[timestamp],
		event_name,
		batch_text,
		resource_type,
		lock_mode,
		resource_0,
		resource_1,
		resource_2,
		object_name,
		associated_object_id,
		index_id,
		index_name
FROM	#temp_result
WHERE ' + @filter_condition + N' 
ORDER BY
		timestamp,
		TRY_CAST(SUBSTRING(activity_id, 38, 255) AS INT);';
		EXEC sp_executesql @sql_stmt;
	END
	ELSE
		SELECT	activity_id,
				[timestamp],
				event_name,
				batch_text,
				resource_type,
				lock_mode,
				resource_0,
				resource_1,
				resource_2,
				object_name,
				associated_object_id,
				index_id,
				index_name
		FROM	#temp_result
		ORDER BY
				timestamp ASC,
				TRY_CAST(SUBSTRING(activity_id, 38, 255) AS INT);
END
GO