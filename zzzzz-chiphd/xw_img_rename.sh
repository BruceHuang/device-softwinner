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

####ɾ�����ڵ��ļ�
function del_exist_file() {
	if [ "$1" ]; then
		if [ -f "$1" ]; then
			rm "$1"
		fi
	fi
}

#��ȡ��myDEVICEĿ¼
#echo $0
thisShFile=$0
myDEVICE="`echo $thisShFile | sed "s%/../zzzzz-chiphd.*%%"`"
####��������ļ�,�Ի�ȡ���ɵ�img�ļ�
XW_IMG_PATH=$ANDROID_BUILD_TOP/../lichee/tools/pack
if [ ! -d $XW_IMG_PATH ]; then
	XW_IMG_PATH=$ANDROID_BUILD_TOP/../lichee/tools/pack_brandy
fi
XW_FLAG_FILE_FOR_RENAME_IMG=$XW_IMG_PATH/xw.nowflag.tmp
if [ "$1" == "--new" ]; then
	touch $XW_FLAG_FILE_FOR_RENAME_IMG
fi
function get_img_origin_name() {
		find $XW_IMG_PATH -name "*.img" -newer $XW_FLAG_FILE_FOR_RENAME_IMG
}

####��ȡandroid�汾
function chiphd_get_android_ver() {
	grep "PLATFORM_VERSION := [4-9]" $ANDROID_BUILD_TOP/build/core/version_defaults.mk | sed 's/^.*=\s*//'
}

####��ȡоƬ���
function chiphd_get_chip_sname() {
	local chip_init_file_name=`echo $myDEVICE/init.sun*i*.rc | sed 's/.*\///'`
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
		init.sun50iw1p1.rc) chip_sname=a64
		;;
		init.sun8i.rc) chip_sname=a23
			if [ -d $myDEVICE/../astar-y3 -o -d $myDEVICE/../astar-yh ]; then
				chip_sname=a33
			fi
			if [ -d $myDEVICE/../octopus-f1 ]; then
				chip_sname=a83
			fi
			if [ -d $myDEVICE/../astar-common -a -d $myDEVICE/../kylin-common -a -d $myDEVICE/../octopus-common ]; then
				chip_sname=a33
			fi
		;;
		*) chip_sname=unknow
		;;
	esac ####end case

	if [ "$chip_sname" == "a31" ]; then
		if [ -d $myDEVICE/../fiber-a31s-evb ]; then
			chip_sname=a31s
		else
			#�����ж������û�������sdkĿ¼��
			thisAVer=`grep "PLATFORM_VERSION := [4-9]" $ANDROID_BUILD_TOP/build/core/version_defaults.mk | sed 's/^.*=\s*//'`
			if [ "$thisAVer" -a "`echo $thisAVer | grep 4.2 2>/dev/null`" ]; then
				thisTop=$(cd $ANDROID_BUILD_TOP && pwd) && thisTop=${thisTop%/*} &&	thisTop=${thisTop##*/} 
				if [ "`echo $thisTop | grep [aA]31[sS] 2>/dev/null`" ]; then
					chip_sname=a31s
				fi
			fi
		fi
	fi

	echo $chip_sname
}

####��ȡsdk���ð汾
function chiphd_get_allwinner_ver() {
	grep "^\s*[^#]ro.product.firmware=" $myDEVICE/*.mk | sed 's/^.*=\s*//' | sed 's/\s*\\//' | sed 's/\r//'
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
	sed -n "$mk_begin,$mk_end"p $1 | grep "^\s*$3\s*=" | sed "s/^\s*$3\s*=//" | sed "s/^\s*//" | sed "s/\s*$//" | sed "s/\"//g"
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

	sed -n "$mk_begin,$mk_end"p $1 | grep "^\s*$3\s*=" | sed "s/^\s*$3\s*=//" | sed "s/^\s*//" | sed "s/\s*$//" | sed "s/\"//g"
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
##ʾ�� sysconfig_CreateImgName sys_config1.fex
###utf8�ַ���: 
##˫   -- \0345\0217\0214   ##��   -- \0345\0215\0225    ##λ   -- \0344\0275\0215
##���� -- \0345\0205\0274\0345\0256\0271  ##���� -- \0350\0223\0235\0347\0211\0231 
##�� -- \0346\0214\0257\0345\0212\0250  ##���� -- \0344\0270\0255\0346\0200\0247 
function sysconfig_CreateImgName() {
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
	
	local TIME_Name=$(date '+%Y%02m%02d')
	local StrCompatible="\0345\0205\0274\0345\0256\0271"
	local StrTmp=$StrCompatible
	##LCD���
	myLcdX=$(sysconfig_getValue_1MKk $fexCfgFile lcd_used lcd_x)
	if [ $thisDebug -ne 0 ]; then echo myLcdX=$myLcdX ; fi
	myLcdY=$(sysconfig_getValue_1MKk $fexCfgFile lcd_used lcd_y)
	if [ $thisDebug -ne 0 ]; then echo myLcdY=$myLcdY ; fi
	myLcdBitwidth=$(sysconfig_getValue_1MKk $fexCfgFile lcd_used lcd_lvds_bitwidth)
	if [ ! "$myLcdBitwidth" ]; then
		myLcdBitwidth=$(sysconfig_getValue_1MKk $fexCfgFile lcd_used lcd_lvds_colordepth)
	fi
	if [ "$myLcdBitwidth" == "1" ]; then
		myLcdBitwidth="6\0344\0275\0215"
	else
		myLcdBitwidth="8\0344\0275\0215"
	fi
	if [ $thisDebug -ne 0 ]; then echo myLcdBitwidth=$myLcdBitwidth ; fi
	
	##DDR���
	myDDR=$(sysconfig_getValue $fexCfgFile dram_clk)
	myDDR="_ddr$myDDR"
	if [ $thisDebug -ne 0 ]; then echo myDDR=$myDDR ; fi
	myOdt=$(sysconfig_getValue $fexCfgFile dram_odt_en)
	if [ $(($myOdt)) -eq 1 ]; then
		myOdt="_odt"
	else
		myOdt=""
	fi
	if [ $thisDebug -ne 0 ]; then echo myOdt=$myOdt ; fi
	
	##�������
	#�Ƿ����
	StrTmp="$StrCompatible"
	#StrTmp=""
	myTP=$(sysconfig_getValue $fexCfgFile ctp_used)
	if [ "$myTP" == "1" ]; then
		myTP="_ctp$StrTmp"
    else
	    myTP=$(sysconfig_getValue $fexCfgFile rtp_used)
	    if [ "$myTP" == "1" ]; then
		    myTP="_rtp"
        else
		    myTP=""##$(sysconfig_getValue $fexCfgFile rtp_used)
	    fi
    fi
	if [ $thisDebug -ne 0 ]; then echo myTP=$myTP ; fi
	
	##����ͷ���
	#�Ƿ����
	#StrTmp="$StrCompatible"
	StrTmp=""
	myCamera=$(sysconfig_getValue_1MKk $fexCfgFile csi_used csi_dev_qty)
	if [ ! "$myCamera" ]; then
		myCamera=$(sysconfig_getValue_1MKk $fexCfgFile vip_used vip_dev_qty)
	fi
	if [ ! "$myCamera" ]; then
        myCamera=0
		camera0_used=$(sysconfig_getValue $fexCfgFile csi0_dev0_used)
		camera1_used=$(sysconfig_getValue $fexCfgFile csi0_dev1_used)
        if [ $camera0_used ] && [ $camera0_used -eq 1 ]; then
            let "myCamera=myCamera+1"
        fi
        if [ $camera1_used ] && [ $camera1_used -eq 1 ]; then
            let "myCamera=myCamera+1"
        fi
	fi

	if [ "$myCamera" ]; then
        if [ $myCamera -eq 1 ]; then
            myCamera="_\0345\0215\0225Camera$StrTmp"
        elif [ $myCamera -eq 2 ]; then
                myCamera="_\0345\0217\0214Camera$StrTmp"
        fi
    fi
	if [ $thisDebug -ne 0 ]; then echo myCameraNum=$myCamera ; fi
	
	##������Ӧ���
	#�Ƿ����
	StrTmp="$StrCompatible"
	#StrTmp=""
	myGsensor=$(sysconfig_getValue $fexCfgFile gsensor_used)
	if [ "$myGsensor" == "0" ]; then
		myGsensor=""
	else
		myGsensor="_gsensor$StrTmp"
	fi
	
	##�����
	myMotor=$(sysconfig_getValue $fexCfgFile motor_used)
	if [ "$myMotor" == "1" ]; then
		myMotor="_\0346\0214\0257\0345\0212\0250"
	else
		myMotor=""
	fi
	if [ $thisDebug -ne 0 ]; then echo myMotor=$myMotor ; fi
	
	##�������
	myBTooth=$(sysconfig_getValue $fexCfgFile bt_used)
	if [ "$myBTooth" == "1" ]; then
		myBTooth="_\0350\0223\0235\0347\0211\0231"
	else
		myBTooth=""
	fi
	#���Android����
	if [ "$myBTooth" ]; then
		if [ ! "`grep "^\s*BOARD_HAVE_BLUETOOTH\s*:=\s*true" $myDEVICE/BoardConfig.mk`" ]; then
			myBTooth=""
		fi
	fi
	if [ $thisDebug -ne 0 ]; then echo myBTooth=$myBTooth ; fi
	
	##wifi���
	#�Ƿ����
	StrTmp="$StrCompatible"
	#StrTmp=""
	myWifi=$(sysconfig_getValue $fexCfgFile todo)
	if [ "$myWifi" == "1" ]; then
		myWifi="_wifi$StrTmp"
	else
		myWifi=""
	fi
	if [ $thisDebug -ne 0 ]; then echo myWifi=$myWifi ; fi
	
	##nand����EMMC
	myStorageType=$(sysconfig_getValue $fexCfgFile storage_type)
	if [ "$myStorageType" == "1" ]; then
		myStorageType="_EMMC0"
	else
		if [ "$myStorageType" == "2" ]; then
			myStorageType="_EMMC2"
		else
			myStorageType=""
		fi
	fi
	
	################### android
	myAndroidVer=$(chiphd_get_android_ver)
	myChipSName=$(chiphd_get_chip_sname)
	myAllwinnerVer=`echo $(chiphd_get_allwinner_ver)`
	
	local MyImgName=`echo -e ${fexCfgDirName}_${myAllwinnerVer}_${myChipSName}_${myAndroidVer}_${TIME_Name}01_${myLcdBitwidth}${myLcdX}x${myLcdY}${myTP}${myCamera}${myGsensor}$myOdt${myMotor}${myBTooth}${myStorageType}${myImgDebugName}_.img`
	echo $MyImgName
}
#sysconfig_CreateImgName sys_config1.fex

if [ "$1" == "--rename" ]; then
	ImgOldName=$(get_img_origin_name)
	ImgNewName=$(sysconfig_CreateImgName $2 $3)
	#echo $ImgOldName
	#echo $ImgNewName
	if [ -f "$ImgOldName" -a "$ImgNewName" ]; then
		del_exist_file "$XW_FLAG_FILE_FOR_RENAME_IMG"
		del_exist_file "${ImgOldName%/*}/$ImgNewName"
		mv $ImgOldName ${ImgOldName%/*}/$ImgNewName && show_vit "$ImgNewName"
	fi
fi

#############################################################
## for chiphd end
#############################################################
