#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD #It will help to take the file from the stating location of the script

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

#check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
   echo -e "$R ERROR:: Please run the script using root access $N"  | tee -a $LOG_FILE
   exit 1 #give other than 0 till 127 to exit the script
else
   echo "You are running with root access" | tee -a $LOG_FILE
fi

#validate function takes input as exit status, what command they tries to install
VALIDATE(){
     if [ $1 -eq 0 ]
   then
      echo -e "$2 is.... $G SUCCESS $N" | tee -a $LOG_FILE
   else
      echo -e "$2 is.... $R  FAILURE $N" | tee -a $LOG_FILE
      exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling the default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling the required version of nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing the nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating the roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir /app
VALIDATE $? "Creating the app directory"
   
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing the dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "Starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Creating the mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing the mongodb client"


STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
   mongosh --host mongodb.pothina.store </app/db/master-data.js &>>$LOG_FILE
   VALIDATE $? "Loading data into mongoDB"
else
  echo -e "Data is already loaded ... $Y SKIPPING $N"
fi





