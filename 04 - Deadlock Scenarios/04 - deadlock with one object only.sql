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

/* Create the test table for processing */
CREATE TABLE dbo.process_status
(
    id INT,
    scancode VARCHAR(10),
    ship_id VARCHAR(10),
    istate INT
);
GO

/* Create a nonclustered index on the predicate attributes */
CREATE NONCLUSTERED INDEX nix_TestTable_scancode_ship_id
ON dbo.process_status
(
	scancode,
	ship_id
);
GO

/* Insert a demo record into the test table */
INSERT INTO dbo.process_status
(scancode, ship_id, istate, id)
VALUES
('0000000000', '4711', 0, 1);
GO

CREATE OR ALTER PROCEDURE dbo.StartProcess
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
 
        /* Now we start our activity which takes app. 10 seconds */
        WAITFOR DELAY '00:00:05';
  
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
