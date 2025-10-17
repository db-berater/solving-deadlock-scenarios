
# Session - Solving Deadlock Scenarios
This repository contains all slides and demo codes for my session "Solving Deadlock Scenarios"
To work with the scripts it is required to have the workshop database [ERP_Demo](https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK) installed on your SQL Server Instance.
The last version of the demo database can be downloaded here:

**https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK**

> Written by
>	[Uwe Ricken](https://www.db-berater.de/uwe-ricken/), 
>	[db Berater GmbH](https://db-berater.de)
> 
> All scripts are intended only as a supplement to demos and lectures
> given by Uwe Ricken.  
>   
> **THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
> ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
> TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
> PARTICULAR PURPOSE.**

**Note**\
The database contains a framework for all workshops / sessions from db Berater GmbH
+ Stored Procedures
+ User Definied Inline Functions

Session Scripts for SQL Server Session "Solving Deadlock Scenarios"
Version:	1.00.100
Date:		2025-10-17

# Session Description
The session material covers three deadlock scenarios that can occur in everyday life with data locks in Microsoft SQL Server. From simple to complex deadlocks, examples are shown of how deadlocks can occur and how they can be avoided.

# Folder structure
## 01 - Documents and Preparation
This folder contains the slide deck (Powerpoint) and a restore procedure for the ERP_Demo database. Since the procedure dbo.sp_read_xevent_locks is part of the core framework of ERP_Demo, it is not required anymore.
## 02 - Transaction Isolation Levels
This folder contains examples for all four pessimistic isolation levels of Microsoft SQL Server. These demos are typically for a session with >= 75 mins!
## 03 - Lock Types
empty
## 04 - Deadlock Scenarios
This folder contains three examples for Deadlocks in Microsoft SQL Server.
+ Classic Deadlock Scenario
+ Foreign Key Deadlock Scenario
+ Index Key Lookup Scenario
## 05 - Deadlock Scenarios - Solutions
This folder contains deeper analysis scripts for a better understanding why deadlocks in the previous scenarios occured.
## 97 - extended events
To understand deadlocks in depth it is required to understand the locking chain. With Extended Events we make locks inside a session visible.
## 98 - SQL Query Stress
This folder contains templates for workloads which requires higher contention. It is recommended to have a SQL Alias called "SQLServer" to avoid changing the Server Name inside the template scripts.