#!/bin/bash 

echo "System Information Script"

# Taking user input 
read -p "Enter a directory name: " directory_name 

#creating a directory 
mkdir -p "$directory_name"

# Creating a file 
file_name="$directory_name/running_processes.txt"
touch "$file_name"

# Storing system information in variables 
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

#Displaying info 
echo ""

echo "current date: $current_date"
echo "host name: $host_name"
echo "user name: $user_name"

echo ""

echo "Disk Usage"
df -h 

echo ""
echo "Runnning Processes"
ps aux

# Storing running processes ina file 
ps aux > "$file_name"

echo ""
echo "Running processes have been stored in $file_name"