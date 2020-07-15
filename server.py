# python 3.8.3

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


import pymysql
import client

db = pymysql.connect(host='192.0.0.1', port=3306, user='root', passwd='root', db='DB', charset='utf8')

# 조건조회

# 월말정산

# 연말정산


cursor = db.cursor()
cursor.execute("SHOW TABLES")
db.commit()
db.close()