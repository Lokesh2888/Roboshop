#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

#check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
   echo -e "$R ERROR:: Please run the script using root access $N"
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

cp mongodb.repo /etc/yum.repos.d/mongo.repo 
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing the mongoDB server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling mongod "

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting mongod "

sed -i 's/127.0.0.1/0.0.0.0./g' /etc/mongod.conf
VALIDATE $? "Editing filr for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongod "


