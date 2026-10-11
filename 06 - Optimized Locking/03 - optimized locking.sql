ALTER DATABASE ERP_Demo SET COMPATIBILITY_LEVEL = 170;
ALTER DATABASE ERP_Demo SET READ_COMMITTED_SNAPSHOT = ON;
ALTER DATABASE ERP_Demo SET ACCELERATED_DATABASE_RECOVERY = OFF WITH ROLLBACK IMMEDIATE;
ALTER DATABASE ERP_Demo SET OPTIMIZED_LOCKING = OFF WITH ROLLBACK IMMEDIATE;
GO

USE ERP_Demo;
GO

BEGIN TRANSACTION
GO
	UPDATE	demo.orders
	SET		o_orderpriority = '1 - URGENT'
	WHERE	o_custkey = 1211159;
	GO

    SELECT resource_type, request_mode, COUNT(*) AS cnt
    FROM sys.dm_tran_locks
    GROUP BY resource_type, request_mode
    ORDER BY cnt DESC;

    SELECT  *
    FROM    sys.dm_tran_locks
    WHERE   request_session_id = @@SPID;

    /* Let's check the locks! */
	SELECT	request_session_id,
            object_name,
            index_name,
            resource_type,
            resource_description,
            request_mode,
            request_type,
            request_status,
            blocking_session_id
	FROM	dbo.get_locking_status(NULL, 1)
    WHERE   resource_associated_entity_id > 10000
            AND resource_type <> N'METADATA'
            AND resource_description <> N'get_locking_status'
    ORDER BY
            sort_order;
    GO

    /*
        Run the following code in another Query Window!
        SELECT * FROM demo.orders
        WHERE	o_orderdate = '2023-01-01'
        ORDER BY
	        o_orderkey;
    */
ROLLBACK;
GO