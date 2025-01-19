USE ERP_Demo;
GO

/*
	Session 1:	Update auf dbo.customers
*/
BEGIN TRANSACTION update_customers;
GO
	UPDATE	dbo.customers
	SET		c_name = 'Uwe Ricken'
	WHERE	c_custkey = 10
	OPTION	(MAXDOP 1);
	GO

	/* After the second transaction has started we process with the next step */
	SELECT	*
	FROM	dbo.nations
	WHERE	n_nationkey = 2
	OPTION	(MAXDOP 1);
ROLLBACK TRANSACTION update_customers;
GO
