#!/bin/bash
####���ļ�ֻʵ�����������ű�, Ȼ���������ű��������
############################################################
if [ -d device/rockchip ]; then
CHIPHD_ANDROID_SCRIPT_PATH=device/rockchip/zzzzz-chiphd
elif [ -d device/intel ]; then
CHIPHD_ANDROID_SCRIPT_PATH=device/intel/zzzzz-chiphd
else
CHIPHD_ANDROID_SCRIPT_PATH=device/softwinner/zzzzz-chiphd
fi

##����cdĿ¼
temp_chiphd_oooooold_pwd=$OLDPWD
temp_chiphd_nnnnnnew_pwd=$PWD

##���������ڴ�ʵ��
source $CHIPHD_ANDROID_SCRIPT_PATH/com_misc.sh

##�Զ�����
update-chiphd-script-auto

##���������
source $CHIPHD_ANDROID_SCRIPT_PATH/chiphdsetup.sh

##�ָ�cdĿ¼
#if [ -d "$temp_chiphd_oooooold_pwd" ]; then
	cd $temp_chiphd_oooooold_pwd
#fi
cd $temp_chiphd_nnnnnnew_pwd
#############################################################
## end for this script file
#############################################################