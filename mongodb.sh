#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

    mkdir -p $LOGS_FOLDER
    echo "script started excuted at: $(date)"

if [ $USER_ID -ne 0 ]; then
    echo "ERROR :: Please run this script with root privelege"
    exit 1
fi 

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "Installing $2...$R failure $N"
        exit 1
    else
        echo -e "Installing $2...$G success $N"
    fi
    
}
 
 cp mongo.repo /etc/yum.repos.d/mongo.repo
 VALIDATE $? "Adding mongo repo"

 dnf install mongodb-org -y &>>$LOG_FILE
 VALIDATE $? "Installing mongodb"

 systemctl enable mongod &>>$LOG_FILE
 VALIDATE $? "Enable mongodb"

 systemctl start mongod