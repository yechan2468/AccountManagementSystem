############################################################################################################################################

# <Account Management System>
# This program is for handling financial tasks; More specifically, you can input, store, inquire account informations(revenue, expenditure).
# This code "server.py" performs things below:
#   1. get requirements from "client.py",
#   2. handle requirements and inquire DBMS using procedure,
#   3. get replies from DBMS
#   * This program uses MySQL Ver 14.14 Distrib 5.7.30, for Linux (x86_64) using EditLine wrapper.
#   * This program was designed to run on Ubuntu Server 20.04 LTS (Linux 64bit). 

# Developers : Eungwang Yang, Yechan Lee
# Development started : from 2020.07.05. - now
# program version 0.0.0. (On development, core functionalities not yet completed)

############################################################################################################################################

### 1.DB와 연결, 클라이언트와 연결

import socket 
import pymysql
from _thread import *

# connect to mysql server
db_com = pymysql.connect(host='219.255.75.109', port=17000, user='cjstjd', passwd='cjstjd1234', db='DB_COM', charset='utf8')
DB_COM = db_com.cursor()
print('DB_COM Connected')
db_acc = pymysql.connect(host='219.255.75.109', port=17000, user='cjstjd', passwd='cjstjd1234', db='DB_ACC', charset='utf8')
DB_ACC = db_acc.cursor()
print('DB_ACC Connected')

# 쓰레드에서 실행되는 코드입니다. 
# 접속한 클라이언트마다 새로운 쓰레드가 생성되어 통신을 하게 됩니다. 
def threaded(client_socket, addr): 
    print('Connected by :', addr[0], ':', addr[1]) 

    # 클라이언트가 접속을 끊을 때 까지 반복합니다. 
    while True: 
        try:
            # 데이터가 수신되면 클라이언트에 다시 전송합니다.(에코)
            data = client_socket.recv(1024)

            if not data: 
                print('Disconnected by ' + addr[0],':',addr[1])
                break

            print('Received from ' + addr[0],':',addr[1] , data.decode())

            client_socket.send(data) 
        except ConnectionResetError as e:
            print('Disconnected by ' + addr[0],':',addr[1])
            break
             
    client_socket.close() 

# client와의 네트워킹을 위한 주소
HOST = '192.168.0.4'
# 외부 listen할 포트 주소; 포트포워딩 필요
PORT = 3308

# 소켓 객체를 생성합니다. 
# 주소 체계(address family)로 IPv4, 소켓 타입으로 TCP 사용합니다. 
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
# 포트 사용중이라 연결할 수 없다는 
# WinError 10048 에러 해결을 위해 필요합니다. 
server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
# bind 함수는 소켓을 특정 네트워크 인터페이스와 포트 번호에 연결하는데 사용됩니다.
# HOST는 hostname, ip address, 빈 문자열 ""이 될 수 있습니다.
# 빈 문자열이면 모든 네트워크 인터페이스로부터의 접속을 허용합니다. 
# PORT는 1-65535 사이의 숫자를 사용할 수 있습니다.  
server_socket.bind(('', PORT)) 
# 서버가 클라이언트의 접속을 허용하도록 합니다. 
server_socket.listen() 

print('server start')


# 새로운 쓰레드에서 해당 소켓을 사용하여 통신을 하게 됩니다. 
while True: 
    print('wait')
    # 클라이언트가 접속하면 accept 함수에서 새로운 소켓을 리턴합니다.
    client_socket, addr = server_socket.accept() 
    start_new_thread(threaded, (client_socket, addr)) 

server_socket.close()


### 2.DB로 SQL문전송 및 결과받기?

# # INS_Users(name, phoneNumber, address, position, role, age, id, password, result): 9 input parameters
# cursor.callproc("INS_T_User", ("이예성", "01021946031", "충청남도 계룡시 장안로 75, 109동 1404호", "학생", "찬양대", "19", None, None))
# fetch = cursor.fetchall()
# if fetch == False or fetch[0][0] == -1 :
#     print("Failed to insert user data to mysql server.")
# else:
#     print(fetch)
#     db.commit()

# # UPD_Users(name, phoneNumber, address, position, role, age, id, password, result): 9 input parameters
# #   - Null(None) value in the input parameter is treated as non-changing
# cursor.callproc("UPD_Users", ("이예성", None, None, "집사", "청년부", "20", None, None))
# fetch = cursor.fetchall()
# if fetch == False or fetch[0][0] == -1 :
#     print("Failed to update user data in mysql server." + fetch)
# else:
#     print(fetch)
#     db.commit()

# # GET_Users(name, phoneNumber, result): 2 input parameters
# #   - if more than one input parameter(name, phoneNumber) is given, returns information(row) of the person
# cursor.callproc("GET_Users", ("이예찬", None))
# fetch = cursor.fetchall()
# if fetch == False or fetch[0][0] == -1 :
#     print("Failed to get user data in mysql server:" + fetch)
# else:
#     print(fetch)

# # DEL_Users(name, phoneNumber, result): 2 input parameters
# #   - if more than one input parameter(name, phoneNumber) is given, deletes information(row) of the person
# cursor.callproc("DEL_Users", ("이예성", None))
# fetch = cursor.fetchall()
# if fetch == False or fetch[0][0] == -1 :
#     print("Failed to delete user data in mysql server." + fetch)
# else:
#     print(fetch)
#     db.commit()

# sql = "SELECT * FROM Users"
# cursor.execute(sql)
# print(cursor.fetchall())

# db.commit()
# db.close()

### 3.받은결과 클라이언트로 전송

### 4.로그 남기기(T_LOG)

### *주고받고의 성공여부를 클라이언트로 전송 -> if null, false