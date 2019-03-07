#!/usr/bin/env 
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} == "centos" ]]; then
		if cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/' | grep -q -E -i "7" ; then
			release="centos7"	
		fi
	fi	
	echo -e "${release}"
}
Set_config_port(){
	while true
	do
	echo -e "请输入要设置的端口"
	read -e -p "(默认: 4443):" port
	[[ -z "$port" ]] && port="4443"
	echo $((${port}+0)) &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
			echo && echo ${Separator_1} && echo -e "	端口 : ${Green_font_prefix}${port}${Font_color_suffix}" && echo ${Separator_1} && echo
			break
		else
			echo -e "${Error} 请输入正确的数字(1-65535)"
		fi
	else
		echo -e "${Error} 请输入正确的数字(1-65535)"
	fi
	done
}
Add_iptables(){
	if [[ ! -z "${port}" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	fi
}
Del_iptables(){
	if [[ ! -z "${port}" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	fi
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
		chkconfig --level 2345 iptables on
		chkconfig --level 2345 ip6tables on
	else
		iptables-save > /etc/iptables.up.rules
		ip6tables-save > /etc/ip6tables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Restart(){
	sudo systemctl restart frps
}
Stop(){
	sudo systemctl stop frps
}
Start(){
	sudo systemctl start frps
}
Install(){
	check_sys
	if ! wget https://github.com/fatedier/frp/releases/download/v0.20.0/frp_0.20.0_linux_amd64.tar.gz; then
			echo -e "${Error} Frp 脚本下载失败 !" && exit 1
		else
			echo -e "${Info} Frp 脚本下载完成 !"
			tar -zxvf frp_0.20.0_linux_amd64.tar.gz		
	fi
	Set_config_port
	echo -e "端口设置完成"
	echo "[common]" > frp_0.20.0_linux_amd64/frps.ini
	echo "bind_port=${port}" > frp_0.20.0_linux_amd64/frps.ini
	echo -e "添加配置文件完成"
	if [[ ${release} == "centos7" ]]; then
		Setfirewall
		else
		Add_iptables
		Save_iptables
	fi
	echo -e "开放端口完成"
	Setaotu
	echo -e "设置自启动完成"
}
Setfirewall(){
	firewall-cmd --zone=public --add-port=${port}/tcp --permanent
	firewall-cmd --zone=public --add-port=${port}/udp --permanent
	firewall-cmd --reload
}
Setaotu(){
    echo "[Unit]" >> /lib/systemd/system/frps.service
	echo "Description=fraps service" >> /lib/systemd/system/frps.service
	echo "After=network.target syslog.target" >> /lib/systemd/system/frps.service
	echo "Wants=network.target" >> /lib/systemd/system/frps.service
	echo "[Service]" >> /lib/systemd/system/frps.service
	echo "Type=simple" >> /lib/systemd/system/frps.service
	echo "ExecStart=$(cd `dirname $0`; pwd)/frp_0.20.0_linux_amd64/frps -c $(cd `dirname $0`; pwd)/frp_0.20.0_linux_amd64/frps.ini" >> /lib/systemd/system/frps.service
	echo "[Install]" >> /lib/systemd/system/frps.service
	echo "WantedBy=multi-user.target" >> /lib/systemd/system/frps.service
	sudo systemctl start frps
	sudo systemctl enable frps
}

echo -e "  Frp管理 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- ZHOUJIA ----

  ${Green_font_prefix}1.${Font_color_suffix} 重启Frp
  ${Green_font_prefix}2.${Font_color_suffix} 停止Frp
  ${Green_font_prefix}3.${Font_color_suffix} 启动Frp
————————————
  ${Green_font_prefix}4.${Font_color_suffix} 安装配置Frp
  ${Green_font_prefix}5.${Font_color_suffix} 设置Frp自启动

————————————
 "
 	echo && read -e -p "请输入数字 [1-5]：" num
case "$num" in
	1)
	Restart
	;;
	2)
	Stop
	;;
	3)
	Start
	;;
	4)
	Install
	;;
	5)
	Setaotu
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [1-5]"
	;;
esac
