/*
	============================================================================
	File:		01 - classic deadlock 01.sql

	Summary:	This script demonstrates a possible solution to avoid classical
				deadlocks.

				Solution: Same call stack for all processes.

				THIS SCRIPT IS PART OF THE TRACK:
					Session: Solving Deadlock Scenarios

	Date:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	We take exactly the same scenario with a defense option to prevent deadlocks
*/

/*
	Session 1:	When we know from our dev scenario that we must have an additional
				lookup to other resources, we have three options to protect our
				workload against Deadlocks:

	- Usage of same call stack (order of executions)
	- Aquire a lock before we start the process
	- Hold required rows from the additional resource in a temporary object
*/
BEGIN TRANSACTION update_customers;
GO
	/*
		We know that we must access an additional resource
	*/
	SELECT	*
	FROM	dbo.nations WITH (HOLDLOCK)
	WHERE	n_nationkey = 2;

	UPDATE	dbo.customers
	SET		c_name = 'Uwe Ricken'
	WHERE	c_custkey = 10
	OPTION	(MAXDOP 1);
	GO

	/*
		What resources are locked now?
	*/
	SELECT	*
	FROM	dbo.get_locking_status(@@spid);
	GO

	/* After the second transaction has started we process with the next step */
	SELECT	*
	FROM	dbo.nations
	WHERE	n_nationkey = 2
	OPTION	(MAXDOP 1);

	SELECT	*
	FROM	dbo.get_locking_status(@@spid);
	GO

ROLLBACK TRANSACTION update_customers;
GO

USE ERP_Demo;
GO

/*
	Session 2:	Update auf dbo.customers
*/
BEGIN TRANSACTION update_customers;
GO
	UPDATE	dbo.nations
	SET		n_name = 'UK'
	WHERE	n_nationkey = 2
	OPTION	(MAXDOP 1);
	GO

	/* After the second transaction has started we process with the next step */
	SELECT	*
	FROM	dbo.customers
	WHERE	c_custkey = 10
	OPTION	(MAXDOP 1);
ROLLBACK TRANSACTION update_customers;
GO

	SELECT	*
	FROM	dbo.get_locking_status(74);
	GO