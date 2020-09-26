/*

# <Account Manbirthdayment System>
# This program is for handling financial tasks; More specifically, you can input, store, inquire account informations(revenue, expenditure).
# This code "server.sql" performs things below:
#   1. get requirements from "client.py" through stored procedure calls or SQL given by string type,
#   2. handle requirements(mainly CRUD) and inquire DBMS using stored procedure,
#   3. get replies(SELECT) from DBMS
#   * This program uses MySQL Ver 14.14 Distrib 5.7.30, for Linux (x86_64) using EditLine wrapper.
#   * This program was designed to run on Ubuntu Server 20.04 LTS (Linux 64bit). 

# Developers : Eungwang Yang, Yechan Lee
# Development started : from 2020.07.05. - now
# program version 0.0.0. (On development, core functionalities not yet completed)

*/

CREATE DATABASE IF NOT EXISTS DB_COM DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE DB_COM;		-- DB: 천성교회의 교인, 일정 등을 관리하기 위한 테이블들을 모아 놓은 general한 목적의 데이터베이스.

/* ================================================================================================================================= */

/* Users Table: 교인 정보 관리
   Users table을 관리하기 위한 프로시저는 INS_Users(insert), DEL_Users(delete), UPD_Users(update), GET_Users(get info of only one person)으로,
   서버 컴퓨터의 하드웨어 스펙이 부족한 만큼 대부분의 일을 클라이언트에서 처리하기 위함이다.
   
   ** 주의: procedure의 input data validity는 client.py에서 검사해야 한다.
   여기에 구현된 procedure에서는 값이 NULL로 주어졌는지 정도만 검사하고, 잘못된 data의 input으로 인한 예상치 못한 결과에 대해서는 보장할 수 없음.
 */

CREATE TABLE IF NOT EXISTS T_USER
(
	userid VARCHAR(100) NOT NULL,		-- 아이디
	password varchar(255),				-- 비번
    name varchar(100) NOT NULL,			-- 이름
    phoneNumber varchar(255),			-- 전화번호 hyphen('-') is not included
    address varchar(255),				-- 주소
    position varchar(255),				-- 직분
    birthday date,						-- 생년월일
	comments varchar(255),				-- 비고
    PRIMARY KEY PK(userid)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;	-- 한글 사용 가능

/* INS_Users Procedure: 성공 시 return 0, 실패 시 return -1 */
DROP PROCEDURE IF EXISTS INS_Users;
DELIMITER $$
CREATE PROCEDURE INS_Users
(
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255), 
    _address VARCHAR(255), 
    _part VARCHAR(255), 
    _position VARCHAR(255),
	_birthday VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255)
)
INS_Users_Label: BEGIN
	/* 해당 정보를 가진 사람의 name이 이미 존재한다면, -- update instead */
	IF (
			SELECT COUNT(phoneNumber) FROM Users
            WHERE phoneNumber = _phoneNumber
		) >= 1
        OR
        (
			SELECT COUNT(name) FROM Users
            WHERE name = _name
		) >= 1
	THEN
		CALL UPD_Users(_name, _phoneNumber, _address, _part, _position, _birthday, _id, _password);
        SELECT -1, _name, 'Insert하려는 대상의 이름, 혹은 전화번호가 이미 테이블에 존재합니다. 대신 주어진 정보를 이용해 Update했습니다.';
        LEAVE INS_Users_Label;
    END IF;
    
	/* id와 password의 default 값을 각각 교인 이름과 0000으로 설정 */
	IF _id = NULL THEN
        SET _id = _name;
	END IF;
	IF _password = NULL THEN
		SET _password = '0000';
	END IF;
    
    START TRANSACTION;
	INSERT INTO Users(name, address, phoneNumber, part, position, birthday, id, password)
	VALUE(_name, _address, _phoneNumber, _part, _position, _birthday, _id, _password);
	COMMIT;
    
    SELECT 0, _name, 'insert done';
END$$
DELIMITER ;

/* UPD_Users Procedure : 입력받은 name을 이용하여, 그 name을 가진 사람의 정보를 수정함. 만약 사람의 이름 자체를 바꾸고자 하는 경우에는 DEL_Users를 사용
   만약 (phoneNumber를 포함하지 않는) 입력 parameter 중 여러 개가 NULL로 주어질 경우, 값을 바꾸지 않음.
 */
DROP PROCEDURE IF EXISTS UPD_Users;
DELIMITER $$
CREATE PROCEDURE UPD_Users
(
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255), 
    _address VARCHAR(255), 
    _part VARCHAR(255), 
    _position VARCHAR(255),
	_birthday VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255), 
)
UPD_Users_Label: BEGIN
	-- check if more than one parameter of (_name or _phoneNumber) is(are) given
	IF _name IS NULL THEN
		IF _phoneNumber IS NULL THEN
			SELECT -1, '이름, 혹은 전화번호 parameter 중 적어도 하나의 값이 주어져야 합니다.';
			LEAVE UPD_Users_Label;
		ELSE
			SET _name = (SELECT name FROM Users WHERE phoneNumber = _phoneNumber);
        END IF;
	END IF;
    
    -- update할 대상이 존재하는지 check
    IF 
    (
		SELECT COUNT(name) FROM Users
		WHERE name = _name
	) = 0 
    THEN
		SELECT -1, _name, 'update할 대상(_name)이 존재하지 않습니다.';
		LEAVE UPD_Users_Label;
    END IF;
    
	/* If input parameter is given as NULL, do not change value */
	START TRANSACTION;
    UPDATE Users
	SET 
		address = COALESCE(_address, address),
		part = COALESCE(_part, part),
		position = COALESCE(_position, position), 
        birthday = COALESCE(_birthday, birthday),
		id = COALESCE(_id, id),
		password = COALESCE(_password, password)
	WHERE name = _name;
	COMMIT;
    
    SELECT 0, _name, 'update done';
END$$
DELIMITER ;

/* DEL_Users: name과 phoneNumber 둘이 primary key(PK)이므로, 입력된 _name 혹은 _phoneNumber를 가진 user 정보를 삭제.
   따라서 name과 phoneNumber 둘 중 하나를 NULL로 비워 놓아도 됨.
*/
DROP PROCEDURE IF EXISTS DEL_Users;
DELIMITER $$
CREATE PROCEDURE DEL_Users 
(
	IN _name VARCHAR(255), 
	_phoneNumber VARCHAR(255)
)
BEGIN
    IF _phoneNumber IS NULL THEN
		START TRANSACTION;
        DELETE FROM Users 
        WHERE name = _name;
        COMMIT;
        
		SELECT 0, _name, 'delete done';
    ELSEIF _name IS NULL THEN
		START TRANSACTION;
		DELETE FROM Users 
        WHERE phoneNumber = _phoneNumber;
        COMMIT;
        
		SELECT 0, (SELECT name FROM User WHERE phoneNumber = _phoneNumber), 'delete done';
    ELSE
        SELECT -1, '이름, 혹은 전화번호 parameter는 NULL 값이 될 수 없습니다.';
	END IF;
END$$
DELIMITER ;

/* GET_Users: only 한 사람이 가진 정보만을 return받기 위한 함수. 
   DEL_Users와 비슷한 mechanism으로, name이나 phoneNumber 둘 중 하나 이상을 입력 parameter로 받는다.
   GET하지 못했을 때 -1을 SELECT
*/
DROP PROCEDURE IF EXISTS GET_Users;
DELIMITER $$
CREATE PROCEDURE GET_Users 
(
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255)
)
BEGIN
    IF _name IS NOT NULL THEN
		SELECT name, phoneNumber, address, part, position, birthday, id, password 
        FROM Users 
        WHERE name = _name;
    ELSEIF _phoneNumber IS NOT NULL THEN
        SELECT name, phoneNumber, address, part, position, birthday, id, password 
        FROM Users 
        WHERE phoneNumber = (
			SELECT phoneNumber FROM (
					SELECT phoneNumber FROM Users 
					WHERE name = _name
				) temp
			); -- get information of whom having name '_name', using phoneNumber(PK)
    ELSE
		SELECT -1, '이름, 혹은 전화번호 parameter 중 하나의 값이 존재해야 합니다.';
	END IF;
END$$
DELIMITER ;

/* for debugging */
/*
SET @name = '이예찬';
SET @phoneNumber = '01021156036';
SET @address = '충청남도 계룡시 장안로 75, 109동 1404호';
-- insert User
CALL INS_Users(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL);

SET @name = '양은광';
SET @phoneNumber = '01028885479';
SET @address = '대전광역시 대덕구 관평동 그다음은 모름';
-- insert User
CALL INS_Users(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL);
SELECT * FROM Users;

-- update User
SET @newAddress = '대전광역시 서구 방동 593번지';
CALL UPD_Users(@name, @phoneNumber, @newAddress, NULL, NULL, NULL, NULL, NULL);
SELECT * FROM Users;

-- delete User
CALL DEL_Users(@name, NULL);
SELECT * FROM Users;	

CALL UPD_Users('이예성', '01021946031', '충청남도 계룡시 장안로 75, 109동 1404호', NULL, "청년부", "19", NULL, NULL);
SELECT * FROM Users;
*/

/* ================================================================================================================================= */

/*
 Accounts(회계정보)를 담당하는 데이터베이스와 프로시져.
 - Accounts는 account2020, account2021, ... 등의 table로 이뤄져 있으며,
 - procedure의 종류로는 
   Create_Accounts_Table, INS_Accounts, INS_Middle_Accounts, DEL_Accounts, GET_LIST_Accounts_By_Id, GET_LIST_Accounts,
   INS_Accounts_Id_Table, GET_Accounts_Id_Table, UPD_Accounts_ID_Table이 있음.
   회계 프로그램에서 Update 혹은 Delete보다는 마지막 행에 Insert하는 작업과 조회(GET_LIST)하는 작업이 가장 주를 이룬다는 것을 고려해, 위와 같이 procedure의 종류를 결정함.
 
 - INSERT의 경우 INS_Accounts (맨 마지막 행에 insert)와 INS_Middle_Accounts(중간 행에 insert한 뒤 그 다음에 오는 모든 행들의 id를 1씩 증가시킴)으로 나뉨.
   INSERT를 맨 마지막 행에 하는 경우가 대부분이므로, 대부분의 경우에서 id를 증가시키는 overhead를 줄이기 위함임.
   client.py에서는 엑셀 형식이든, 표 형식이든 정리된 데이터들을 정리할 때 (client 단에서 저장 버튼을 눌렀을 때) 날짜 순서대로 정렬한 뒤 순서대로 Accounts DB에 insert하도록 하는 작업이 필요. 
   저장 단계에서 정렬함으로써 Accounts database에서 검색, 조회가 빠르게 하도록 하기 위함.
 - DELETE의 경우 중간에 있는 element를 삭제하는 경우가 대부분이므로, 중간의 데이터를 삭제한다고 상정함. 
   INS_Middle_Account와 정반대 동작을 수행하며, 중간 행을 delete한 뒤 그 다음에 오는 모든 행들의 id를 1씩 감소시킴.
 - UPDATE의 경우 DELETE 후 INSERT_Middle함으로써 동작.
 - GET_LIST_Accounts_By_Id: 연속적 데이터 불러오기에 사용.
   특히 월별로 records를 get하는 경우가 많으므로, DB에 1월달 record 시작 id, 2월달 record 시작 id, ...를 저장해 놓음.
   client 프로그램이 시작하면 DB에서 id table을 불러오고, client에서 1.records 저장 시, 2.프로그램 종료 시 id table을 갱신해 DB에 저장.
 - GET_LIST_Accounts: 연속적이지 않은 데이터 불러오기, e.g. 조건검색에 사용.
*/

CREATE DATABASE IF NOT EXISTS DB_ACC DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE DB_ACC;

/* ================================================================================================================================= */

/* Accounts_Table: 회계 정보 테이블들을 연도 별로 저장
   related procedures
	- Create_Accounts_Table: 프로그램 사용 중 연도가 늘어날 때 호출
    - INS_Accounts, INS_Middle_Accounts, UPD_Accounts, DEL_Accounts, GET_LIST_Accounts
*/
DROP PROCEDURE IF EXISTS Create_Accounts_Table;
DELIMITER $$
CREATE PROCEDURE Create_Accounts_Table
(
	IN tableName VARCHAR(255)
)
BEGIN
	SET @table := tableName;
	SET @sql_text := 
    CONCAT (
		'CREATE TABLE IF NOT EXISTS ',@table,
        '(
			id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
			month INT(2) NOT NULL,
			date INT(2) NOT NULL,
			amount BIGINT NOT NULL,
			name VARCHAR(255) NOT NULL,
			purpose VARCHAR(255),
			purposeDetail VARCHAR(255),
			others VARCHAR(255)
        ) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;'
	);
	PREPARE stmt from @sql_text;
	EXECUTE stmt;
END$$
DELIMITER ;

-- CALL Create_Account_Table('account2020');

/* INS_Accounts: 회계 내역을 insert. tableName, month, date, amount, name은 모두 NULL이 아니어야 함 */
DROP PROCEDURE IF EXISTS INS_Accounts;
DELIMITER $$
CREATE PROCEDURE INS_Accounts
(
	IN 
    _tableName VARCHAR(255),
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name varchar(255),
	_purpose varchar(255),
	_purposeDetail VARCHAR(255),
	_others varchar(255)
)
INS_Accounts_Label: BEGIN
	-- month, date, amount 셋 중 하나가 NULL value이면 오류
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) OR (_name = NULL)THEN
		SELECT -1, 'tableName, month, date, amount parameter는 모두 NULL이 아니어야 합니다.';
        LEAVE INS_Accounts_Label;        
	END IF;

    SET @table := _tableName;
	SET @sql_text := 
    CONCAT (
		'INSERT INTO ',@table,'(month, date, amount, name, purpose, purposeDetail, others)
        VALUE(_month, _date, _amount, _name, _purpose, _purposeDetail, _others);'
	);
	PREPARE stmt from @sql_text;
    START TRANSACTION;
	EXECUTE stmt;
    COMMIT;
    SELECT 0, CONCAT(_month, '/', _date, ', ', _amount, ' won'), 'insert done';
END$$
DELIMITER ;

/* INS_Accounts: 회계 내역을 insert. tableName, month, date, amount는 모두 NULL이 아니어야 함 */
DROP PROCEDURE IF EXISTS INS_Middle_Accounts;
DELIMITER $$
CREATE PROCEDURE INS_Middle_Accounts
(
	IN 
    _tableName VARCHAR(255),
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name varchar(255),
	_purpose varchar(255),
	_purposeDetail VARCHAR(255),
	_others varchar(255),
    _insertId int
)
INS_Middle_Accounts_Label: BEGIN
	-- month, date, amount 셋 중 하나가 NULL value이면 오류
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) OR (_name = NULL) OR (_insertId = NULL) THEN
		SELECT -1, 'tableName, month, date, amount, name, insertId parameter는 모두 NULL이 아니어야 합니다.';
        LEAVE INS_Middle_Accounts_Label;
	END IF;

    SET @table := _tableName;
    SET @id := _insertId;
	SET @sql_text := 
    CONCAT (
		'UPDATE ', @table, ' SET id = id + 1 WHERE id >= ', @id, ' ORDER BY id DESC;	
		INSERT INTO ', @table, ' (id, month, date, amount, name, purpose, purposeDetail, others) 
		VALUES (', @id, ', _month, _date, _amount, _name, _purpose, _purposeDetail, _others);
	'); -- 'ORDER BY id DESC' makes records start with the highest ids first
    
	PREPARE stmt from @sql_text;
    START TRANSACTION;
	EXECUTE stmt;
    COMMIT;
    
    SELECT 0, CONCAT(_month, '/', _date, ', ', _amount, ' won'), 'insert done';
END$$
DELIMITER ;

/* DEL_Accounts */
DROP PROCEDURE IF EXISTS DEL_Accounts;
DELIMITER $$
CREATE PROCEDURE DEL_Accounts
(
	IN 
    _tableName VARCHAR(255),
	_id INT
)
DEL_Accounts_Label: BEGIN
	IF (_tableName = NULL) OR (_id = NULL) THEN
		SELECT -1, 'tableName, id는 모두 NULL이 아니어야 합니다.';
		LEAVE DEL_Accounts_Label;
    END IF;
    
	SET @table := tableName;
    SET @sql_text := 
    CONCAT ('
		DELETE FROM ', @table, ' WHERE id = ', @id, ' ;
		UPDATE ', @table, ' SET id = id - 1 WHERE id >= ', @id, ' ORDER BY id DESC;
    ');
        
	PREPARE stmt from @sql_text;
    START TRANSACTION;
	EXECUTE stmt;
    COMMIT;

    SELECT 0, CONCAT('table: ', @table, ', id: ', _id, '; delete done');
END$$
DELIMITER ;

/* UPD_Accounts: 자주 사용되지 않는 기능이라서 일단 DEL 후 UPD하는 방식으로 구현해놓았음. 이후 수정 바람 */
DROP PROCEDURE IF EXISTS UPD_Accounts;
DELIMITER $$
CREATE PROCEDURE UPD_Accounts
(
	IN 
    _tableName VARCHAR(255),
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name VARCHAR(255),
	_purpose VARCHAR(255),
	_purposeDetail VARCHAR(255),
	_others VARCHAR(255),
    _id INT
)
UPD_Accounts_Label: BEGIN
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) OR (_name = NULL) THEN
		SELECT -1, 'tableName, month, date, amount, name parameter는 모두 NULL이 아니어야 합니다.';
		LEAVE UPD_Accounts_Label;
    END IF;
    
    CALL DEL_Accounts(_tableName, _id);
	CALL INS_Middle_Accounts(_tableName, _month, _date, _amount, _name, _purpose, _purposeDetail, _others, _id);
    
    SELECT 0, CONCAT(_month, '/', _date, ', ', _amount, ' won'), 'update done';
END$$
DELIMITER ;

/* GET_LIST_Accounts_By_Id: 연속된 데이터를 불러올 때 호출 (e.g. 월별, 연도별 데이터 호출), recommended */
DROP PROCEDURE IF EXISTS GET_LIST_Accounts_By_Id;
DELIMITER $$
CREATE PROCEDURE GET_LIST_Accounts_By_Id
(
	IN 
    _tableName VARCHAR(255),
	_startId INT,
    _endId INT	-- [startId, endId) : startId is included, and endId is not included in range
)
GET_LIST_Accounts_By_Id_Label: BEGIN
	IF (_tableName = NULL) OR (_startId = NULL) OR (_endId = NULL) THEN
		SELECT -1, 'tableName, startId, endId는 모두 NULL이 아니어야 합니다.';
		LEAVE GET_LIST_Accounts_By_Id_Label;
    END IF;
    
	SET @table := _tableName;
    SET @startId := _startId;
    SET @endId := _endId;
    
    SET @sql_text := 
    CONCAT ('    
		SELECT * FROM ', @table, '
		WHERE id >= ', @startId, ' AND id < ', @endId, ';
    ');
    
	PREPARE stmt from @sql_text;
    START TRANSACTION;
	EXECUTE stmt;
    COMMIT;
END$$
DELIMITER ;

/* GET_LIST_Accounts : ON DEVELOPMENT */
DROP PROCEDURE IF EXISTS GET_LIST_Accounts;
DELIMITER $$
CREATE PROCEDURE GET_LIST_Accounts
(
	IN 
    _tableName VARCHAR(255),
	_startMonth INT(2),		-- date range
    _endMonth INT(2),
    _startDate INT(2),
	_endDate INT(2),
	_startAmount BIGINT,	-- amount range
    _endAmount BIGINT,
	_name VARCHAR(255),
    _purpose VARCHAR(255),
    _purposeDetail VARCHAR(255)
)
BEGIN
	/* GET_LIST_Accounts : ON DEVELOPMENT */
	SET @table := _tableName;
    SET @sql_text := 
    CONCAT ('
    ');
	PREPARE stmt from @sql_text;
    START TRANSACTION;
	EXECUTE stmt;
    COMMIT;
    /* GET_LIST_Accounts : ON DEVELOPMENT */
END$$
DELIMITER ;

/* ================================================================================================================================= */

/* Accounts_Id_Table: starting index of each month is stored in this table.
   related procedures: INS_Accounts_Id_Table, GET_Accounts_Id_Table, UPD_Accounts_Id_Table
*/
CREATE TABLE IF NOT EXISTS Accounts_Id_Table 
(
	tableName VARCHAR(255) NOT NULL PRIMARY KEY,
	January int,
	Feburuary int,
	March int,
	April int,
	May int,
	June int,
	July int,
	August int,
	September int,
	October int,
	November int,
	December int
);

/* INS_Accounts_Id_Table: 프로그램 사용 중 연도가 늘어날 시 호출 */
DROP PROCEDURE IF EXISTS INS_Accounts_Id_Table;
DELIMITER $$
CREATE PROCEDURE INS_Accounts_Id_Table
(
	IN _tableName VARCHAR(255)
)
BEGIN    
    START TRANSACTION;
    INSERT INTO Accounts_Id_Table(_tableName, January, February, March, April, June, July, August, September, October, November, December)
	VALUE (0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);	-- January starting index is always 0; NULL means there is no record in that month
    COMMIT;
    
    SELECT 0, _tableName, 'Accounts_Id_Table insert done';
END$$
DELIMITER ;

/* GET_Accounts_Id_Table */
DROP PROCEDURE IF EXISTS GET_Accounts_Id_Table;
DELIMITER $$
CREATE PROCEDURE GET_Accounts_Id_Table
(
	IN _tableName VARCHAR(255)
)
GET_Accounts_Id_Label: BEGIN
	IF (_tableName = NULL) THEN
		SELECT -1, 'tableName은 NULL이 아니어야 합니다.';
		LEAVE GET_Accounts_Id_Label;
    END IF;
    
	SET @table := _tableName;
    SET @sql_text := 
    CONCAT (
		'SELECT * FROM Accounts_Id_Table WHERE tablename = ', @table, ';'
    );
	PREPARE stmt from @sql_text;
	EXECUTE stmt;
END$$
DELIMITER ;

/* UPD_Accounts_Id_Table: 변경내용 저장 시, 혹은 프로그램 종료 시 호출 */
DROP PROCEDURE IF EXISTS UPD_Accounts_Id_Table;
DELIMITER $$
CREATE PROCEDURE UPD_Accounts_Id_Table
(
	IN _tableName VARCHAR(255),
	_January int,
	_Feburuary int,
	_March int,
	_April int,
	_May int,
	_June int,
	_July int,
	_August int,
	_September int,
	_October int,
	_November int,
	_December int
)
UPD_Accounts_Id_Table_Label: BEGIN
	IF (_tableName = NULL) THEN
		SELECT -1, 'tableName은 NULL이 아니어야 합니다.';
		LEAVE UPD_Accounts_Id_Table_Label;
    END IF;
    
    START TRANSACTION;
    UPDATE Accounts_Id_Table
	SET 
		January = COALESCE(_January, January),
        Feburuary = COALESCE(_Feburuary, Feburuary),
        March = COALESCE(_March, March),
        April = COALESCE(_April, April),
        May = COALESCE(_May, May),
        June = COALESCE(_June, June),
        July = COALESCE(_July, July),
        August = COALESCE(_August, August),
        September = COALESCE(_September, September),
        October = COALESCE(_October, October),
        November = COALESCE(_November, November),
        December = COALESCE(_December, December)
	WHERE tableName = _tableName;
    COMMIT;
    
    SELECT 0, 'Accounts_Id_Table update done';
END$$
DELIMITER ;

/* ================================================================================================================================= */