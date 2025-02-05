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