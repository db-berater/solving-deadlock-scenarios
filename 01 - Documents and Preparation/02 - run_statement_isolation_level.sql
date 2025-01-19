USE ERP_Demo;
GO

CREATE OR ALTER PROCEDURE dbo.run_statement_isolation_level
	@sql_stmt			NVARCHAR(MAX),
	@isolation_level	NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	SET	@sql_stmt = CASE @isolation_level
						WHEN N'READ UNCOMMITTED'	THEN N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;' + @sql_stmt
						WHEN N'REPEATABLE READ'		THEN N'SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;' + @sql_stmt
						WHEN N'SERIALIZABLE'		THEN N'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;' + @sql_stmt
						ELSE @sql_stmt
					END

	RAISERROR ('Running statement with isolation level %s', 0, 1, @isolation_level) WITH NOWAIT;

	EXEC	sp_executesql @sql_stmt;
END
GO