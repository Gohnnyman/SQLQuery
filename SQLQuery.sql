USE TestData
GO 

---------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS Logs
DROP TABLE IF EXISTS Operations
DROP TABLE IF EXISTS PaymentTypes
DROP TABLE IF EXISTS OperationTypes

DROP PROCEDURE IF EXISTS insertIntoLogs
DROP PROCEDURE IF EXISTS insertIntoOperations
DROP PROCEDURE IF EXISTS insertIntoOperationTypes
DROP PROCEDURE IF EXISTS LogsSum
DROP PROCEDURE IF EXISTS incomeSum
DROP PROCEDURE IF EXISTS total
DROP PROCEDURE IF EXISTS insertIntoPaymentTypes
DROP PROCEDURE IF EXISTS xmlTest
DROP PROCEDURE IF EXISTS currentBalance
DROP PROCEDURE IF EXISTS totalOperaionCost
GO

---------------------------------------------------------------------------------------------------------

CREATE TABLE OperationTypes(
	ID					INT				NOT NULL UNIQUE IDENTITY(1,1),
	Name				VARCHAR(16)		NOT NULL
	PRIMARY KEY(ID)
)

CREATE TABLE PaymentTypes(
	ID					INT				NOT NULL UNIQUE IDENTITY(1,1),
	Name				VARCHAR(16)		NOT NULL
	PRIMARY KEY(ID)
)



CREATE TABLE Operations(
	ID					INT				NOT NULL UNIQUE IDENTITY(1,1),
	Name				VARCHAR(16)		NOT NULL,
	OperationTypesID	INT				NOT NULL,
	Description			VARCHAR(256)	NULL


	PRIMARY KEY(ID),
	FOREIGN KEY(OperationTypesID) REFERENCES OperationTypes(ID) 
		ON DELETE CASCADE 
		ON UPDATE CASCADE
)


CREATE TABLE Logs(
	ID					INT				NOT NULL UNIQUE IDENTITY(1,1),
	OperationsID		INT				NOT NULL,
	Date				DATETIME		NOT NULL DEFAULT GETDATE(),
	Amount				DECIMAL(19, 2)	NOT NULL,
	PaymentTypesID		INT				NOT NULL DEFAULT 2

	PRIMARY KEY(ID),
	FOREIGN KEY(OperationsID) REFERENCES Operations(ID)
		ON DELETE CASCADE
		ON UPDATE CASCADE,

		
	FOREIGN KEY(PaymentTypesID) REFERENCES PaymentTypes(ID)
		ON DELETE CASCADE
		ON UPDATE CASCADE
)
GO

---------------------------------------------------------------------------------------------------------

CREATE PROCEDURE insertIntoLogs  @OperationsId INT, @Amount DECIMAL(19, 2), @PaymentTypesId INT AS 
BEGIN 
	IF(@Amount IS NULL OR @OperationsId IS NULL) 
	BEGIN 
		SELECT 'OH NO! Values can''t be NULL' AS Err
		RETURN 
	END	

	IF(@PaymentTypesID IS NULL)
		INSERT INTO Logs(OperationsId, Amount) VALUES
		(@OperationsID, @Amount);
	ELSE 
		INSERT INTO Logs(OperationsId, Amount, PaymentTypesID) VALUES
		(@OperationsID, @Amount, @PaymentTypesID);

END
GO


CREATE PROCEDURE insertIntoPaymentTypes @Name VARCHAR(16) AS 
BEGIN 
	IF(@Name IS NULL) 
	BEGIN 
		SELECT 'OH NO! Values can''t be NULL' AS Err
		RETURN 
	END	

	INSERT INTO PaymentTypes(Name) VALUES
	(@Name);
END
GO


CREATE PROCEDURE insertIntoOperations @Name VARCHAR(16), @OperationTypesID INT, @Description VARCHAR(256)  AS 
BEGIN 
	IF(@Name IS NULL OR @OperationTypesID IS NULL OR @Description IS NULL) 
	BEGIN 
		SELECT 'OH NO! Values can''t be NULL' AS Err
		RETURN 
	END	

	INSERT INTO Operations(Name, OperationTypesID, Description) VALUES
	(@Name, @OperationTypesID, @Description);
END
GO


CREATE PROCEDURE insertIntoOperationTypes @Name VARCHAR(16)  AS 
BEGIN 
	IF(@Name IS NULL) 
	BEGIN 
		SELECT 'OH NO! Values can''t be NULL' AS Err
		RETURN 
	END	


	INSERT INTO OperationTypes(Name) VALUES
	(@Name);
END
GO


CREATE PROCEDURE currentBalance AS 
BEGIN 
	SELECT 
		SUM(CASE OperationTypesID WHEN 1 THEN Amount ELSE -Amount END) AS 'Current Balance'
	FROM Logs
	INNER JOIN Operations ON Operations.ID = OperationsID
END
GO

CREATE PROCEDURE totalOperaionCost @OperationID INT AS
BEGIN 
	IF(@OperationID NOT IN (SELECT ID FROM Operations))
	BEGIN
		SELECT 'OH NO! Values can''t be NULL' AS Err
		RETURN 
	END 


	SELECT 
		Operations.Name,
		SUM(IIF(OperationTypesID = 1, Amount, -Amount)) AS 'Sum'
		FROM Logs
	INNER JOIN 
		Operations ON Operations.ID = OperationsID
	WHERE 
		Operations.ID = @OperationID
	GROUP BY 
		Operations.Name

END
GO


CREATE PROCEDURE total @fromDate DATETIME = NULL, @toDate DATETIME = NULL AS
BEGIN

	IF(@fromDate IS NULL)
		SET @fromDate = (SELECT MIN(DATE) FROM Logs)
	
	IF(@toDate IS NULL)
		SET @toDate = (SELECT MAX(DATE) FROM Logs);
	

	DECLARE @tmp TABLE (ID INT, Operation VARCHAR(16), Date DATETIME, Cost INT, PaymentType VARCHAR(16), Cur INT);

	INSERT INTO @tmp 
		SELECT 
			Logs.ID, 
			Operations.Name, 
			Logs.Date, 
			CASE OperationTypesID WHEN 1 THEN Amount ELSE -Amount END AS Cost, 
			PaymentTypes.Name, 
			SUM(IIF(OperationTypesID = 1, Amount, -Amount)) OVER (ORDER BY Logs.ID) AS Cur 
			FROM Logs
		INNER JOIN 
			Operations ON Operations.ID = OperationsID
		INNER JOIN 
			PaymentTypes ON PaymentTypes.ID = PaymentTypesID

	


	SELECT 
		Id,
		Operation, 
		Date, 
		PaymentType, 
		Cost, 
		ISNULL(LAG(Cur) OVER(ORDER BY ID),0) AS 'Previous Balance', 
		Cur AS 'Current Balance' 
		FROM @tmp
	WHERE 
		Date >= @fromDate AND Date <= @toDate
END
Go

---------------------------------------------------------------------------------------------------------

EXEC insertIntoOperationTypes 'In'
EXEC insertIntoOperationTypes 'Out'

EXEC insertIntoPaymentTypes 'Card'
EXEC insertIntoPaymentTypes 'Cash'

EXEC insertIntoOperations 'Earnings', 1, 'Earnings from products'
EXEC insertIntoOperations 'Fine/penalty', 1, 'Fine/penalty from workers'
EXEC insertIntoOperations 'Advertisment', 1, 'Money recived from advertisment'
EXEC insertIntoOperations 'Other Out', 2, 'You know, when you spend some money in MacDonal''s'
EXEC insertIntoOperations 'Other In', 1, 'You know, when you find some money on the road'
EXEC insertIntoOperations 'Salary', 2,'Salary for workers'
EXEC insertIntoOperations 'Taxes', 2, 'Nobody likes taxs'
EXEC insertIntoOperations 'Purchasing', 2, 'Purchasing some product for business'
EXEC insertIntoOperations 'Coffee', 2, 'Spending money on coffee for workers'
EXEC insertIntoOperations 'Breakdowns', 2,'Spending money for repairing breakdowns'

EXEC insertIntoLogs 1, 228.13, 1 
EXEC insertIntoLogs 2, 3.99, 2
EXEC insertIntoLogs 2, 3.99, 2
EXEC insertIntoLogs 5, 1337, 1
EXEC insertIntoLogs 9, 1488, 1
GO

---------------------------------------------------------------------------------------------------------

CREATE PROCEDURE xmlTest AS
BEGIN 

	DECLARE	@xmlPart	xml =	N'<FilterSet>
									<commandTimeout>0</commandTimeout>
									<filter>
										<items>
											<items>
												<Value>1.2.24</Value>
												<name>VersionOfProduct</name>
											</items>
											<items>
												<Value>ua</Value>
												<name>productLanguage</name>
											</items>
											<items>
												<Value>ua</Value>
												<name>interfaceLanguage</name>
											</items>
											<items>
												<Value>1488</Value>
												<name>workerID</name>
											</items>
											<items>
												<Value>13371488</Value>
												<name>globalWorkerID</name>
											</items>
											<items>
												<Value>Bob Smith</Value>
												<name>fullName</name>
											</items>
											<items>
												<Value>2281337</Value>
												<name>deviceID</name>
											</items>
											<items>
												<Value>1888</Value>
												<name>someID</name>
											</items>
											<items>
												<Value>2020-01-04T12:11:11</Value>
												<name>DateTime</name>
											</items>
											<items>
												<Value>BATMAN!</Value>
												<name>KRIA</name>
											</items>
										</items>
									</filter>
								</FilterSet>'

	DECLARE @docHandle INT
	EXEC sp_xml_preparedocument @docHandle OUTPUT,  @xmlPart;

	WITH tmp(name, Value) AS ( SELECT name, Value FROM OPENXML(@docHandle, '/FilterSet/filter/items/items', 2) WITH (name NVARCHAR(64), Value NVARCHAR(64)))


	SELECT * FROM tmp
	PIVOT(
		MIN(Value) FOR name IN (interfaceLanguage, globalWorkerID, someID, fullName, KRIA)
	) as pvt

	EXEC sp_xml_removedocument @docHandle
END
GO

EXEC total
EXEC xmlTest

