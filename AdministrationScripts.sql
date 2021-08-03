USE StockAuction;

-- Functions for data manipulation
DELIMITER //

CREATE FUNCTION getBuyerNameFromAuction(
	buyerClientNumber smallint
)
RETURNS NCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE buyerName nchar(50);
    DECLARE buyerID nchar(10);
    
    SELECT clientID
    INTO buyerID
    FROM AuctionClientAtAuction
    WHERE buyerClientNumber = clientNumber
    LIMIT 1;

    SELECT fullName 
    INTO buyerName 
    FROM AuctionClient
    WHERE buyerID = id; 
    
    RETURN (buyerName);
END//

CREATE FUNCTION getSellerNameFromAuction(
	sellerClientNumber smallint
)
RETURNS NCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE sellerName nchar(50);
    DECLARE sellerID nchar(10);
    
    SELECT clientID
    INTO sellerID
    FROM AuctionClientAtAuction
    WHERE sellerClientNumber = clientNumber
    LIMIT 1;

    SELECT fullName 
    INTO sellerName 
    FROM AuctionClient
    WHERE sellerID = id; 
    
    RETURN (sellerName);
END//

CREATE FUNCTION getAgentNameFromAuction(
	agentID nchar(10)
)
RETURNS NCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE agentName nchar(50);

    SELECT fullName 
    INTO agentName 
    FROM StockAgent
    WHERE agentID = id; 
    
    RETURN (agentName);
END//

CREATE FUNCTION getAuctioneerNameFromAuction(
	auctioneerID nchar(10)
)
RETURNS NCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE auctioneerName nchar(50);
    
	SELECT fullName
    INTO auctioneerName
    FROM StockAgent
    WHERE auctioneerID = id;
    
    RETURN (auctioneerName);
END//

DELIMITER ;

-- Function tests
SELECT getBuyerNameFromAuction(57);
SELECT getSellerNameFromAuction(87);
SELECT getAgentNameFromAuction('P_Bar');
SELECT getAuctioneerNameFromAuction('F_Mic');

-- Views
CREATE VIEW CattleSold2020 AS 
SELECT lotNumber, getBuyerNameFromAuction(buyer) AS BuyerName, getSellerNameFromAuction(seller) AS SellerName, getAgentNameFromAuction(agent) AS AgentName, getAuctioneerNameFromAuction(auctioneer) AS AuctioneerName, quantity, breed, CONCAT('$', FORMAT(lotSellingPrice, 2)) AS SellingPriceOfLot
FROM CattleLot CL
INNER JOIN AuctionDay AD ON CL.auctionDay = AD.id
WHERE AD.auctionDay BETWEEN '2020-01-01' AND '2020-12-31' 
AND CL.lotSellingPrice IS NOT NULL;

CREATE VIEW SheepSold2020 AS 
SELECT lotNumber, getBuyerNameFromAuction(buyer) AS BuyerName, getSellerNameFromAuction(seller) AS SellerName, getAgentNameFromAuction(agent) AS AgentName, getAuctioneerNameFromAuction(auctioneer) AS AuctioneerName, quantity, breed, CONCAT('$', FORMAT(lotSellingPrice, 2)) AS SellingPriceOfLot
FROM SheepLot SL
INNER JOIN AuctionDay AD ON SL.auctionDay = AD.id
WHERE AD.auctionDay BETWEEN '2020-01-01' AND '2020-12-31' 
AND SL.lotSellingPrice IS NOT NULL;

-- View Tests
SELECT * FROM CattleSold2020;
SELECT * FROM SheepSold2020;

INSERT SheepLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer, buyer, sellingPricePerHead, passedIn) VALUES (N'S1620', 1619, 420, 38, N'P_Jan     ', N'Merino              ', N'R', 2, 65, NULL, N'P_Jan     ', 62, 88.0000, NULL); 

SELECT * FROM SheepSold2020;

-- Triggers
DROP TRIGGER TotalCattlePurchased_AI;
DROP TRIGGER TotalCattleSold_AI;
DROP TRIGGER TotalSheepPurchased_AI;
DROP TRIGGER TotalSheepSold_AI;

DELIMITER //
    
CREATE TRIGGER TotalCattlePurchased_AI
	AFTER INSERT ON CattleLot FOR EACH ROW
    BEGIN
    
		UPDATE AuctionClientAtAuction ACAA
		INNER JOIN CattleLot CL ON CL.auctionDay = ACAA.auctionId
		SET ACAA.valuePurchased = COALESCE(ACAA.valuePurchased + NEW.lotSellingPrice, lotSellingPrice)
		WHERE buyer = clientNumber;
            
		UPDATE AuctionClient AC
		INNER JOIN AuctionClientAtAuction ACAA ON ACAA.clientID = AC.id
		SET AC.assetsPurchasedAtAuctions = COALESCE(AC.assetsPurchasedAtAuctions + ACAA.valuePurchased, ACAA.valuePurchased)
		WHERE AC.id = ACAA.clientId;
        
	END//
    
CREATE TRIGGER TotalCattleSold_AI
	AFTER INSERT ON CattleLot FOR EACH ROW
    BEGIN
		
		UPDATE AuctionClientAtAuction ACAA
		INNER JOIN CattleLot CL ON CL.auctionDay = ACAA.auctionId
		SET ACAA.valueSold = COALESCE(ACAA.valueSold + NEW.lotSellingPrice, lotSellingPrice)
		WHERE seller = clientNumber;
            
		UPDATE AuctionClient AC
		INNER JOIN AuctionClientAtAuction ACAA ON ACAA.clientID = AC.id
		SET AC.assetsSoldAtAuctions = COALESCE(AC.assetsSoldAtAuctions + ACAA.valueSold, ACAA.valueSold)
		WHERE AC.id = ACAA.clientId;
        
	END//
    
CREATE TRIGGER TotalSheepPurchased_AI
	AFTER INSERT ON SheepLot FOR EACH ROW
    BEGIN
    
		UPDATE AuctionClientAtAuction ACAA
		INNER JOIN SheepLot SL ON SL.auctionDay = ACAA.auctionId
		SET ACAA.valuePurchased = COALESCE(ACAA.valuePurchased + NEW.lotSellingPrice, lotSellingPrice)
		WHERE buyer = clientNumber;
            
		UPDATE AuctionClient AC
		INNER JOIN AuctionClientAtAuction ACAA ON ACAA.clientID = AC.id
		SET AC.assetsPurchasedAtAuctions = COALESCE(AC.assetsPurchasedAtAuctions + ACAA.valuePurchased, ACAA.valuePurchased)
		WHERE AC.id = ACAA.clientId;
        
	END//
    
CREATE TRIGGER TotalSheepSold_AI
	AFTER INSERT ON SheepLot FOR EACH ROW
    BEGIN
		
		UPDATE AuctionClientAtAuction ACAA
		INNER JOIN CattleLot CL ON CL.auctionDay = ACAA.auctionId
		SET ACAA.valueSold = COALESCE(ACAA.valueSold + NEW.lotSellingPrice, lotSellingPrice)
		WHERE seller = clientNumber;
            
		UPDATE AuctionClient AC
		INNER JOIN AuctionClientAtAuction ACAA ON ACAA.clientID = AC.id
		SET AC.assetsSoldAtAuctions = COALESCE(AC.assetsSoldAtAuctions + ACAA.valueSold, ACAA.valueSold)
		WHERE AC.id = ACAA.clientId;
        
	END//
    
CREATE TRIGGER ClientAttendanceAtAuction_AI 
	AFTER INSERT ON AuctionClientAtAuction FOR EACH ROW
    BEGIN
        
        UPDATE AuctionClient AC
        SET ClientAttendanceAtAuctions = ( 
			SELECT COUNT(clientID) AS Counter
			FROM AuctionClientAtAuction ACAA
			INNER JOIN AuctionDay AD ON AD.id = ACAA.auctionId
			WHERE AC.id = ACAA.clientID AND AD.auctionDay >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
			GROUP BY clientID
            LIMIT 1
            );
	END//
    
DELIMITER ;

-- Trigger Tests
SHOW TRIGGERS; 

DROP TRIGGER ClientAttendanceAtAuction_AI;

SELECT * FROM AuctionClientAtAuction;
SELECT * FROM AuctionClient;

INSERT CattleLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, averageWeight, reserve, auctioneer, buyer, sellingPricePerKg, passedIn) VALUES (N'C1619', 1619, 271, 57, N'P_Jan     ', N'Angus               ', N'B', 2, 14,1023.00, NULL, N'P_Jan     ', 56, 5.1700, NULL);
INSERT SheepLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer, buyer, sellingPricePerHead, passedIn) VALUES (N'S1620', 1620, 450, 88, N'F_Mik     ', N'Romney              ', N'W', 3, 100, 75.0000, N'F_Mik     ', 61, 81.0000, NULL);
INSERT CattleLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, averageWeight, reserve, auctioneer, buyer, sellingPricePerKg, passedIn) VALUES (N'C1619', 1619, 272, 57, N'P_Jan     ', N'Angus               ', N'B', 2, 100,1023.00, NULL, N'P_Jan     ', 56, 5.1700, NULL);
DELETE FROM CattleLot WHERE lotNumber = 271;

SELECT * FROM AuctionClientAtAuction;
SELECT * FROM AuctionClient;

INSERT AuctionClientAtAuction (auctionId, clientNumber, clientID) VALUES (1619, 200, N'KIR77     ');
DELETE FROM AuctionClientAtAuction WHERE auctionId = 1619 AND clientNumber = 200;
SELECT * FROM AuctionClient;



-- Stored Procedures
DROP TABLE IF EXISTS ClientsAtAuction;
CREATE TEMPORARY TABLE ClientsAtAuction(
	theClientID nchar(10),
    theClientNumber SMALLINT UNSIGNED
);

LOAD DATA LOCAL INFILE 'C:/temp/mysql/SampleAuctionData/1621Clients.csv'
IGNORE INTO TABLE ClientsAtAuction 
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@nextId, @nextClientNumber)
SET theClientID = @nextID, theClientNumber = @nextClientNumber;

SELECT * FROM ClientsAtAuction;

DROP TABLE IF EXISTS C_AuctionPreSales;
CREATE TEMPORARY TABLE C_AuctionPreSales(
	theLotNumber smallint,
    theSeller smallint,
    theAgent nchar(10),
    theAuctioneer nchar(10),
    theBreed nchar(20),
    theSex nchar(1),
    theAge tinyint,
    theQuantity tinyint,
    theReserve decimal(5, 2)
);

DROP TABLE IF EXISTS S_AuctionPreSales;
CREATE TEMPORARY TABLE S_AuctionPreSales(
	theLotNumber smallint,
    theSeller smallint,
    theAgent nchar(10),
    theAuctioneer nchar(10),
    theBreed nchar(20),
    theSex nchar(1),
    theAge tinyint,
    theQuantity tinyint,
    theReserve smallint
);

DROP TABLE IF EXISTS C_AuctionPostSales;
CREATE TEMPORARY TABLE C_AuctionPostSales(
	theLotNumber smallint,
    theAvgWeight decimal(6, 2),
    theSellingPricePerKG decimal(5, 2),
    theBuyer smallint,
    thePassedIn bit
);

DROP TABLE IF EXISTS S_AuctionPostSales;
CREATE TEMPORARY TABLE S_AuctionPostSales(
	theLotNumber smallint,
    theBuyer smallint,
    theSellingPricePerHead decimal(5, 2),
    thePassedIn bit
);

-- Load cattle auction data
LOAD DATA LOCAL INFILE 'C:/temp/mysql/SampleAuctionData/C1621.csv'
IGNORE INTO TABLE C_AuctionPreSales
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@nextLotNumber, @nextSeller, @nextAgent, @nextAuctioneer, @nextBreed, @nextSex, @nextAge, @nextQuantity, @nextReserve)
SET theLotNumber = @nextLotNumber, theSeller = @nextSeller, theAgent = @nextAgent, theAuctioneer = @nextAuctioneer, theBreed = @nextBreed, theSex = @nextSex, theAge = @nextAge, theQuantity = @nextQuantity, theReserve = IF(@nextReserve = ' ', NULL, @nextReserve);

-- Load sheep auction data 
LOAD DATA LOCAL INFILE 'C:/temp/mysql/SampleAuctionData/S1621.csv'
IGNORE INTO TABLE S_AuctionPreSales
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@nextLotNumber, @nextSeller, @nextAgent, @nextAuctioneer, @nextBreed, @nextSex, @nextAge, @nextQuantity, @nextReserve)
SET theLotNumber = @nextLotNumber, theSeller = @nextSeller, theAgent = @nextAgent, theAuctioneer = @nextAuctioneer, theBreed = @nextBreed, theSex = @nextSex, theAge = @nextAge, theQuantity = @nextQuantity, theReserve = IF(@nextReserve = ' ', NULL, @nextReserve);

-- Load cattle post auction data
LOAD DATA LOCAL INFILE 'C:/temp/mysql/SampleAuctionData/C1621Sales.csv'
IGNORE INTO TABLE C_AuctionPostSales
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@nextLotNumber, @nextAvgWeight, @nextSellingPricePerKG, @nextBuyer, @nextPassedIn)
SET theLotNumber = @nextLotNumber, theAvgWeight = @nextAvgWeight, theSellingPricePerKG = IF(@nextSellingPricePerKG = ' ', NULL, @nextSellingPricePerKG), theBuyer = IF(@nextBuyer = ' ', NULL, @nextBuyer), thePassedIn = IF(@nextPassedIn = 1, 1, 0);

-- Load sheep post auction data
LOAD DATA LOCAL INFILE 'C:/temp/mysql/SampleAuctionData/S1621Sales.csv'
IGNORE INTO TABLE S_AuctionPostSales
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@nextLotNumber, @nextBuyer, @nextSellingPricePerHead, @nextPassedIn)
SET theLotNumber = @nextLotNumber, theSellingPricePerHead = IF(@nextSellingPricePerHead = ' ', NULL, @nextSellingPricePerHead), theBuyer = IF(@nextBuyer = ' ', NULL, @nextBuyer), thePassedIn = IF(@nextPassedIn = 1, 1, 0);

    
SELECT * FROM C_AuctionPreSales;
SELECT * FROM S_AuctionPreSales;
SELECT * FROM C_AuctionPostSales;
SELECT * FROM S_AuctionPostSales;

    
DELIMITER //

CREATE PROCEDURE CreateAuction(
	IN dateOfAuction date,
    IN auctionNumber smallint,
    IN typeOfAuction nchar(2)
)

BEGIN
    
    DECLARE auctionDayID smallint;
    
    SET FOREIGN_KEY_CHECKS = 0;

    SELECT id
    INTO auctionDayID
    FROM AuctionDay
    WHERE id = auctionNumber;
    
	INSERT INTO AuctionDay(id, auctionDay)
    VALUES (auctionNumber, dateOfAuction);
    
    IF (auctionDayID = auctionNumber) THEN
		CALL LoadClientsIntoAuction(auctionNumber);
	END IF;
    
	IF (typeOfAuction = 'C') THEN
		INSERT INTO CattleAuction(id, auctionID, startTime)
        VALUES (INSERT(auctionNumber, 1, 0, 'C'), auctionNumber, '11:00');
	END IF;
    
	IF (typeOfAuction = 'S') THEN
		INSERT INTO SheepAuction(id, auctionID, startTime)
        VALUES (INSERT(auctionNumber, 1, 0, 'S'), auctionNumber, '11:00');
	END IF;
    
	IF ((typeOfAuction = 'CS') OR (typeOfAuction = 'SC')) THEN
		INSERT INTO SheepAuction(id, auctionID, startTime)
        VALUES (INSERT(auctionNumber, 1, 0, 'S'), auctionNumber, '11:00');
		INSERT INTO CattleAuction(id, auctionID, startTime)
        VALUES (INSERT(auctionNumber, 1, 0, 'C'), auctionNumber, '11:00');
	END IF;
    
    SET FOREIGN_KEY_CHECKS = 1;
    
END//

CREATE PROCEDURE LoadClientsIntoAuction(
	IN auctionNumber smallint
)

BEGIN

	DECLARE finished tinyint default false;
    DECLARE newClientID nchar(5);
    DECLARE newClientNumber smallint;
	DECLARE curTheClients CURSOR FOR SELECT theClientID, theClientNumber FROM ClientsAtAuction;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;

    OPEN curTheClients;
    
    theLoop:
    LOOP
		FETCH curTheClients INTO newClientID, newClientNumber;
        IF (! finished) THEN
			    INSERT INTO AuctionClientAtAuction (auctionId, clientNumber, clientID)
				VALUES (auctionNumber, newClientNumber, newClientID);
		ELSE 
			LEAVE theLoop;
		END IF;
	END LOOP;
    
    CLOSE curTheClients;
    
    DROP TEMPORARY TABLE ClientsAtAuction;

END//

CREATE PROCEDURE LoadPresalesDataForAuction(
	IN auctionNumber smallint,
    IN typeOfAuction nchar(2)
)

BEGIN 

	DECLARE finished tinyint default false;
    DECLARE newLotNumber smallint;
    DECLARE newSeller smallint;
    DECLARE newAgent nchar(10);
    DECLARE newAuctioneer nchar(10);
    DECLARE newBreed nchar(20);
    DECLARE newSex nchar(1);
    DECLARE newAge tinyint;
    DECLARE newQuantity tinyint;
    DECLARE newReserve decimal(5,2);
    DECLARE curC_PreSalesData CURSOR FOR SELECT theLotNumber, theSeller, theAgent, theAuctioneer, theBreed, theSex, theAge, theQuantity, theReserve FROM C_AuctionPreSales;
    DECLARE curS_PreSalesData CURSOR FOR SELECT theLotNumber, theSeller, theAgent, theAuctioneer, theBreed, theSex, theAge, theQuantity, theReserve FROM S_AuctionPreSales;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;
    
    SET FOREIGN_KEY_CHECKS = 0;
    
    IF (typeOfAuction = 'C') THEN
		OPEN curC_PreSalesData;
    
		theLoop:
		LOOP
			FETCH curC_PreSalesData INTO newLotNumber, newSeller, newAgent, newAuctioneer, newBreed, newSex, newAge, newQuantity, newReserve;
			IF (! finished) THEN
				INSERT INTO CattleLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
				VALUES (INSERT(auctionNumber, 1, 0, 'C'), auctionNumber, newLotNumber, newSeller, newAgent, newBreed, newSex, newAge, newQuantity, newReserve, newAuctioneer);
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
    
		CLOSE curC_PreSalesData;
        
        DROP TEMPORARY TABLE C_AuctionPreSales;
	END IF;
    
    IF (typeOfAuction = 'S') THEN    
		OPEN curS_PreSalesData;
    
		theLoop:
		LOOP
			FETCH curS_PreSalesData INTO newLotNumber, newSeller, newAgent, newAuctioneer, newBreed, newSex, newAge, newQuantity, newReserve;
			IF (! finished) THEN
				INSERT INTO SheepLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
				VALUES (INSERT(auctionNumber, 1, 0, 'S'), auctionNumber, newLotNumber, newSeller, newAgent, newBreed, newSex, newAge, newQuantity, newReserve, newAuctioneer);
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
    
		CLOSE curS_PreSalesData;
        
        DROP TEMPORARY TABLE S_AuctionPreSales;
	END IF;
    
	IF ((typeOfAuction = 'CS') OR (typeOfAuction = 'SC')) THEN
		OPEN curC_PreSalesData;
    
		theLoop:
		LOOP
			FETCH curC_PreSalesData INTO newLotNumber, newSeller, newAgent, newAuctioneer, newBreed, newSex, newAge, newQuantity, newReserve;
			IF (! finished) THEN
				INSERT INTO CattleLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
				VALUES (INSERT(auctionNumber, 1, 0, 'C'), auctionNumber, newLotNumber, newSeller, newAgent, newBreed, newSex, newAge, newQuantity, newReserve, newAuctioneer);
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
    
		CLOSE curC_PreSalesData;

		OPEN curS_PreSalesData;
    
		theLoop:
		LOOP
			FETCH curS_PreSalesData INTO newLotNumber, newSeller, newAgent, newAuctioneer, newBreed, newSex, newAge, newQuantity, newReserve;
			IF (! finished) THEN
				INSERT INTO SheepLot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
				VALUES (INSERT(auctionNumber, 1, 0, 'S'), auctionNumber, newLotNumber, newSeller, newAgent, newBreed, newSex, newAge, newQuantity, newReserve, newAuctioneer);
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
    
		CLOSE curS_PreSalesData;
        
        DROP TEMPORARY TABLE C_AuctionPreSales;
        DROP TEMPORARY TABLE S_AuctionPreSales;
	END IF;
    
    SET FOREIGN_KEY_CHECKS = 1;
    
END//
    
CREATE PROCEDURE LoadPostSalesDataForAuction(
	IN auctionNumber smallint,
    IN typeOfAuction nchar(2)
)

BEGIN
	
    DECLARE finished tinyint default false;
    DECLARE newLotNumber smallint;
    DECLARE newBuyer smallint;
    DECLARE newAvgWeight decimal(6, 2);
    DECLARE newSellingPricePerKG decimal(5, 2);
    DECLARE newSellingPricePerHead decimal(5, 2);
    DECLARE newPassedIn bit;
	DECLARE curC_PostSalesData CURSOR FOR SELECT theLotNumber, theAvgWeight, theSellingPricePerKG, theBuyer, thePassedIn FROM C_AuctionPostSales;
    DECLARE curS_PostSalesData CURSOR FOR SELECT theLotNumber, theSellingPricePerHead, theBuyer, thePassedIn FROM S_AuctionPostSales;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;
    
    SET FOREIGN_KEY_CHECKS = 0;
    
    IF (typeOfAuction = 'C') THEN
		OPEN curC_PostSalesData;
        
        theLoop:
        LOOP
			FETCH curC_PostSalesData INTO newLotNumber, newAvgWeight, newSellingPricePerKG, newBuyer, newPassedIn;
            IF (! finished) THEN
				UPDATE CattleLot
                SET averageWeight = newAvgWeight, sellingPricePerKg = newSellingPricePerKG, buyer = newBuyer, passedIn = newPassedIn
                WHERE newLotNumber = lotNumber;
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
        
		CLOSE curC_PostSalesData;
        
        DROP TEMPORARY TABLE C_AuctionPostSales;
	END IF;
    
	IF (typeOfAuction = 'S') THEN
		OPEN curS_PostSalesData;
        
        theLoop:
        LOOP
			FETCH curS_PostSalesData INTO newLotNumber, newSellingPricePerHead, newBuyer, newPassedIn;
            IF (! finished) THEN
				UPDATE SheepLot
                SET sellingPricePerHead = newSellingPricePerHead, buyer = newBuyer, passedIn = newPassedIn
                WHERE newLotNumber = lotNumber;
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
        
		CLOSE curC_PostSalesData;
        
        DROP TEMPORARY TABLE C_AuctionPostSales;
	END IF;

	IF ((typeOfAuction = 'CS') OR (typeOfAuction = 'SC')) THEN
		OPEN curC_PostSalesData;
        
        theLoop:
        LOOP
			FETCH curC_PostSalesData INTO newLotNumber, newAvgWeight, newSellingPricePerKG, newBuyer, newPassedIn;
            IF (! finished) THEN
				UPDATE CattleLot
                SET averageWeight = newAvgWeight, sellingPricePerKg = newSellingPricePerKG, buyer = newBuyer, passedIn = newPassedIn
                WHERE newLotNumber = lotNumber;
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
        
		CLOSE curC_PostSalesData;
        
		OPEN curS_PostSalesData;
        
        theLoop:
        LOOP
			FETCH curS_PostSalesData INTO newLotNumber, newSellingPricePerHead, newBuyer, newPassedIn;
            IF (! finished) THEN
				UPDATE SheepLot
                SET sellingPricePerHead = newSellingPricePerHead, buyer = newBuyer, passedIn = newPassedIn
                WHERE newLotNumber = lotNumber;
			ELSE
				LEAVE theLoop;
			END IF;
		END LOOP;
        
		CLOSE curC_PostSalesData;

		DROP TEMPORARY TABLE C_AuctionPostSales;
		DROP TEMPORARY TABLE S_AuctionPostSales;
	END IF;
    
    SET FOREIGN_KEY_CHECKS = 1;
    
END//

CREATE PROCEDURE TotalLotValuePurchased(
	IN buyerNumber smallint,
    IN typeOfLot char(2),
    OUT totalValuePurchased decimal(12, 2)
    )
    
    BEGIN
		
        IF (typeOfLot = 'C') THEN
			SELECT buyer, SUM(lotSellingPrice) AS totalValuePurchased
			FROM CattleLot CL
            WHERE CL.buyer = buyerNumber;
		END IF;
        
        IF (typeOfLot = 'S') THEN
			SELECT buyer, SUM(lotSellingPrice) AS totalValuePurchased
			FROM SheepLot SL
            WHERE SL.buyer = buyerNumber;
		END IF;
        
        IF ((typeOfLot = 'CS') OR (typeOfLot = 'SC')) THEN
			SELECT buyer, SUM(lotSellingPrice) AS totalValuePurchased
            FROM ( 
            SELECT buyer, lotSellingPrice FROM CattleLot
			UNION ALL
            SELECT buyer, lotSellingPrice FROM SheepLot
                ) T
			WHERE T.buyer = buyerNumber
            GROUP BY T.buyer;
		END IF;
	
    END//
    
CREATE PROCEDURE TotalLotValueSold(
	IN sellerNumber smallint,
    IN typeOfLot char(2),
    OUT totalValueSold decimal(12, 2)
    )
    
    BEGIN
		
        IF (typeOfLot = 'C') THEN
			SELECT seller, SUM(lotSellingPrice) AS totalValueSold
			FROM CattleLot CL
            WHERE CL.seller = sellerNumber;
		END IF;
        
        IF (typeOfLot = 'S') THEN
			SELECT seller, SUM(lotSellingPrice) AS totalValueSold
			FROM SheepLot SL
            WHERE SL.seller = sellerNumber;
		END IF;
        
        IF ((typeOfLot = 'CS') OR (typeOfLot = 'SC')) THEN
			SELECT seller, SUM(lotSellingPrice) AS totalValueSold
            FROM ( 
            SELECT seller, lotSellingPrice FROM CattleLot
			UNION ALL
            SELECT seller, lotSellingPrice FROM SheepLot
                ) T
			WHERE T.seller = sellerNumber
            GROUP BY T.seller;
		END IF;
	
    END//

DELIMITER ;

-- Stored Procedures tests
DROP PROCEDURE CreateAuction;
DROP PROCEDURE LoadClientsIntoAuction;
DROP PROCEDURE LoadPresalesDataForAuction;
DROP PROCEDURE TotalLotValuePurchased;
DROP PROCEDURE TotalLotValueSold;

CALL CreateAuction('2020-09-13', 1621, 'CS');
CALL CreateAuction('2020-09-13', 1621, 'S');
DELETE FROM AuctionDay WHERE id = 1621;
DELETE FROM AuctionClientAtAuction WHERE auctionId = 1621;
DELETE FROM SheepLot WHERE auctionId = 'S1621';
SELECT * FROM CattleAuction;
SELECT * FROM SheepAuction;
SELECT * FROM AuctionDay;

CALL TotalLotValuePurchased(56, 'C', @totalValue);
CALL TotalLotValuePurchased(56, 'S', @totalValue);
CALL TotalLotValuePurchased(56, 'SC', @totalValue);

CALL TotalLotValueSold(57, 'C', @totalValue);
CALL TotalLotValueSold(57, 'S', @totalValue);
CALL TotalLotValueSold(57, 'CS', @totalValue);

-- Stored Procedure loading data tests
CALL LoadClientsIntoAuction(1621);
CALL LoadPresalesDataForAuction(1621, 'C');
CALL LoadPostSalesDataForAuction(1621, 'C');
SELECT * FROM ClientsAtAuction;
SELECT * FROM AuctionClient;
SELECT * FROM AuctionClientAtAuction;
SELECT * FROM AuctionDay;
SELECT * FROM CattleLot;
SELECT * FROM SheepLot;

-- Indexes
CREATE UNIQUE INDEX index_cattleDayAndLot
ON CattleLot (auctionDay, lotNumber);

CREATE UNIQUE INDEX index_sheepDayAndLot
ON SheepLot (auctionDay, lotNumber);

CREATE UNIQUE INDEX index_auctionAndClient
ON AuctionClientAtAuction (auctionID, clientNumber);

ANALYZE TABLE CattleLot;
ANALYZE TABLE SheepLot;
ANALYZE TABLE AuctionClientAtAuction;

-- Index Tests
SHOW INDEXES FROM CattleLot; 
SHOW INDEXES FROM SheepLot; 
SHOW INDEXES FROM AuctionClientAtAuction; 

SELECT *
FROM CattleLot
USE INDEX (index_cattleDayAndLot)
WHERE auctionDay = 1619 AND lotNumber = 9;

EXPLAIN SELECT *
FROM CattleLot
USE INDEX (index_cattleDayAndLot)
WHERE auctionDay = 1619 AND lotNumber = 9;

SELECT *
FROM SheepLot
USE INDEX (index_sheepDayAndLot)
WHERE auctionDay = 1620 AND lotNumber = 236;

EXPLAIN SELECT *
FROM SheepLot
USE INDEX (index_sheepDayAndLot)
WHERE auctionDay = 1620 AND lotNumber = 236;

SELECT *
FROM AuctionClientAtAuction
USE INDEX (index_auctionAndClient)
WHERE auctionID = 1619 AND clientNumber = 56;

EXPLAIN SELECT *
FROM AuctionClientAtAuction
USE INDEX (index_auctionAndClient)
WHERE auctionID = 1619 AND clientNumber = 56;

-- //******************** Security ********************\\

CREATE USER IF NOT EXISTS 'AuctionCreator'@'localhost' IDENTIFIED BY 'AuctionCreator';
CREATE USER IF NOT EXISTS 'ClientLoader'@'localhost' IDENTIFIED BY 'ClientLoader';
CREATE USER IF NOT EXISTS 'StockLoader'@'localhost' IDENTIFIED BY 'StockLoader';
CREATE USER IF NOT EXISTS 'AuctionDayDataEntry'@'localhost' IDENTIFIED BY 'AuctionDayDataEntry';
CREATE USER IF NOT EXISTS 'AuctionDaySupervisor'@'localhost' IDENTIFIED BY 'AuctionDaySupervisor';
CREATE USER IF NOT EXISTS 'SaleDayAdmin'@'localhost' IDENTIFIED BY 'SaleDayAdmin';
CREATE USER IF NOT EXISTS 'Reporter'@'localhost' IDENTIFIED BY 'Reporter';
CREATE USER IF NOT EXISTS 'DailyReporter'@'localhost' IDENTIFIED BY 'DailyReporter';

GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionDay TO 'AuctionCreator'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.CattleAuction TO 'AuctionCreator'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.SheepAuction TO 'AuctionCreator'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.CreateAuction TO 'AuctionCreator'@'localhost';
SHOW GRANTS FOR 'AuctionCreator'@'localhost';

GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClient TO 'ClientLoader'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClientAtAuction TO 'ClientLoader'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadClientsIntoAuction TO 'ClientLoader'@'localhost';
SHOW GRANTS FOR 'ClientLoader'@'localhost';

GRANT SELECT, INSERT, UPDATE ON StockAuction.CattleLot TO 'StockLoader'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.SheepLot TO 'StockLoader'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadPresalesDataForAuction  TO 'StockLoader'@'localhost';
SHOW GRANTS FOR 'StockLoader'@'localhost';

GRANT SELECT, UPDATE ON StockAuction.CattleLot TO 'AuctionDayDataEntry'@'localhost';
GRANT SELECT, UPDATE ON StockAuction.SheepLot TO 'AuctionDayDataEntry'@'localhost';
SHOW GRANTS FOR 'AuctionDayDataEntry'@'localhost';

GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionDay TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.CattleAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.SheepAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClient TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClientAtAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.CattleLot TO 'AuctionDaySupervisor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON StockAuction.SheepLot TO 'AuctionDaySupervisor'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.CreateAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadClientsIntoAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadPresalesDataForAuction TO 'AuctionDaySupervisor'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadPostSalesDataForAuction TO 'AuctionDaySupervisor'@'localhost';
SHOW GRANTS FOR 'AuctionDaySupervisor'@'localhost';

-- can add grant option but user unlikely to be granting privileges 
GRANT ALL ON StockAuction.* TO 'SaleDayAdmin'@'localhost'; -- WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE StockAuction.CreateAuction TO 'SaleDayAdmin'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadClientsIntoAuction TO 'SaleDayAdmin'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadPresalesDataForAuction TO 'SaleDayAdmin'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadPostSalesDataForAuction TO 'SaleDayAdmin'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValuePurchased TO 'SaleDayAdmin'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValueSold TO 'SaleDayAdmin'@'localhost';
SHOW GRANTS FOR 'SaleDayAdmin'@'localhost';

GRANT SELECT ON StockAuction.* TO 'Reporter'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValuePurchased TO 'Reporter'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValueSold TO 'Reporter'@'localhost';
SHOW GRANTS FOR 'Reporter'@'localhost';

GRANT SELECT ON StockAuction.CattleSold2020 TO 'DailyReporter'@'localhost';
GRANT SELECT ON StockAuction.SheepSold2020 TO 'DailyReporter'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValuePurchased TO 'DailyReporter'@'localhost';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValueSold TO 'DailyReporter'@'localhost';
SHOW GRANTS FOR 'DailyReporter'@'localhost';

CREATE ROLE IF NOT EXISTS 'ClientLoader_role', 'AuctionDayDataEntry_role', 'Reporter_role';

GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClient TO 'ClientLoader_role';
GRANT SELECT, INSERT, UPDATE ON StockAuction.AuctionClientAtAuction TO 'ClientLoader_role';
GRANT EXECUTE ON PROCEDURE StockAuction.LoadClientsIntoAuction TO 'ClientLoader_role';
SHOW GRANTS FOR 'ClientLoader_role';

GRANT SELECT, UPDATE ON StockAuction.CattleLot TO 'AuctionDayDataEntry_role';
GRANT SELECT, UPDATE ON StockAuction.SheepLot TO 'AuctionDayDataEntry_role';
SHOW GRANTS FOR 'AuctionDayDataEntry_role';

GRANT SELECT ON StockAuction.* TO 'Reporter_role';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValuePurchased TO 'Reporter_role';
GRANT EXECUTE ON PROCEDURE StockAuction.TotalLotValueSold TO 'Reporter_role';
SHOW GRANTS FOR 'Reporter_role';

-- Granting index rebuilding
CREATE USER IF NOT EXISTS 'DatabaseEngineer'@'localhost' IDENTIFIED BY 'DatabaseEngineer';
GRANT INDEX ON StockAuction.CattleLot TO 'DatabaseEngineer'@'localhost';
GRANT INDEX ON StockAuction.SheepLot TO 'DatabaseEngineer'@'localhost';
GRANT INDEX ON StockAuction.AuctionClientAtAuction TO 'DatabaseEngineer'@'localhost';
SHOW GRANTS FOR 'DatabaseEngineer'@'localhost';
