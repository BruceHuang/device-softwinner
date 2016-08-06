#!/bin/bash

################################################################################
####��������
MyAAPT=$(gettop)/$CHIPHD_ANDROID_SCRIPT_PATH/apktool/aapt
################################################################################

### �Ƴ��ļ����Ŀո�
function RemoveSpaceOfApkName()
{
	#ȥ���ļ����ո�
	local new_f=
	for f in *.apk
	do
		new_f=`echo "$f" | sed 's/[ ]\+/_/g' `
		if [ "$new_f" != "$f" ]; then
			mv "$f" "$new_f" && echo "rename '$f' $new_f"
		fi
	done
}

### �԰���������apk
function RenameApkByPackageName()
{
	local RenameMethod=$1
	local EndFix=$2
	local thisApkToRenameSet=
	if [ "$RenameMethod" -a "$RenameMethod" = "packagename" ]; then
		thisApkToRenameSet=`ls *.apk` ##apk��ֻ�ð���
	else
		thisApkToRenameSet=`ls *.apk | grep -v "^[0-9A-Za-z\._|\-]*$"` ##�����apk��ֻ����[��ĸ����-._]
	fi
	if [ "$thisApkToRenameSet" ]; then
		local thisApkPNamg="" ##apk package name

		for f in $thisApkToRenameSet
		do
			thisApkPNamg="`$MyAAPT dump badging $f | sed -n '/^package:/'p | awk -F\' '{print $(2)}'`"
			if [ "$thisApkPNamg" -a "$thisApkPNamg" != "$f" ]; then
				mv "$f" "${thisApkPNamg}${EndFix}.apk" && echo "rename $f --> ${thisApkPNamg}${EndFix}.apk"
			fi
		done
	fi
}

### ��ѹ��Ӧ��apk���ļ�
function UnzipApksLibs()
{
	local _thisApkFNamg="" ##apk name without .apk
	local _thisApkHasLibs=false

	for f in *.apk
	do
		_thisApkFNamg="${f/%.apk/}"
		if [ "`$MyAAPT dump badging $f | sed -n '/^native.code/'p`" ]; then
			_thisApkHasLibs=true
		else
			_thisApkHasLibs=false
		fi
		
		if [ $_thisApkHasLibs == true ]; then
			echo "unzip $f, doing..."
			unzip -qq -j $f `unzip -l $f | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'` -d ./$_thisApkFNamg
		fi
	done
}

### ����Ԥ��װAPK��mk�ļ�
function CreateChiphdPreinstallApkMakeFile()
{
    ## �Ƴ��ļ����ո�
    RemoveSpaceOfApkName
    ## �淶����
    RenameApkByPackageName
	local tPreinstallDir
	if [ "$1" -a "$1" == "--once" ]; then
		tPreinstallDir=preinstall_once
	elif [  "$1" -a "$1" == "--cp"  ]; then
		tPreinstallDir=preinstall_cp
	elif [  "$1" -a "$1" == "--precopy"  ]; then
		tPreinstallDir=precopy
	else
		tPreinstallDir=preinstall
	fi
	local tMakeFileName=Android.mk
	local _thisApkFNamg="" ##apk name without .apk
	####д���ļ�ͷ������Ϊ����һ��EOF��ע���ַ�$Ҫת��
	(cat << EOF) > ./$tMakeFileName

LOCAL_PATH := \$(call my-dir)

EOF
	
	for f in *.apk
	do
		####д��ÿ��APK�Σ�����Ϊ����һ��EOF��ע���ַ�$Ҫת��
		_thisApkFNamg="${f/%.apk/}"
		(cat << EOF) >> ./$tMakeFileName

#########################
include \$(CLEAR_VARS)
LOCAL_MODULE := $_thisApkFNamg
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_PATH := \$(TARGET_OUT)/${tPreinstallDir}
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
include \$(BUILD_PREBUILT)
EOF

	done ##ѭ������
}

### ����Ԥ��װsystem APK��mk�ļ�
function CreateChiphdPreSystemApkMakeFile()
{
    ## �Ƴ��ļ����ո�
    RemoveSpaceOfApkName
    ## �淶����
    RenameApkByPackageName packagename "_chiphd-0"     ##�ļ������"_chiphd-0"������,����.so�Ĵ�����Ҫ
  local IsPrivApp=$1
  local tIsX86Arch=false
	local tMakeFileName=Android.mk
	local _thisApkFNamg="" ##apk name without .apk
	local _thisApkHasLibs=false
	local _curApkLibShortName=
	local tIntelArmLibDir=lib/arm
	local tSystemStandardLibDir=lib
	local tSystemLibDir=lib
	local tDataAppLibDir=app-lib
	local USE_STANDARD_MAKE_FILE=true
	local TEST_JAVA_SRC_FILE=$ANDROID_BUILD_TOP/frameworks/base/services/java/com/android/server/pm/PackageManagerService.java
	if [ -f "$TEST_JAVA_SRC_FILE" ]; then
		if [ "`grep 'earlyPreinstall' $TEST_JAVA_SRC_FILE`" ]; then
			USE_STANDARD_MAKE_FILE=false
		fi
	fi
	## intel ƽ̨��ʱ�ñ�׼makefile
	if [ "$CHIPHD_ANDROID_SCRIPT_PATH" -a "$CHIPHD_ANDROID_SCRIPT_PATH" = "device/intel/zzzzz-chiphd" ]; then
		USE_STANDARD_MAKE_FILE=true
		tIsX86Arch=true
	fi
	if [ "${IsPrivApp}_test" = "priv-app_test" ]; then
		MkIsPrivApp="LOCAL_PRIVILEGED_MODULE := true"
	else
		MkIsPrivApp="LOCAL_PRIVILEGED_MODULE := false"
	fi
	####д���ļ�ͷ������Ϊ����һ��EOF��ע���ַ�$Ҫת��
	(cat << EOF) > ./$tMakeFileName

LOCAL_PATH := \$(call my-dir)

EOF
####����д��makefile�ν���
	for f in *.apk
	do
		####д��ÿ��APK�Σ�����Ϊ����һ��EOF��ע���ַ�$Ҫת��
		_thisApkFNamg="${f/%.apk/}"
		(cat << EOF) >> ./$tMakeFileName


#########################
include \$(CLEAR_VARS)
LOCAL_MODULE := $_thisApkFNamg
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_CLASS := APPS
$MkIsPrivApp
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
include \$(BUILD_PREBUILT)
EOF
####����д��makefile�ν���
    ##���APK�Ƿ��п�
    if [ "`$MyAAPT dump badging $f | sed -n '/^native.code/'p`" ]; then
			_thisApkHasLibs=true
		else
			_thisApkHasLibs=false
		fi
		##��ѹ��
		if [ $_thisApkHasLibs == true ]; then
			if [ "$tIsX86Arch" = "true" ]; then
				All_so_Files="`unzip -l $f | awk '$(NF) ~ /x86\/.*.so$/ {print $(NF)}'`"   ###����armeabi-v7a/Ŀ¼��
				if [ "$All_so_Files" ]; then
					tSystemLibDir=$tSystemStandardLibDir
				else
					tSystemLibDir=$tIntelArmLibDir
					All_so_Files="`unzip -l $f | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}'`"   ###����armeabi-v7a/Ŀ¼��
				fi
			else
				tSystemLibDir=$tSystemStandardLibDir
				All_so_Files="`unzip -l $f | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}'`"   ###����armeabi-v7a/Ŀ¼��
			fi

			if [ "$All_so_Files" ]; then
				: # echo -e "get *.so from \e[1;33marmeabi/\e[0m"
			else
				All_so_Files="`unzip -l $f | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'`"   ###���armeabi/Ŀ¼��
				if [ "$All_so_Files" ]; then
					: # echo -e "get *.so from \e[1;33marmeabi-v7a\e[0m"
				else
					# echo -e "get *.so from \e[1;33marmeabi\e[0m"
					All_so_Files="`unzip -l $f | awk '$(NF) ~ /armeabi.*.so$/ {print $(NF)}'`"   ###�ٴ�armeabi*Ŀ¼��
				fi
			fi
			# thisApkPNamg="`$MyAAPT dump badging $f | sed -n '/^package:/'p | awk -F\' '{print $(2)}'`"
			thisApkLibDir=$_thisApkFNamg
			if [ "$All_so_Files" ]; then
				if [ ! -d "$tDataAppLibDir" ]; then mkdir $tDataAppLibDir ; fi
				echo "unzip .so files from  $f  to  $thisApkLibDir , doing..."
				unzip -qq -j $f $All_so_Files -d ./${tDataAppLibDir}/$thisApkLibDir
			else
				#echo "error : unzip .so files from $f"
				echo -e "\e[1;31merror\e[0m : fail unzip .so files from $f"
				continue
			fi
			#### ��ı�׼makefile����
			if [ "$USE_STANDARD_MAKE_FILE" = "true" ]; then
				##��׼make file����
		    for _curApkLibName in ${tDataAppLibDir}/$thisApkLibDir/*
		    do
		        _curApkLibShortName="${_curApkLibName##*/}"
####д��makefile
		    (cat << EOF) >> ./$tMakeFileName
#########
include \$(CLEAR_VARS)
LOCAL_MODULE := $_curApkLibShortName
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := \$(TARGET_OUT)/$tSystemLibDir
LOCAL_SRC_FILES := $_curApkLibName
LOCAL_MODULE_CLASS := lib
include \$(BUILD_PREBUILT)
EOF
####����д��makefile�ν���
    		done ## ���makefile����ѭ������
			fi

		fi ##��ѹ���жϽ���

	done ## apk ѭ������
	
	#### ���ѹ����ѹ��ʽʵ�ֵ�makefile����
	if [ "$USE_STANDARD_MAKE_FILE" != "true" -a -d ${tDataAppLibDir} ]; then
		##������п��ļ�
		local tDataAppLibTarFile=libsOfPreApk.tar
		tar cvf $tDataAppLibTarFile ${tDataAppLibDir}
		## ��ӵ�makefile
		if [ $? = 0 ]; then
			if [ "${IsPrivApp}_test" = "priv-app_test" -a -f ../system/${tDataAppLibTarFile} ]; then
				#��priv-app��so���system�ĺϲ���ͬһ��ѹ����,�����������ͬ��ѹ����
				echo "tar .so files in system/${tDataAppLibTarFile} for priv-app"
				cd ../system/ && tar xf ../priv-app/${tDataAppLibTarFile} && rm ${tDataAppLibTarFile} && tar cvf $tDataAppLibTarFile ${tDataAppLibDir} && cd -
			else
			####д��makefile
		    (cat << EOF) >> ./$tMakeFileName


######### $tDataAppLibTarFile
include \$(CLEAR_VARS)
LOCAL_MODULE := $tDataAppLibTarFile
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := \$(TARGET_OUT)/preinstall
LOCAL_SRC_FILES := $tDataAppLibTarFile
LOCAL_MODULE_CLASS := lib
include \$(BUILD_PREBUILT)
EOF
####����д��makefile�ν���
			fi ###end of ["${IsPrivApp}_test" = "priv-app_test" -a -f ../system/${tDataAppLibTarFile}]
		else
			echo "error on tar .so files"
		fi
	fi
}

### ����ظ���apk���
function CheckChiphdPreApkDuplicateBuild()
{
	local PreBuilApkMkFile="$1"
	if [ "$PreBuilApkMkFile" -a -f "$PreBuilApkMkFile" ]; then
		DuplicateVal=$(awk 'NR==FNR {a[$3]++} NR>FNR && a[$3] > 1' $PreBuilApkMkFile $PreBuilApkMkFile)
		if [ "$DuplicateVal" ]; then
			DuplicateVal=`echo $DuplicateVal | sed 's/PRODUCT_PACKAGES += //g'`
			if [ "$DuplicateVal" ]; then
				echo -e "Duplicate PreBuild : \e[1;31m $DuplicateVal \e[0m"
				for ff in $DuplicateVal
				do
					echo "---------------------"
					if [ "`echo $ff | grep ".so$"`" ]; then
						echo "#### find find -name $ff" && find -name $ff
					else
						echo "#### find -name ${ff}.apk" && find -name ${ff}.apk
					fi
				done
			else
				echo -e "\e[1;31m Duplicate PreBuild : \e[0m"
			fi
		fi
	fi
}

### ����Ԥ��װdata APK��mk�ļ� ���$1="--once" ��ֻ����ļ�����once
function CreateChiphdPreDataApkMakeFile()
{
    ## �Ƴ��ļ����ո�
    RemoveSpaceOfApkName
    ## �淶����
    RenameApkByPackageName "packagename" "-1" ##ֻ�ð���
	local tMakeFileName=Android.mk
	local tDataAppDir=app
	local tTarFileName=earlyPreApk.tar

	if [ "$1" -a "$1" = "--once" ]; then
		tTarFileName=earlyPreApk.once.tar
	fi

	mkdir $tDataAppDir \
		&& mv *.apk $tDataAppDir \
		&& tar cf $tTarFileName $tDataAppDir

	########## make file����
	####д���ļ�ͷ������Ϊ����һ��EOF��ע���ַ�$Ҫת��
	(cat << EOF) > ./$tMakeFileName

LOCAL_PATH := \$(call my-dir)

EOF
####����д��makefile�ν���
		## ��ӵ�makefile
	if [ -f "$tTarFileName" ]; then
		####д��makefile
		(cat << EOF) >> ./$tMakeFileName

######### $tDataAppLibTarFile
include \$(CLEAR_VARS)
LOCAL_MODULE := $tTarFileName
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := \$(TARGET_OUT)/preinstall
LOCAL_SRC_FILES := $tTarFileName
LOCAL_MODULE_CLASS := lib
include \$(BUILD_PREBUILT)
EOF
####����д��makefile�ν���
	fi

}

### ����Ԥ��װsystem APK��mk�ļ�, $1Ϊ$DEVICEԤװapk��Ŀ¼(�����AndroidĿ¼)
function DoChiphdPreApk()
{
    local OldPath=$(pwd)
    local OemApkPath=$1
    local PreApkTopMkFile=ChiphdPreApk.mk
    
    if [ "$OemApkPath" -a -d $OemApkPath ]; then
        ## preinstall ����
        if [ -d $OemApkPath/preinstall ]; then
            cd $OemApkPath/preinstall
            CreateChiphdPreinstallApkMakeFile
        fi
        ## [ֻ��װһ��] preinstall ����
        if [ -d $OemApkPath/preinstall_once ]; then
            cd $OemApkPath/preinstall_once
            CreateChiphdPreinstallApkMakeFile --once
        fi
        ## system/app ����
        if [ -d $OemApkPath/system ]; then
            cd $OemApkPath/system
            CreateChiphdPreSystemApkMakeFile
        fi
        ## system/priv-app ����
        if [ -d $OemApkPath/priv-app ]; then
            cd $OemApkPath/priv-app
            CreateChiphdPreSystemApkMakeFile priv-app
        fi
        ## data/app ����
        if [ -d $OemApkPath/earlyDataApk ]; then
            cd $OemApkPath/earlyDataApk
            CreateChiphdPreDataApkMakeFile
        fi
        ## data/app ���� apk����
        if [ -d $OemApkPath/cpDataApk ]; then
            cd $OemApkPath/cpDataApk
            CreateChiphdPreinstallApkMakeFile --cp
        fi
        ## data/app ���� precopy����
        if [ -d $OemApkPath/precopy ]; then
            cd $OemApkPath/precopy
            CreateChiphdPreinstallApkMakeFile --precopy
        fi
        ##PreApkTopMkFile
        cd $OemApkPath

        (cat << EOF) > ./$PreApkTopMkFile
LOCAL_PATH := \$(call my-dir)

include \$(call all-makefiles-under,\$(LOCAL_PATH))

EOF
        ## ��ӱ���
        find -name Android.mk | xargs awk '$1=="LOCAL_MODULE" {print "PRODUCT_PACKAGES += " $3 }' >> ./$PreApkTopMkFile
        ##����ظ���
        CheckChiphdPreApkDuplicateBuild $PreApkTopMkFile
        
        cd $OldPath  
    fi
}

#############################################################
## end for this script file
#############################################################

