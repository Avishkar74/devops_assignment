![alt text](images/image.png)

> Output of `sudo adduser task2user` (asks for a password, makes a group, copies `/etc/skel`, creates `/home/task2user`), then `id`, `ls -ld` and `grep` on `/etc/passwd`.  
> Below it, `sudo useradd task2useradd` gives a user with no home directory (`ls -ld` fails), and `useradd -m task2useradd2` creates one. This shows the difference between `adduser` and `useradd`.  

I tried both adduser and useradd to understand the difference between them. When I used adduser, it guided me through the process, asked me to set a password, created a group for the user, and also created the user's home directory automatically. On the other hand, when I used useradd without any options, the user was created successfully, but no home directory was created. I then used useradd -m, where the -m option created the home directory as well. From this, I understood that adduser is more convenient for manually creating users on Ubuntu, while useradd gives more direct control and may require additional options depending on what needs to be configured.
