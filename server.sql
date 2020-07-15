USE DB;		-- DB: 천성교회의 교인, 일정 등을 관리하기 위한 테이블들을 모아 놓은 general한 목적의 데이터베이스.

/* Users Table: 교인 정보 관리
   Users table을 관리하기 위한 프로시저는 insertUser, deleteUser, modifyUser 세 개 뿐으로,
   서버 컴퓨터의 하드웨어 스펙이 부족한 만큼 대부분의 일을 클라이언트에서 처리하기 위함이다.
 */
CREATE TABLE IF NOT EXISTS Users (
    name varchar(255) NOT NULL,
    phoneNumber varchar(255) NOT NULL,
    address varchar(255),
    position varchar(255),
    role varchar(255),
    age int,
	id varchar(255),
    password varchar(255),
    PRIMARY KEY phoneNumber(phoneNumber)
);
ALTER TABLE Users CHARACTER SET utf8 COLLATE utf8_general_ci;	-- 한글 사용 가능

/* insertUser Procedure */
DROP PROCEDURE IF EXISTS insertUser;
DELIMITER $$
CREATE PROCEDURE insertUser
(
	IN _name VARCHAR(255), 
    _address VARCHAR(255), 
    _phoneNumber VARCHAR(255), 
    _position VARCHAR(255), 
    _role VARCHAR(255),
	_age VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255), 
    OUT RESULT INT
    )
BEGIN
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
END$$
DELIMITER ;

/* modifyUser Procedure : 입력받은 name을 이용하여, 그 name을 가진 사람의 정보를 수정함. 만약 사람의 이름 자체를 바꾸고자 하는 경우에는 deleteUser를 사용 */
DROP PROCEDURE IF EXISTS modifyUser;
DELIMITER $$
CREATE PROCEDURE modifyUser
(
	IN _name VARCHAR(255), 
    _address VARCHAR(255), 
    _phoneNumber VARCHAR(255), 
    _position VARCHAR(255), 
    _role VARCHAR(255),
	_age VARCHAR(255), 
    _id VARCHAR(255), 
    _password VARCHAR(255), 
    OUT RESULT INT)
BEGIN
	UPDATE Users
	SET address=_address, phoneNumber=_phoneNumber, position=_position, role=_role, age=_age, id=_id, password=_password
	WHERE name = _name;
    
	COMMIT;
	SET RESULT = 0;
END$$
DELIMITER ;

/* deleteUser: phoneNumber가 primary key(PK)이므로, 입력된 _phoneNumber를 가진 user 정보를 삭제. 만약 동명이인이 존재한다면 _name을 참고하여 삭제.
   따라서 name과 phoneNumber 둘 중 하나를 NULL로 비워 놓아도 됨.
*/
DROP PROCEDURE IF EXISTS deleteUser;
DELIMITER $$
CREATE PROCEDURE deleteUser (
	IN _name VARCHAR(255), 
    _phoneNumber VARCHAR(255),
    OUT RESULT INT
    )
BEGIN
    IF _phoneNumber != NULL THEN
		DELETE FROM Users WHERE phoneNumber = _phoneNumber;
        COMMIT;
    ELSEIF (COUNT(CASE WHEN Users.name = _name THEN 1 END) = 1) THEN	-- if there is only one user that has name '_name'
        DELETE FROM Users WHERE (SELECT name FROM Users WHERE phoneNumber = _phoneNumber);
        COMMIT;
        SET RESULT = 0;
    ELSE
		SET RESULT = -1;
	END IF;
END$$
DELIMITER ;


/* for debugging */
SET @result = -1;

SET @name = '이예찬';
SET @phoneNumber = '01021156036';
SET @address = '충청남도 계룡시 장안로 75, 109동 1404호';
/*
CALL insertUser(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL, @result);
SET @name = '양은광';
SET @phoneNumber = '01033225522';
SET @address = '대전광역시 대덕구 관평동 그다음은 모름';
CALL insertUser(@name, @phoneNumber, @address, NULL, NULL, NULL, NULL, NULL, @result);
SELECT * FROM Users;


SET @newAddress = '대전광역시 서구 방동 593번지';
CALL modifyUser(@name, @newAddress, NULL, NULL, NULL, NULL, NULL, NULL, @result);
SELECT * FROM Users;
*/
CALL deleteUser(@name, @phoneNumber, @result);
SELECT * FROM Users;