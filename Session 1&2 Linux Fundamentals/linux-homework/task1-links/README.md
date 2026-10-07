# Task 1: Soft Link and Hard Link

I created an original.txt file and then created both a hard link and a soft link for it.

The main thing I noticed is that the hard link and the original file have the same inode number. This means that both names point to the same file data. Even after I deleted original.txt, I was still able to read the contents using hardlink.txt.

The soft link works differently. It points to the path of the original file, which can be seen as softlink.txt -> original.txt. After deleting original.txt, the soft link stopped working because the file it was pointing to no longer existed.

So, in simple terms, a hard link is another name for the same file, while a soft link is like a shortcut that points to the original file.

![alt text](image.png)