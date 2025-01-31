BEGIN TRANSACTION
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe',
			c_nationkey = 99
	WHERE	c_custkey = 10;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(@@SPID)
	WHERE	object_name = N'[dbo].[customers]'
	ORDER BY
			object_name,
			sort_order;

	SELECT * FROM dbo.nations
	WHERE n_nationkey = 99;

	SELECT	request_session_id,
			index_name,
			resource_type,
			resource_description,
			request_mode,
			request_type,
			request_status
	FROM	dbo.get_locking_status(88)
	ORDER BY
			object_name,
			sort_order;
ROLLBACK TRANSACTION
GO