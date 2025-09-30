#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.althaf84.org
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

check_root(){
    if [ $USERID -ne 0 ]; then
        echo "ERROR:: Please run this script with root privelege"
        exit 1 # failure is other than 0
    fi
}


VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
    ###  Node js ###
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling nodejs"
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enable nodejs20"
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "installing nodejs"

    id roboshop
    if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating System User"
    else
        echo -e "User already exist....$Y  SKIPPING $N"
    fi

    mkdir -p /app 
    VALIDATE $? "Creating App Directory"
    curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
    VALIDATE $? "Downloading catalogue application"
    cd /app 
    VALIDATE $? "Changing to app directory"

    rm -rf /app/*
    VALIDATE $? "Removing exiting code"
    unzip /tmp/catalogue.zip &>>$LOG_FILE
    VALIDATE $? "unzip to catalogue"
    npm install &>>$LOG_FILE
    VALIDATE $? "Install dependencies"
    cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
    VALIDATE $? "copy systemctl service"
    systemctl daemon-reload
    systemctl enable catalogue &>>$LOG_FILE
    VALIDATE $? "Enable catalogue"
    cp $SCRIP_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
    VALIDATE $? "copy mongo repo"
    dnf install mongodb-mongosh -y &>>$LOG_FILE
    VALIDATE $? "Install MongoDB client"
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
    systemctl restart catalogue
    VALIDATE $? "Restart catalgoue"
