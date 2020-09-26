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


import socket 

# 219.255.75.109:18000 -> 포트포워딩 (3308)
HOST = '219.255.75.109'
PORT = 18000

client_socket = socket.socket(socket.AF_INET,socket.SOCK_STREAM) 

# connect to host
client_socket.connect((HOST, PORT)) 

def CALL_PROCEDURE(db, table, procedure, *procedure_parameters) :
    message = [db, table, procedure, procedure_parameters]
    client_socket.send(message.encode)

# 키보드로 입력한 문자열을 서버로 전송하고 
# 서버에서 에코되어 돌아오는 메시지를 받으면 화면에 출력합니다. 
# quit를 입력할 때 까지 반복합니다. 
while True: 
    message = input('Enter Message ("quit" to exit): ')
    if message == 'quit':
    	break

    client_socket.send(message.encode()) 
    
    rawData = client_socket.recv(1024) 
    data = rawData.decode()

    if not data :
        print("invalid request.")

    print('Received from the server :',repr(data), "\ndatatype: ", type(data)) 

client_socket.close() 
