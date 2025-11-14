/*
	============================================================================
	File:		04 - deadlock with one object only.sql

	Summary:	This demo shows a deadlock with only ONE object involved.

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

DROP TABLE IF EXISTS dbo.process_status;
GO

/* Create the test table for processing */
RAISERROR ('Create the demo table [dbo].[process_status]', 0, 1) WITH NOWAIT;
GO

BEGIN
    CREATE TABLE dbo.process_status
    (
        id          INT         NOT NULL,
        scancode    VARCHAR(10) NOT NULL,
        ship_id     VARCHAR(10) NOT NULL,
        istate      INT         NOT NULL
    );

    /* Create a nonclustered index on the predicate attributes */
    CREATE NONCLUSTERED INDEX nix_process_status_scancode_ship_id
    ON dbo.process_status
    (
	    scancode,
	    ship_id
    );

    /* Insert a demo record into the test table */
    INSERT INTO dbo.process_status
    (scancode, ship_id, istate, id)
    VALUES
    ('0000000000', '4711', 0, 1);
END
GO

RAISERROR ('Create stored procedure [dbo].[start_process]', 0, 1) WITH NOWAIT;
GO

CREATE OR ALTER PROCEDURE dbo.start_process
    @scancode   VARCHAR(10),
    @ship_id    VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
 
    BEGIN TRANSACTION
        /* We lock the resource to prevent other activity */
        UPDATE  dbo.process_status
        SET     istate = 1
        WHERE   scancode = @scancode
                AND ship_id = @ship_id;
 
        /* Now we start our activity which takes app. 1 - 3 seconds */
        WAITFOR DELAY '00:00:01';
  
        /*
            and release the lock when the process is done
            AT THIS POINT WE RUN INTO A DEADLOCK!   
        */
        UPDATE  dbo.process_status
        SET     istate = 0
        WHERE   scancode = @scancode
                AND ship_id = @ship_id;
    COMMIT TRANSACTION;
END
GO

RAISERROR ('To demonstrate the deadlocks just load the template
./98 - SQL Query Stress/03 - deadlock on one object.json', 0, 1) WITH NOWAIT;
