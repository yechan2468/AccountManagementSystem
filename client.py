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
import ui

db_com = pymysql.connect(host='219.255.75.109', port=17000, user='cjstjd', passwd='cjstjd1234', db='DB_COM', charset='utf8')
DB_COM = db_com.cursor()
print('DB_COM Connected')
db_acc = pymysql.connect(host='219.255.75.109', port=17000, user='cjstjd', passwd='cjstjd1234', db='DB_ACC', charset='utf8')
DB_ACC = db_acc.cursor()
print('DB_ACC Connected')

