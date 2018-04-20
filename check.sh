#!/bin/bash

id=197 #节点id
host="http://ss.doubledou.buzz" #主站域名
x=5 #循环次数

url="$host/check?id=$id"

for k in $( seq 1 $x )
do
	status[${k}-1]=$(curl --connect-timeout 10 -s $url) 
	#echo ${status[${k}-1]}
	if [ ${status[${k}-1]} == 1 ]
	then
		echo "第"$k"次测试节点在线正常"
	elif [ ${status[${k}-1]} == -1 ]
	then
		echo "第"$k"次测试节点不存在"
	elif [ ${status[${k}-1]} == 2 ]
	then
		echo "第"$k"次测试节点失联"
	else
		echo "第"$k"次测试异常"
	fi
	sleep 1
done

s=3

for i in ${status[@]}
do
   [ $i == 1 ] && s=1 && break #s=1节点正常
   [ $i == -1 ] && s=-1 #s=2节点不存在
   [ $i == 2 ] && s=2 #s=2节点掉线
done
echo
echo "--------处理结果--------"
if [ $s == 1 ]
then 
	echo "节点正常，不做处理"
elif [ $s == -1 ]
then
	echo "节点不存在，请检查node id是否填写正确"
elif [ $s == 2 ]
then	
	echo "节点失联，已重启节点"
	systemctl restart ssr.service
	#cd /root/shadowsocks
	#bash run.sh
else
	echo "遇到未知错误"
fi
