#!/bin/bash
############################################################
## for chiphd begin
############################################################
####ȫ�ֱ���
THIS_PWD_BAK=$(pwd)
THIS_OLD_PWD_BAK=$(pwd)

function this_record_pwd() {
	THIS_PWD_BAK=$(pwd)
	cd - > /dev/null
	THIS_OLD_PWD_BAK=$(pwd)
	cd - > /dev/null
}

function this_resume_pwd() {
	cd $THIS_OLD_PWD_BAK
	cd $THIS_PWD_BAK
}

####ɾ�����ڵ��ļ�
function del_exist_file() {
	if [ "$1" ]; then
		if [ -f "$1" ]; then
			rm "$1"
		fi
	fi
}

#### windows·����cd����
function wcd() {
	if [ $# -lt 1 ]; then
		show_vit "need path"
		return 1
	fi

	if [ 1 -lt $# ]; then
		show_vit 'Is there space? use ""'
		return 0
	fi

	local my_path
	my_path="$(echo "$1" | sed 's/\\/\//g')"
	#echo $my_path
	if [ -d "$my_path" ]; then
		cd "$my_path"
	else
		echo "no path : $my_path"
	fi
}

#####��ȡip
function get_my_ip_addr() {
	local myip=$(ifconfig eth0 2>/dev/null | grep "inet" | cut -f 2 -d ":" | cut -f 1 -d " ")
	if [ ! "$myip" ]; then
		myip=$(ifconfig eth1 2>/dev/null | grep "inet" | cut -f 2 -d ":" | cut -f 1 -d " ")
		if [ ! "$myip" ]; then
			myip=$(ifconfig wlan0 2>/dev/null | grep "inet" | cut -f 2 -d ":" | cut -f 1 -d " ")
			if [ ! "$myip" ]; then
				myip="127.0.0.1"
			fi
		fi
	fi
	echo $myip
}

#####�򵥼���Ƿ���chiphd�ķ�����
function IS_CHIPHD_SERVER_BY_IP() {
	local chiphd_server_ip_set="192.168.1.20 192.168.1.22 192.168.1.23 192.168.1.101"
	this_ip=$(get_my_ip_addr)

	if [ "`echo $chiphd_server_ip_set | grep $this_ip`" ]; then
		echo "true"
	else
		echo "false"
	fi
}

#�Զ������ű�
function update-chiphd-script-auto()
{
	##����Ƿ�chiphd server
	if [ "`IS_CHIPHD_SERVER_BY_IP`" == "true" ]; then
		if [ -d $CHIPHD_ANDROID_SCRIPT_PATH ]; then
			local TempPwd=`pwd`
			cd $CHIPHD_ANDROID_SCRIPT_PATH && echo -e -n "    now update script : " && git pull
			cd $TempPwd
		else
			echo -e "\e[1;33m  No dir -- $CHIPHD_ANDROID_SCRIPT_PATH\e[0m"
		fi
	fi
}

# ���Ƕ��ͬ���ļ�������������ȵ�wallpaper��
function findcp()
{
	SFile=$1  #����Դ�ļ�
	TDir=$2   #Ŀ��Ŀ¼
	if [ "t$SFile" != "t" -a -f $SFile ]; then
		if [ "t$TDir" = "t" ]; then
			TDir=.
		fi
		if [ -d $TDir ]; then
			SFileName=${SFile##*/}
			TFiles=`find $TDir -name $SFileName`
			if [ "$TFiles" ]; then
				for ii in $TFiles
				do
					echo "cp $SFile $ii" && cp $SFile $ii
				done
			fi
		fi
	fi
}
#############################################################
## end for this script file
#############################################################
