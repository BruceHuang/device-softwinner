#!/bin/bash
############################################################
##  �Զ������̼��ű�
############################################################
# show very important tip
function show_vit() {
#	echo "num=$#"
#	echo "$@"
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e "\e[1;31m$mytipid\e[0m"
		done
	fi
}

# show very important tip without line end
function show_vit_nle() {
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e -n "\e[1;31m$mytipid\e[0m"
		done
	fi
}

# show warning tip
function show_wtip() {
#	echo "num=$#"
#	echo "$@"
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e "\e[1;33m$mytipid\e[0m"
		done
	fi
}

# show warning tip without line end
function show_wtip_nle() {
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e -n "\e[1;33m$mytipid\e[0m"
		done
	fi
}

####ɾ�����ڵ��ļ�
function del_exist_file() {
	if [ "$1" ]; then
		if [ -f "$1" ]; then
			rm "$1"
		fi
	fi
}

####��ȡandroid�汾
function chiphd_get_android_ver() {
	grep "PLATFORM_VERSION := [4-9]" $ANDROID_BUILD_TOP/build/core/version_defaults.mk | sed 's/^.*=\s*//'
}

####��ȡоƬ���
function chiphd_get_chip_sname() {
	local chip_init_file_name=`echo $DEVICE/init.sun?i.rc | sed 's/.*\///'`
	local chip_sname=a10
	case $chip_init_file_name  in
		init.sun4i.rc) chip_sname=a10
		;;
		init.sun5i.rc) chip_sname=a13
		;;
		init.sun6i.rc) chip_sname=a31
		;;
		init.sun7i.rc) chip_sname=a20
		;;
		*) chip_sname=unknow
		;;
	esac ####end case

	if [ "$chip_sname" == "a31" ]; then
		if [ "`ls $DEVICE/modules/modules/vfe* 2>/dev/null`" ]; then 
			chip_sname=a31s
		fi
	fi

	echo $chip_sname
}

####��ȡsdk���ð汾
function chiphd_get_allwinner_ver() {
	grep "^\s*[^#]ro.product.firmware=" $DEVICE/*.mk | sed 's/^.*=\s*//' | sed 's/\s*\\//' | sed 's/\r//'
}

###################sys_config function############
####��ȡ$2=$3��ֵ�������е�����,$1Ϊ�ļ���
##ʾ�� sysconfig_getLine_KV sys_config1.fex lcd_used 1
function sysconfig_getLine_KV() {
	if [ $# -lt 3 ]; then
		show_vit "need filename and key-value para"
		return 1
	fi

	sed -n "/^\s*$2\s*=\s*$3\s*/=" $1
}

####��ȡ$2������Χ��ʼ�е�����,$1Ϊ�ļ���
##ʾ�� sysconfig_getLine_MK_0 sys_config1.fex card_boot0_para
function sysconfig_getLine_MK_0() {
	if [ $# -lt 2 ]; then
		show_vit "not enough para"
		return 1
	fi

	sed -n "/^\s*\[$2\]\s*/=" $1
}


####��ȡ$2������Χ�����е�����,$1Ϊ�ļ���
##ʾ�� sysconfig_getLine_MK_1 sys_config1.fex recovery_key
function sysconfig_getLine_MK_1() {
	if [ $# -lt 2 ]; then
		show_vit "not enough para"
		return 1
	fi
	#���������������
	mk_maxLine=200

	local mk_begin=$(sysconfig_getLine_MK_0 $1 $2)
	mk_begin=`expr $mk_begin + 1`
	local mk_end=`expr $mk_begin + $mk_maxLine`

	mk_end=`sed -n "$mk_begin,$mk_end"p $1 | grep -n '^\[.*\]' | sed -n "1,1"p | sed 's/:.*//'`
	if [ "$mk_end" ]; then
		mk_end=`expr $mk_begin + $mk_end - 2`
	else
		mk_end=`awk 'END{print NR}' $1`
	fi
	
	echo $mk_end
}

####��ȡ��$2�п�ʼ�ұ����������е�����,$1Ϊ�ļ���
##ʾ�� sysconfig_getLine_MK_end sys_config1.fex 100
function sysconfig_getLine_MK_end() {
	if [ $# -lt 2 ]; then
		show_vit "not enough para"
		return 1
	fi
	#���������������
	mk_maxLine=200

	local mk_begin=$2
	local mk_end=`expr $mk_begin + $mk_maxLine`

	mk_end=`sed -n "$mk_begin,$mk_end"p $1 | grep -n '^\[.*\]' | sed -n "1,1"p | sed 's/:.*//'`
	if [ "$mk_end" ]; then
		mk_end=`expr $mk_begin + $mk_end - 2`
	else
		mk_end=`awk 'END{print NR}' $1`
	fi

	echo $mk_end
}

####��ȡ$2������$3�Ӽ���ֵ,$1Ϊ�ļ���
##ʾ�� sysconfig_getValue_MKk sys_config1.fex lcd0_para lcd_x 
function sysconfig_getValue_MKk() {
	if [ $# -lt 3 ]; then
		show_vit "not enough para"
		return 1
	fi
	local mk_begin=$(sysconfig_getLine_MK_0 $1 $2)
	mk_begin=`expr $mk_begin + 1`
	local mk_end=$(sysconfig_getLine_MK_end $1 $mk_begin)
	sed -n "$mk_begin,$mk_end"p $1 | grep "^\s*$3" | sed "s/^\s*$3\s*=//" | sed "s/^\s*//" | sed "s/\s*$//" | sed "s/\"//g"
}

####��ȡ$2�Ӽ�Ϊ1���ڵ�������$3�Ӽ���ֵ,$1Ϊ�ļ���
##ʾ�� sysconfig_getValue_1MKk sys_config1.fex lcd_used lcd_x 
function sysconfig_getValue_1MKk() {
	if [ $# -lt 3 ]; then
		show_vit "not enough para"
		return 1
	fi
	local mk_begin=$(sysconfig_getLine_KV $1 $2 1)
	if [ ! "$mk_begin" ]; then
		echo ""
		return 1
	fi
	local mk_end=$(sysconfig_getLine_MK_end $1 $mk_begin)

	sed -n "$mk_begin,$mk_end"p $1 | grep "^\s*$3" | sed "s/^\s*$3\s*=//" | sed "s/^\s*//" | sed "s/\s*$//" | sed "s/\"//g"
}
####��ȡ$2�Ӽ���ֵ($2ҪΪΨһ��),$1Ϊ�ļ���
##ʾ�� sysconfig_getValue sys_config1.fex dram_clk 
function sysconfig_getValue() {
	if [ $# -lt 2 ]; then
		show_vit "not enough para"
		return 1
	fi
  grep "^\s*$2" $1 | sed "s/^\s*$2\s*=//" | sed "s/^\s*//" | sed "s/\s*$//" | sed "s/\"//g"
}

####�����̼�������,$1Ϊ�ļ���
##ʾ�� sysconfig_checkPatchNand sys_config1.fex
###utf8�ַ���: 
##˫   -- \0345\0217\0214   ##��   -- \0345\0215\0225    ##λ   -- \0344\0275\0215
##���� -- \0345\0205\0274\0345\0256\0271  ##���� -- \0350\0223\0235\0347\0211\0231 
##�� -- \0346\0214\0257\0345\0212\0250  ##���� -- \0344\0270\0255\0346\0200\0247 
function sysconfig_checkPatchNand() {
	if [ $# -lt 1 ]; then
		show_vit "not enough para"
		return 1
	fi
	local thisDebug=0

	local fexCfgFile=$1
	local fexCfgDirName=$1
	if [ -f $fexCfgFile ]; then
		#���������ļ�, Ҫ��ȡ����·��
		fexCfgDirName=${fexCfgFile%/*}
	else
		#��������·��, Ҫ��ȡ�����ļ���
		if [ $thisDebug -ne 0 ]; then echo $fexCfgDirName ; fi
		if [ -d $fexCfgDirName ]; then
			if [ -f $fexCfgDirName/sys_config1.fex ]; then
				fexCfgFile=$fexCfgDirName/sys_config1.fex
			else
				fexCfgFile=$fexCfgDirName/sys_config.fex
			fi
		else
			#���������·�����ļ���������
			fexCfgDirName=${fexCfgFile%/*}
			if [ -f $fexCfgDirName/sys_config1.fex ]; then
				fexCfgFile=$fexCfgDirName/sys_config1.fex
			else
				fexCfgFile=$fexCfgDirName/sys_config.fex
			fi
			if [ ! -f $fexCfgFile ]; then
				if [ $thisDebug -ne 0 ]; then echo return-001 ; fi
				return 1
			fi
		fi
	fi
	
	#ֻҪ����Ŀ¼��
	fexCfgDirName=${fexCfgDirName##*/}

	#�������ļ��򵥼��Ϸ���
	if [ -f $fexCfgFile ]; then
		if [ ! "`grep "\[product\]" $fexCfgFile`" ]; then
			if [ $thisDebug -ne 0 ]; then echo return-002 ; fi
			return 1
		fi
	else
		if [ $thisDebug -ne 0 ]; then echo return-003 ; fi
		return 1
	fi

	if [ "$2" = "-d" ]; then
		myImgDebugName="_card0"
	else
		myImgDebugName=""
	fi
	
	################### android
	myAndroidVer=$(chiphd_get_android_ver)
	myChipSName=$(chiphd_get_chip_sname)
	myAllwinnerVer=$(chiphd_get_allwinner_ver)
	
	#��ȡ�Ƚ��ļ������
	local std_sys1File=${fexCfgFile/$fexCfgDirName/xw_check_configs}
	local std_sysDir=${std_sys1File%/*}
	local std_sysPartition=${std_sysDir}/sys_partition.fex
	local my_sysPartition=${fexCfgFile%/*}/sys_partition.fex
	echo $std_sys1File
	echo $std_sysDir
	echo $std_sysPartition
	if [ -d $std_sysDir ]; then
		if [ "$myChipSName" = "a10" -o "$myChipSName" = "a13" ]; then
			std_sysPartition=${std_sysDir}/sys_config.fex
			my_sysPartition=${fexCfgFile%/*}/sys_config.fex
		fi
		
		#nand ����
		stdCfg_good_block_ratio=$(sysconfig_getValue $std_sys1File good_block_ratio)
		if [ "$stdCfg_good_block_ratio" ]; then
			show_wtip "warning : kernel nand patch"
			myCfg_good_block_ratio=$(sysconfig_getValue $fexCfgFile good_block_ratio)
			if [ "$myCfg_good_block_ratio" ]; then
				if [ ! "$stdCfg_good_block_ratio" == "$myCfg_good_block_ratio" ]; then
					show_wtip "          need check good_block_ratio value"
				fi
			else
				show_wtip_nle "          need add " && show_vit_nle "good_block_ratio = $stdCfg_good_block_ratio" && show_wtip " to ${fexCfgFile##*/}" 
			fi
			if [ "$myChipSName" = "a10" -o "$myChipSName" = "a13" ]; then
				my_temp_user_type=$(sysconfig_getValue_MKk $my_sysPartition partition3 user_type)
				if [ "$my_temp_user_type" -a "$my_temp_user_type" == 0 ]; then
					show_wtip_nle "          system partition should modify " && show_vit_nle "user_type = 1" && show_wtip " in sys_config.fex"
				fi
				my_temp_user_type=$(sysconfig_getValue_MKk $my_sysPartition partition4 user_type)
				if [ "$my_temp_user_type" -a "$my_temp_user_type" == 0 ]; then
					show_wtip_nle "          data partition should modify " && show_vit_nle "user_type = 1" && show_wtip " in sys_config.fex"
				fi
				my_temp_user_type=$(sysconfig_getValue_MKk $my_sysPartition partition7 user_type)
				if [ "$my_temp_user_type" -a "$my_temp_user_type" == 0 ]; then
					show_wtip_nle "          cache partition should modify " && show_vit_nle "user_type = 1" && show_wtip " in sys_config.fex"
				fi
			fi
		fi
		#end for nand ����		
	else
		echo "not check configs"
	fi
}
#sysconfig_CreateImgName sys_config1.fex
if [ "$1" ]; then
	sysconfig_checkPatchNand $1
fi

#############################################################
## end for this script file
#############################################################