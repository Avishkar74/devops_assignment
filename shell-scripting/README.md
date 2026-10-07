# Shell Scripting

I created a shell script to collect and display basic system information. The script uses the date command to get the current date, hostname to display the system hostname, and whoami to find the currently logged-in user. I stored these values in variables and used echo to display them in the terminal. The script also uses df -h to show disk usage in a human-readable format and ps aux to display the currently running processes.

The script takes input from the user using read -p. Here, read is used to accept input, while the -p option is used to display a prompt message before taking the input. The entered directory name is stored in a variable and then used with mkdir -p to create a directory. The -p option in mkdir allows the directory to be created without showing an error if it already exists, and it can also create parent directories when required. A file is then created inside the directory using touch. Finally, the output of ps aux is stored in this file using > output redirection. The > operator redirects the command output to the file instead of displaying it only on the terminal.

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)