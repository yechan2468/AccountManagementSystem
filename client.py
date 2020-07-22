# python 3.8.3

############################################################################################################################################

# <Account Management System>
# This program is for handling financial tasks; More specifically, you can input, store, inquire account informations(revenue, expenditure).
# This code "client.py" performs things below:
#   1. get inputs what the user wants to do (through "ui.py"),
#       1) Write, 2) Read, 3) Modify/Delete informations
#   2. pass the message to server ("server.py"),
#   3. get the server replies and refresh the information showed in UI.

# Developers : Eungwang Yang, Yechan Lee
# Development started : from 2020.07.05. - now
# program version 0.0.0. (On development, core functionalities not yet completed)

############################################################################################################################################


import pymysql

# connect to mysql server
db = pymysql.connect(host='127.0.0.1', port=3306, user='root', passwd='root', db='DB', charset='utf8')
cursor = db.cursor()

# How to call procedure

# input parameter is all set to string
# output parameter(result) is set to int, and it means if the procedure call succedded(0:success, -1:failure)
# phoneNumber cannot be null value at any situation; it works as primary key in mysql server.
# insert, update, get, delete functionailty is provided as stored procedure

# INS_Users(name, phoneNumber, address, position, role, age, id, password, result): 9 input parameters
cursor.callproc("INS_Users", ("이예성", "01021946031", "충청남도 계룡시 장안로 75, 109동 1404호", "학생", "찬양대", "19", None, None))
fetch = cursor.fetchall()
if fetch == False or fetch[0][0] == -1 :
    print("Failed to insert user data to mysql server.")
else:
    print(fetch)
    db.commit()

# UPD_Users(name, phoneNumber, address, position, role, age, id, password, result): 9 input parameters
#   - Null(None) value in the input parameter is treated as non-changing
cursor.callproc("UPD_Users", ("이예성", None, None, "집사", "청년부", "20", None, None))
fetch = cursor.fetchall()
if fetch == False or fetch[0][0] == -1 :
    print("Failed to update user data in mysql server." + fetch)
else:
    print(fetch)
    db.commit()

# GET_Users(name, phoneNumber, result): 2 input parameters
#   - if more than one input parameter(name, phoneNumber) is given, returns information(row) of the person
cursor.callproc("GET_Users", ("이예찬", None))
fetch = cursor.fetchall()
if fetch == False or fetch[0][0] == -1 :
    print("Failed to get user data in mysql server:" + fetch)
else:
    print(fetch)

# DEL_Users(name, phoneNumber, result): 2 input parameters
#   - if more than one input parameter(name, phoneNumber) is given, deletes information(row) of the person
cursor.callproc("DEL_Users", ("이예성", None))
fetch = cursor.fetchall()
if fetch == False or fetch[0][0] == -1 :
    print("Failed to delete user data in mysql server." + fetch)
else:
    print(fetch)
    db.commit()

sql = "SELECT * FROM Users"
cursor.execute(sql)
print(cursor.fetchall())

db.commit()
db.close()

# Accounts Table의 purpose, purposeDetail 등에 들어가는 내용은 별도의 파일로 관리
# 시작할 때 DB에서 Accounts_Id_Table 불러오고, 내용 변경할 때나 끌 때는 DB에 Accounts_Id_Table 저장