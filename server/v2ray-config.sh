echo -e "1. ws + KCP Non-reverse"
echo -e "2. reverse KCP"
echo -e "3. reverse WS"
echo -e "请输入数字选择使用的设置:[1-3]"
read a

if [ $a == 1 ]
then
	cp /etc/v2ray/config.ws.kcp.json /etc/v2ray/config.json
elif [ $a == 2 ]
then
	cp /etc/v2ray/config.B.json /etc/v2ray/config.json
elif [ $a == 3 ]
then
	cp /etc/v2ray/config.B2.json /etc/v2ray/config.json
else
	echo "数字不正确，退出！"
	exit 0
fi

systemctl restart v2ray

echo "操作完成"
