CREATE DATABASE IF NOT EXISTS DB DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE DB;		-- DB: 천성교회의 교인, 일정 등을 관리하기 위한 테이블들을 모아 놓은 general한 목적의 데이터베이스.

/* Users Table: 교인 정보 관리
   Users table을 관리하기 위한 프로시저는 INS_Users(insert), DEL_Users(delete), UPD_Users(update), GET_Users(get info of only one person)으로,
   서버 컴퓨터의 하드웨어 스펙이 부족한 만큼 대부분의 일을 클라이언트에서 처리하기 위함이다.
   
   ** 주의: procedure의 input data validity는 client.py에서 검사해야 한다.
   여기에 구현된 procedure에서는 값이 NULL로 주어졌는지 정도만 검사하고, 잘못된 data의 input으로 인한 예상치 못한 결과에 대해서는 보장할 수 없음.
   
   * 코드 작성 중 Users DB의 procedure에 OUT parameter로 설정된 RESULT가 필요 없다는 것을 알게 됨.
   차차 지울 예정
 */
CREATE TABLE IF NOT EXISTS Users (
    name varchar(255) NOT NULL,
    phoneNumber varchar(255) NOT NULL,	-- hyphen('-') is not included
    address varchar(255),
    position varchar(255),
    role varchar(255),
    age VARCHAR(255),
	id varchar(255),
    password varchar(255),
    PRIMARY KEY PK(name, phoneNumber)
);
ALTER TABLE Users 
CHARACTER SET utf8 
COLLATE utf8_general_ci;	-- 한글 사용 가능

/* INS_Users Procedure: 성공 시 return 0, 실패 시 return -1 */
DROP PROCEDURE IF EXISTS INS_Users;
DELIMITER $$
CREATE PROCEDURE INS_Users
(
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255), 
    _address VARCHAR(255), 
    _position VARCHAR(255), 
    _role VARCHAR(255),
	_age VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255), 
    OUT RESULT INT
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
		CALL UPD_Users(_name, _phoneNumber, _address, _position, _role, _age, _id, _password, RESULT);
        SET RESULT = -1;
        SELECT RESULT, _name, 'Insert하려는 대상의 이름, 혹은 전화번호가 이미 테이블에 존재합니다. 대신 주어진 정보를 이용해 Update했습니다.';
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
	INSERT INTO Users(name, address, phoneNumber, position, role, age, id, password)
	VALUE(_name, _address, _phoneNumber, _position, _role, _age, _id, _password);
	COMMIT;
    
	SET RESULT = 0;
    SELECT RESULT, _name, 'insert done';
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
    _position VARCHAR(255), 
    _role VARCHAR(255),
	_age VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255), 
    OUT RESULT INT)
UPD_Users_Label: BEGIN
	-- check if more than one parameter of (_name or _phoneNumber) is(are) given
	IF _name IS NULL THEN
		IF _phoneNumber IS NULL THEN
			SET RESULT = -1;
			SELECT RESULT, '이름, 혹은 전화번호 parameter 중 적어도 하나의 값이 주어져야 합니다.';
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
		SET RESULT = -1;
		SELECT RESULT, _name, 'update할 대상(_name)이 존재하지 않습니다.';
		LEAVE UPD_Users_Label;
    END IF;
    
	/* If input parameter is given as NULL, do not change value */
	START TRANSACTION;
    UPDATE Users
	SET 
		address = COALESCE(_address, address),
		position = COALESCE(_position, position),
		role = COALESCE(_role, role), 
        age = COALESCE(_age, age),
		id = COALESCE(_id, id),
		password = COALESCE(_password, password)
	WHERE name = _name;
	COMMIT;
    
	SET RESULT = 0;
    SELECT RESULT, _name, 'update done';
END$$
DELIMITER ;

/* DEL_Users: name과 phoneNumber 둘이 primary key(PK)이므로, 입력된 _name 혹은 _phoneNumber를 가진 user 정보를 삭제.
   따라서 name과 phoneNumber 둘 중 하나를 NULL로 비워 놓아도 됨.
*/
DROP PROCEDURE IF EXISTS DEL_Users;
DELIMITER $$
CREATE PROCEDURE DEL_Users (
		IN _name VARCHAR(255), 
		_phoneNumber VARCHAR(255),
		OUT RESULT INT
    )
BEGIN
    IF _phoneNumber IS NULL THEN
		START TRANSACTION;
        DELETE FROM Users 
        WHERE name = _name;
        COMMIT;
        
        SET RESULT = 0;
		SELECT RESULT, _name, 'delete done';
    ELSEIF _name IS NULL THEN
		START TRANSACTION;
		DELETE FROM Users 
        WHERE phoneNumber = _phoneNumber;
        COMMIT;
        
        SET RESULT = 0;
		SELECT RESULT, (SELECT name FROM User WHERE phoneNumber = _phoneNumber), 'delete done';
    ELSE
		SET RESULT = -1;
        SELECT RESULT, '이름, 혹은 전화번호 parameter는 NULL 값이 될 수 없습니다.';
	END IF;
END$$
DELIMITER ;

/* GET_Users: only 한 사람이 가진 정보만을 return받기 위한 함수. 
   DEL_Users와 비슷한 mechanism으로, name이나 phoneNumber 둘 중 하나 이상을 입력 parameter로 받는다.
   GET하지 못했을 때 -1을 SELECT
*/
DROP PROCEDURE IF EXISTS GET_Users;
DELIMITER $$
CREATE PROCEDURE GET_Users (
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255)
    )
BEGIN
    IF _name IS NOT NULL THEN
		SELECT name, phoneNumber, address, position, role, age, id, password 
        FROM Users 
        WHERE name = _name;
    ELSEIF _phoneNumber IS NOT NULL THEN
        SELECT name, phoneNumber, address, position, role, age, id, password 
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
SET @result = -1;

SET @name = '이예찬';
SET @phoneNumber = '01021156036';
SET @address = '충청남도 계룡시 장안로 75, 109동 1404호';
-- insert User
CALL INS_Users(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL, @result);

SET @name = '양은광';
SET @phoneNumber = '01028885479';
SET @address = '대전광역시 대덕구 관평동 그다음은 모름';
-- insert User
CALL INS_Users(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL, @result);
SELECT * FROM Users;

-- update User
SET @newAddress = '대전광역시 서구 방동 593번지';
CALL UPD_Users(@name, @phoneNumber, @newAddress, NULL, NULL, NULL, NULL, NULL, @result);
SELECT * FROM Users;

-- delete User
CALL DEL_Users(@name, NULL, @result);
SELECT * FROM Users;	

CALL UPD_Users('이예성', '01021946031', '충청남도 계룡시 장안로 75, 109동 1404호', NULL, "청년부", "19", NULL, NULL, @result);
SELECT * FROM Users;
*/


/*
 아래부터는 Accounts(회계정보)를 담당하는 데이터베이스와 프로시져.
 - Accounts는 account2020, account2021, ... 등의 table로 이뤄져 있으며,
 - procedure의 종류로는 Create_Accounts_Table, INS_Accounts, INS_Middle_Accounts, DEL_Accounts, GET_LIST_Accounts, GET_Accounts_Id_Table, UPD_Accounts_ID_Table이 있음.
   회계 프로그램에서 Update 혹은 Delete보다는 마지막 행에 Insert하는 작업과 조회(GET_LIST)하는 작업이 가장 주를 이룬다는 것을 고려해, 위와 같이 procedure의 종류를 한정지었음.
 
 - INSERT의 경우 INS_Accounts (맨 마지막 행에 insert)와 INS_Middle(중간 행에 insert한 뒤 그 다음에 오는 모든 행들의 id를 1씩 증가시킴)으로 나뉨.
   INSERT를 맨 마지막 행에 하는 경우가 대부분이므로, 대부분의 경우에서 id를 증가시키는 overhead를 줄이기 위함임.
   client.py에서는 엑셀 형식이든, 표 형식이든 정리된 데이터들을 정리할 때 (client 단에서 저장 버튼을 눌렀을 때) 날짜 순서대로 정렬한 뒤 순서대로 Accounts DB에 insert하도록 하는 작업이 필요. 
   저장 단계에서 정렬함으로써 Accounts database에서 검색, 조회가 빠르게 하도록 하기 위함.
 - DELETE의 경우 중간에 있는 element를 삭제하는 경우가 대부분이므로, 중간의 데이터를 삭제한다고 상정함. 
   INS_Middle_Account와 정반대 동작을 수행하며, 중간 행을 delete한 뒤 그 다음에 오는 모든 행들의 id를 1씩 감소시킴.
 - UPDATE의 경우 DELETE 후 INSERT_Middle함으로써 동작.
 - GET_LIST: 월별로 records를 get하는 경우가 많으므로, DB에 1월달 record 시작 id, 2월달 record 시작 id, ...를 저장해 놓음.
   client 프로그램이 시작하면 DB에서 id table을 불러오고, client에서 1.records 저장 시, 2.프로그램 종료 시 id table을 갱신해 DB에 저장.
*/

CREATE DATABASE IF NOT EXISTS Accounts DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE Accounts;

/* Create_Accounts_Table: 프로그램 사용 중 연도가 늘어나는 것에 대비해 만듦 */
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
			id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
			month INT(2) NOT NULL,
			date INT(2) NOT NULL,
			amount BIGINT NOT NULL,
			name VARCHAR(255),
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
	-- starting index of each month is stored in this table

CREATE TABLE IF NOT EXISTS Accounts_Id_Table (
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

/* INS_Accounts_Id_Table: 프로그램 사용 중 연도가 늘어나는 것에 대비해 만듦 */
DROP PROCEDURE IF EXISTS INS_Accounts_Id_Table;
DELIMITER $$
CREATE PROCEDURE INS_Accounts_Id_Table
(
	IN tableName VARCHAR(255)
)
BEGIN
    START TRANSACTION;
    INSERT INTO Accounts_Id_Table(January, February, March, April, June, July, August, September, October, November, December)
	VALUE (0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);	-- January starting index is always 0; NULL means there is no record in that month
    COMMIT;
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

/* UPD_Accounts_Id_Table */
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

/* INS_Accounts: 회계 내역을 insert. tableName, month, date, amount는 모두 NULL이 아니어야 함 */
DROP PROCEDURE IF EXISTS INS_Accounts;
DELIMITER $$
CREATE PROCEDURE INS_Accounts
(
	IN 
    tableName VARCHAR(255),
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
	IF (tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) THEN
		SELECT -1, 'tableName, month, date, amount parameter는 모두 NULL이 아니어야 합니다.';
        LEAVE INS_Accounts_Label;        
	END IF;

    SET @table := tableName;
	SET @sql_text := 
    CONCAT (
		'INSERT INTO ',@table,'(month, date, amount, name, purpose, purposeDetail, others)
        VALUE(_month, _date, _amount, _name, _purpose, _purposeDetail, _others);'
	);
	PREPARE stmt from @sql_text;
	EXECUTE stmt;
    SELECT 0, CONCAT(_month, '/', _date, ', ', _amount, ' won'), 'insert done';
END$$
DELIMITER ;

/* UPD_Accounts */
DROP PROCEDURE IF EXISTS UPD_Accounts;
DELIMITER $$
CREATE PROCEDURE UPD_Accounts
(
	IN 
    _id INT,
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name varchar(255)
)
UPD_Accounts_Label: BEGIN
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) THEN
		SELECT -1, 'tableName, month, date, amount는 모두 NULL이 아니어야 합니다.';
		LEAVE UPD_Accounts_Label;
    END IF;
    
	SET @table := tableName;
    SET @sql_text := 
    CONCAT (''
    );
END$$
DELIMITER ;

/*  */
DROP PROCEDURE IF EXISTS DEL_Accounts;
DELIMITER $$
CREATE PROCEDURE DEL_Accounts
(
	IN 
    tableName VARCHAR(255),
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name varchar(255)
)
DEL_Accounts_Label: BEGIN
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) THEN
		SELECT -1, 'tableName, month, date, amount는 모두 NULL이 아니어야 합니다.';
		LEAVE DEL_Accounts_Label;
    END IF;
    
	SET @table := tableName;
    SET @sql_text := 
    CONCAT (''
    );
END$$
DELIMITER ;

/*  */
DROP PROCEDURE IF EXISTS GET_LIST_Accounts;
DELIMITER $$
CREATE PROCEDURE GET_LIST_Accounts
(
	IN 
    tableName VARCHAR(255),
	_month INT(2),
	_date INT(2),
	_amount BIGINT,
	_name varchar(255)
)
GET_LIST_Accounts_Label: BEGIN
	IF (_tableName = NULL) OR (_month = NULL) OR (_date = NULL) OR (_amount = NULL) THEN
		SELECT -1, 'tableName, month, date, amount는 모두 NULL이 아니어야 합니다.';
		LEAVE GET_LIST_Accounts_Label;
    END IF;
    
	SET @table := tableName;
    SET @sql_text := 
    CONCAT (''
    );
END$$
DELIMITER ;