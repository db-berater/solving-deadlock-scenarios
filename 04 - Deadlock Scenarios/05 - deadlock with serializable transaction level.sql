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

SELECT	c_custkey,
        c_mktsegment,
        c_nationkey,
        c_name,
        c_address,
        c_phone,
        c_acctbal,
        c_comment
INTO	dbo.demo_table
FROM	dbo.customers
WHERE	c_custkey <= 100
		AND
		(
			c_custkey NOT IN (55, 56)
		);
GO

ALTER TABLE dbo.demo_table
ADD CONSTRAINT pk_demo_table PRIMARY KEY CLUSTERED (c_custkey);
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
				SELECT * FROM dbo.customers
				WHERE	c_custkey = @c_custkey;
	ROLLBACK TRANSACTION;
END
GO

SELECT c_custkey FROM (VALUES (55), (56)) AS x (c_custkey);