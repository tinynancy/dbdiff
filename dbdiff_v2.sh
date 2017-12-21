dbfrom="-utom -pmot -h127.0.0.1"
dbnamefrom="tomdb"
dbto="-ubob -paaa -h127.2.0.2"
dbnameto="bobdb"

suffix=`date "+%Y%m%d%H%M%S"`
backupfile=/tmp/dbbackup_$suffix.sql
sqlfile=/tmp/struc.sql
#sqlpath，默认为空。通常mysql已经在系统可执行命令下。如果运行发现mysql没有找到等报错，请自行添加地址。例如sqlpath=/usr/bin/
sqlpath= 

#notinArray,查看target是否存在于数组array中,若不存在,需要处理，则返回true,return0
notinArray()
{	
	for item in $array
	do
		if [ $item != $target ]
		then
			continue
		else 
			return 1
		fi
	done
	return 0
}

	
#对于确定需要同步的字段，从建表语句中把结构摘出来，生成alter语句写入文件
altertable(){
	colsfrom=`${sqlpath}mysql $dbfrom --default-character-set=utf8 -D information_schema -e "select column_name from information_schema.columns where table_schema='$dbnamefrom' and table_name='${table}'"`
	colsto=`${sqlpath}mysql $dbto --default-character-set=utf8 -D information_schema -e "select column_name from information_schema.columns where table_schema='$dbnameto' and table_name='${table}'"`
	for col in $colsfrom
	do
		target=$col
		array=$colsto	
		if notinArray
		then
			struc=`${sqlpath}mysql $dbfrom --default-character-set=utf8 -D information_schema -e "show create table $dbnamefrom.$table"`
			echo -e  $struc|grep '`'${col}'`'|head -1|sed -e 's/.$/;/g'|sed "s/^/alter table $table add/g" >> $sqlfile
		fi
	done
}

#对于不存在的表，直接用表结构创建
createtable(){
${sqlpath}mysqldump  --compact $dbfrom -d $dbnamefrom $table >> $sqlfile
}

#备份，准备文件等
prepare(){
	${sqlpath}mysqldump -c $dbto $dbnameto > $backupfile
	echo -e "\n1.本地数据库已备份至"$backupfile 
	if [ -e $sqlfile ]
	then	mv $sqlfile $sqlfile.bak 
	echo -e "  上次的表差异文件已备份为"$sqlfile".bak,下次同理会被覆盖"
	fi
	touch $sqlfile
	echo "use $dbnameto;" >> $sqlfile 

}

#main()
prepare
tablesfrom=`${sqlpath}mysql $dbfrom --default-character-set=utf8 -D information_schema -e "select TABLE_NAME from TABLES where TABLE_SCHEMA='$dbnamefrom'"`
tablesto=`${sqlpath}mysql $dbto --default-character-set=utf8 -D information_schema -e "select TABLE_NAME from TABLES where TABLE_SCHEMA='$dbnameto'"`
echo -e  "\n遍历中，还没死，bie着急>_<"
for table in $tablesfrom
do 
	target=$table
	array=$tablesto
	if notinArray
	then 
		createtable	
	else 
		altertable
	fi
done
echo -e "\n2.库表差异增量语句已生成,文件位置：$sqlfile,第一次用先去看看文件对不对吧。\n  请手动source。或将本脚本最后一行反注释，开启自动source功能。"
#${sqlpath}mysql $dbto -e "source $sqlfile" && echo -e "\n3.表差异已自动source成功\n"
