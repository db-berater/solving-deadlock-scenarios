/*
	============================================================================
	File:		05 - deadlock with serializable transaction level.sql

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

DROP TABLE IF EXISTS dbo.demo_table;
GO

CREATE TABLE dbo.demo_table
(
	c_custkey		BIGINT	NOT NULL,
	c_name			VARCHAR(64)	NOT NULL,
	c_mktsegment	VARCHAR(10)	NOT NULL,

	CONSTRAINT pk_demo_table PRIMARY KEY CLUSTERED (c_custkey)
);
GO

BEGIN
	INSERT INTO dbo.demo_table
	(c_custkey, c_name, c_mktsegment)
	SELECT	c_custkey,
			c_name,
			c_mktsegment
	FROM	dbo.customers
	WHERE	c_custkey <= 1000
			AND c_custkey % 2 = 0
			AND
			(
				c_custkey NOT IN (55, 56)
			)
	ORDER BY
			c_custkey ASC
	OPTION	(MAXDOP 1);

END
GO

CREATE OR ALTER PROCEDURE dbo.insert_demo_row
	@c_custkey BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	BEGIN TRANSACTION
		IF NOT EXISTS
			(
				SELECT * FROM dbo.demo_table WHERE c_custkey = @c_custkey
			)
				INSERT INTO dbo.demo_table
				(c_custkey, c_name, c_mktsegment)
				SELECT	c_custkey, c_name, c_mktsegment
				FROM	dbo.customers
				WHERE	c_custkey = @c_custkey;
		ELSE
			UPDATE	dc
			SET		dc.c_name = c.c_name,
					dc.c_mktsegment = c.c_mktsegment
			FROM	dbo.demo_table AS dc
					INNER JOIN dbo.customers AS c
					ON (dc.c_custkey = c.c_custkey);
	ROLLBACK TRANSACTION;
END
GO

RAISERROR ('Activate the extended event "05 - deadlock recordings" and open Live View', 0, 1) WITH NOWAIT;
RAISERROR ('In SQLQueryStress load the workload "05 - deadlock in serializable isolation level.json"', 0, 1) WITH NOWAIT;
GO