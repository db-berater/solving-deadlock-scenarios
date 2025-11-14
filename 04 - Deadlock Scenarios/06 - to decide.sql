SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

DROP TABLE IF EXISTS dbo.demo_table;
CREATE TABLE dbo.demo_table
(
	id	INT			NOT NULL	IDENTITY (1, 1),
	c1	BIGINT		NOT NULL,
	c2	CHAR(100)	NOT NULL,
	c3	CHAR(100)	NOT NULL

	CONSTRAINT pk_demo_table PRIMARY KEY CLUSTERED (id)
);
GO

CREATE NONCLUSTERED INDEX nix_demo_table_c1
ON dbo.demo_table (c1) INCLUDE (c2);
GO

INSERT INTO dbo.demo_table
(c1, c2, c3)
SELECT	c_custkey,
		c_name,
		c_mktsegment
FROM	dbo.customers
WHERE	c_custkey <= 10000
GO

CREATE OR ALTER PROCEDURE dbo.get_record
	@c_custkey	BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@c1	BIGINT;
	DECLARE	@c2	CHAR(100);
	DECLARE	@c3 CHAR(100);

	SELECT	@c1 = c1,
			@c2 = c2,
			@c3 = c3
	FROM	dbo.demo_table
	WHERE	c1 = @c_custkey;
END
GO

CREATE OR ALTER PROCEDURE set_record
	@c_custkey	BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE	dbo.demo_table
	SET		c3 = 'Test'
	WHERE	id = @c_custkey;
END
GO

--EXEC dbo.get_record 4;

--EXEC dbo.set_record 4;
