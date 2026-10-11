USE ERP_Demo;
GO

/* Erstellen von demo schema */
EXEC dbo.sp_create_demo_schema;
GO

/* Erstellen einer Tabelle mit 567.254 Einträgen */
DROP TABLE IF EXISTS demo.orders;
GO

SELECT	o_orderdate,
        o_orderkey,
        o_custkey,
        o_orderpriority,
        o_shippriority,
        o_clerk,
        o_orderstatus,
        o_totalprice,
        o_comment,
        o_storekey
INTO	demo.orders
FROM	dbo.orders
WHERE	o_orderdate >= '2023-01-01'
		AND o_orderdate <= '2023-03-31';
GO

ALTER TABLE demo.orders ADD CONSTRAINT pk_demo_orders
PRIMARY KEY CLUSTERED (o_orderkey)
WITH
(
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON
);
GO

CREATE NONCLUSTERED INDEX nix_demo_orders_o_orderdate
ON demo.orders (o_orderdate)
WITH
(
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON
);
GO

--CREATE NONCLUSTERED INDEX nix_demo_orders_o_custkey
--ON demo.orders(o_custkey)
--WITH
--(
--    DATA_COMPRESSION = PAGE,
--    SORT_IN_TEMPDB = ON
--);
--GO