USE DB;		-- DB: 천성교회의 교인, 일정 등을 관리하기 위한 테이블들을 모아 놓은 general한 목적의 데이터베이스.

/* Users Table: 교인 정보 관리
   Users table을 관리하기 위한 프로시저는 INS_Users(insert), DEL_Users(delete), UPD_Users(update), GET_Users(get info of only one person)으로,
   서버 컴퓨터의 하드웨어 스펙이 부족한 만큼 대부분의 일을 클라이언트에서 처리하기 위함이다.
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
		-- CALL UPD_Users(_name, _phoneNumber, _address, _position, _role, _age, _id, _password, RESULT);
        SET RESULT = -1;
        SELECT RESULT, _name, 'Insert하려는 대상의 이름, 혹은 전화번호가 이미 테이블에 존재합니다.';
        LEAVE INS_Users_Label;
    END IF;
    
	/* id와 password의 default 값을 각각 교인 이름과 0000으로 설정 */
	IF _id = NULL THEN
        SET _id = _name;
	END IF;
	IF _password = NULL THEN
		SET _password = '0000';
	END IF;
    
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
        DELETE FROM Users 
        WHERE name = _name;
        COMMIT;
        SET RESULT = 0;
		SELECT RESULT, _name, 'delete done';
    ELSEIF _name IS NULL THEN
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