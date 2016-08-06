#!/bin/bash
############################################################
## for chiphd begin
CHIPHD_THIS_SCRIPT_VER="v1.8"
############################################################

####������ʾ����
source $CHIPHD_ANDROID_SCRIPT_PATH/com_show_tip.sh

# show help
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_help.sh

####��������
source $CHIPHD_ANDROID_SCRIPT_PATH/com_misc.sh

####���ز��Ҵ��뺯��
source $CHIPHD_ANDROID_SCRIPT_PATH/com_find_code.sh


####����sdk info����
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_sdk_info.sh

####�����Զ�ͬ�����뺯��
source $CHIPHD_ANDROID_SCRIPT_PATH/sync-repo-git.sh

#####����kernel·������ر���
##����lichee������ip
CHIPHD_LICHEE_IP=192.168.1.22
##����lichee�������û���
CHIPHD_LICHEE_USER=builder
##оƬ����
THIS_LICHEE_CHIP=$(chiphd_get_chip_type)
THIS_CHIP_CFGDIR=$(chiphd_get_chip_type CfgDir)
##�汾
THIS_ANDROID_VER=$(chiphd_get_android_ver)
##�ж��Ƿ��ȡ���汾
if [ -z $THIS_ANDROID_VER ]; then
	show_vit "chiphd_get_android_ver() get empty, set THIS_ANDROID_VER=4.1"
	THIS_ANDROID_VER=4.1
else
	if [ ! "`echo "$THIS_ANDROID_VER" | grep "^[4-9]\.[0-9]$"`" ]; then
		show_vit "chiphd_get_android_ver() get ${THIS_ANDROID_VER}, set THIS_ANDROID_VER=4.1"
		THIS_ANDROID_VER=4.1
	fi
fi

##����licheeĿ¼
CHIPHD_LICHEE_DIR=/home2/builder/release/${THIS_LICHEE_CHIP}-${THIS_ANDROID_VER}/lichee
LOCAL_CHIPHD_LICHEE_DIR="$CHIPHD_LICHEE_DIR"
MY_IP_ADDR=$(get_my_ip_addr)
if [ "${MY_IP_ADDR}" != "${CHIPHD_LICHEE_IP}" ]; then
	CHIPHD_LICHEE_DIR=${CHIPHD_LICHEE_USER}@${CHIPHD_LICHEE_IP}:${CHIPHD_LICHEE_DIR}
fi
if [ "`is_rockchip_SDK`" = "true" ]; then
show_vit "    use rockchip-${THIS_ANDROID_VER} sdk"
elif [ "`is_intel_SDK`" = "true" ]; then
show_vit "    use intel-${THIS_ANDROID_VER} sdk"
elif [ "is_box_SDK" = "true" ];then
show_vit "    use box sdk"
else
show_vit "CHIPHD_LICHEE_DIR=$CHIPHD_LICHEE_DIR"
fi

#############ͬ������
if [ "`is_intel_SDK`" != "true" -a "`is_rockchip_SDK`" != "true" ]; then ## intel sdk �ݲ�����
RL_repo_do_remote_sync "$1"
fi
#############ͬ������end

##����ں��Ƿ����ڱ���
function Is_Kernel_Building()
{
	XW_FLAG="chiphd888" # �˱���Ҫ�͹����ں˱���ű�chiphd_build_lichee.sh������ͬ
	local retVal=""

	if [ "${MY_IP_ADDR}" != "${CHIPHD_LICHEE_IP}" ]; then
		retVal=$(ssh ${CHIPHD_LICHEE_USER}@${CHIPHD_LICHEE_IP} "ls ${LOCAL_CHIPHD_LICHEE_DIR}/${XW_FLAG}build_*  2> /dev/null")
	else
		retVal=$(ls ${LOCAL_CHIPHD_LICHEE_DIR}/${XW_FLAG}build_*  2> /dev/null)
	fi

	if [ "$retVal" ]; then
		retVal="Building"
	fi

	echo $retVal
}

##���������ں˱��,������ʱ�ں����ڱ���
XW_BUILD_FLAG_NAME=""
function Is_Kernel_Getting()
{
	XW_FLAG="chiphd888"
	MY_DAY=$(date '+%Y%02m%02d')
	MY_TIME=$(date '+%02k%02M')
	TIME_NAME=${MY_DAY}-${MY_TIME}
	local MyName=$(echo `whoami`)
	MyName="${MyName}-$MY_IP_ADDR"
	XW_FLAG_NAME="${XW_FLAG}_${MyName}_getting_"
	#�������
	if [ "$1" = "-c" ]; then
		$(ssh ${CHIPHD_LICHEE_USER}@${CHIPHD_LICHEE_IP} "touch ${LOCAL_CHIPHD_LICHEE_DIR}/${XW_FLAG_NAME}${TIME_NAME}") && echo "create flag : ${XW_FLAG_NAME}${TIME_NAME}"
	fi
	#ɾ�����
	if [ "$1" = "-d" ]; then
		$(ssh ${CHIPHD_LICHEE_USER}@${CHIPHD_LICHEE_IP} "rm ${LOCAL_CHIPHD_LICHEE_DIR}/${XW_FLAG_NAME}*") && echo "del flag file"
	fi
}


##����lichee tag file
function cp-lichee-tag-file()
{
	if [ -z "$DEVICE" ]; then
		show_vit "not lunch"
		return 0
	fi
	LICHEE_DIR=$ANDROID_BUILD_TOP/../lichee
	#cp tag file
	if [ -f $LICHEE_DIR/out/release_tag.txt  ]; then
		cp $LICHEE_DIR/out/release_tag.txt $DEVICE/modules/modules/ && show_vit "done : cp-lichee-tag-file"
	fi
}

##����Ƿ�Ҫ����buildroot
function chiphd_bsp_need_buildroot()
{
	local chipName=$1
	local retVal="false"
	if [ "$(echo "$chipName" | grep "a20")" -o "$(echo "$chipName" | grep "a23")" ]; then
		retVal="git clone"
	else
		if [ "$(echo "$chipName" | grep "a31")" ]; then
			local vAV=$(chiphd_get_android_ver)
			if [ "$vAV" -a "`echo $vAV | grep "4.[4-9]"`" ]; then
				retVal="scp"
			fi
		fi
	fi
	
	echo $retVal
}

##android����kernel
function chiphd-bsp()
{
	this_record_pwd

	echo "check environment ..."
	if [ -z "$DEVICE" ]; then
		show_vit "not lunch"
		return 0
	else
		if [ ! -d $DEVICE ]; then
			show_vit "lunch error $DEVICE"
			return 0
		fi
	fi
	MyTop=$(gettop)
	echo $DEVICE
	## �����Ƿ��ڵ�ǰ��android����lunch
	cd $DEVICE && cd ../../.. && mygettop=$(pwd) && echo "$mygettop"
	this_resume_pwd
	if [ "$mygettop" != "$MyTop" ]; then
		show_vit "need source-lunch again," "now lunched $DEVICE" "   or not run this command on android dir"
		return 0
	fi

	LICHEE_DIR=$ANDROID_BUILD_TOP/../lichee

	if [ -d $LICHEE_DIR ]; then
		echo $LICHEE_DIR
	else
		mkdir $LICHEE_DIR
	fi
	
	if [ -d $LICHEE_DIR/linux*[3-9].[0-9] ]; then
		my_conitue=no
		my_conitue_tip="exist `echo $LICHEE_DIR/linux*[3-9].[0-9] | sed 's/.*lichee/lichee/'` dir, conitue(yes:no)?"
		show_vit_nle "$my_conitue_tip"
		while read my_conitue
		do
			if [ "yes" = "$my_conitue" ]; then
				break;
			fi
			if [ "no" = "$my_conitue" ]; then
				this_resume_pwd
				return 0;
			fi
			show_vit_nle "$my_conitue_tip"
		done
	fi

	#����Ƿ������ں˱���
	if [ "$(Is_Kernel_Building)" = "Building" ]; then
		show_vit "building kernel now, please wait a minute"
		return 0;
	else
		Is_Kernel_Getting -c
	fi

	#������������ļ�
	echo "call : scp -r $CHIPHD_LICHEE_DIR/out $LICHEE_DIR"
	if [ -d $LICHEE_DIR/out ]; then
		rm -rf $LICHEE_DIR/out
	fi
	scp $CHIPHD_LICHEE_DIR/out.tar $LICHEE_DIR/ || scp -r $CHIPHD_LICHEE_DIR/out $LICHEE_DIR
	if [ -f $LICHEE_DIR/out.tar ]; then
		cd $LICHEE_DIR && tar xf out.tar && cd -
		rm $LICHEE_DIR/out.tar
	fi
	show_vit "done : copy $CHIPHD_LICHEE_DIR/out"

	#git����buildroot
	local NeedBuildroot="`chiphd_bsp_need_buildroot $THIS_LICHEE_CHIP`"
	if [ "$NeedBuildroot" != "false" ]; then
		echo "git update : $LICHEE_DIR/buildroot"
		##git clone
		if [ "$NeedBuildroot" ]; then
			if [ -d $LICHEE_DIR/buildroot ]; then
				if [ -d $LICHEE_DIR/buildroot/.git ]; then
					cd $LICHEE_DIR/buildroot && git pull #&& show_vit "done : git pull $CHIPHD_LICHEE_DIR/buildroot"
					git remote prune origin
					remoteHeadName=$(git remote show origin | grep "HEAD" | sed "s/.*: //")
					#echo $remoteHeadName
					if [ "`echo $remoteHeadName | grep '):'`" ]; then
						show_vit "remote HEAD is ambiguous"
					else
						git checkout $remoteHeadName && git pull && show_vit "done : git pull $CHIPHD_LICHEE_DIR/buildroot"
					fi
				else
					cd $LICHEE_DIR && git clone $CHIPHD_LICHEE_DIR/buildroot && show_vit "done : git clone $CHIPHD_LICHEE_DIR/buildroot"
				fi
			else
				cd $LICHEE_DIR && git clone $CHIPHD_LICHEE_DIR/buildroot && show_vit "done : git clone $CHIPHD_LICHEE_DIR/buildroot"
			fi
			##scp
			if [ "$NeedBuildroot" == "scp" ]; then
				cd $LICHEE_DIR/buildroot && scp -r $CHIPHD_LICHEE_DIR/buildroot/output . && show_vit "done : scp buildroot/output"
			fi
		fi
	fi

	#git����toolsĿ¼
	echo "git update : $LICHEE_DIR/tools"
	if [ -d $LICHEE_DIR/tools ]; then
		if [ -d $LICHEE_DIR/tools/.git ]; then
			cd $LICHEE_DIR/tools && git pull #&& show_vit "done : git pull $CHIPHD_LICHEE_DIR/tools"
			git remote prune origin
			remoteHeadName=$(git remote show origin | grep "HEAD" | sed "s/.*: //")
			#echo $remoteHeadName
			if [ "`echo $remoteHeadName | grep '):'`" ]; then
				show_vit "remote HEAD is ambiguous"
			else
				git checkout $remoteHeadName && git pull && show_vit "done : git pull $CHIPHD_LICHEE_DIR/tools"
			fi
		else
			cd $LICHEE_DIR && git clone $CHIPHD_LICHEE_DIR/tools && show_vit "done : git clone $CHIPHD_LICHEE_DIR/tools"
		fi
	else
		cd $LICHEE_DIR && git clone $CHIPHD_LICHEE_DIR/tools && show_vit "done : git clone $CHIPHD_LICHEE_DIR/tools"
	fi

	#�������,ɾ�����
	Is_Kernel_Getting -d

	this_resume_pwd

	echo "call : extract-bsp"
	extract-bsp && show_vit "done : extract-bsp" && cp-lichee-tag-file

}

##ɾ�������ļ�
function quicklyClean()
{
	if [ "$OUT" ]; then
		if [ -d "$OUT" ]; then
			if [ $1 ]; then
				if [ $1 = "-a" ]; then
					MyClean="root system recovery symbols data kernel recovery.fstab *.img *.ko"
				else
					MyClean="root system *.ko"
				fi
			else
				MyClean="root system *.ko"
			fi
  		cd $OUT && pwd && rm -rf ${MyClean} && ls -alF && cd -
			(echo "****************************************************")
			show_vit "    clean : $OUT\n      ${MyClean}"
			(echo "****************************************************")
		else
			show_vit "$OUT not exist"
		fi
	else
  	show_vit "NOT lunch"
	fi
}

####����repo git tar�ȹ��ܺ���
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_repo_git_tar.sh

####����repo git tar�ȹ��ܺ���
if [ -f $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_cts.sh ]; then
	source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_cts.sh
fi

#### �����ű�����
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_script_update.sh

#### Ԥװapk����makefile�����ʵ��
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_preinstall_apk.sh

#### ��������
if [ "`is_rockchip_SDK`" = "true" ]; then
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_rk_custom.sh
elif [ "`is_intel_SDK`" = "true" ]; then
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_intel_custom.sh
elif [ "`is_box_SDK`" = "true" ];then
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_box_custom.sh
else
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphd_custom.sh
fi
#############################################################
## end for this script file
#############################################################
