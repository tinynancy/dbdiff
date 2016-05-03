# dbdiff
a shell script which compares the schema of 2 mysql databases, and generates a sql file shows the differences that a behinid b

主要实现以下功能：
针对两个数据库（dbfrom ,dbto),比较二者的schema，并且将dbto落后于dbfrom的字段和表，生成sql文件。然后可自动或手动导入。

需要修改或赋值的参数：
脚本前3行
dbfrom
dbto
dbname
