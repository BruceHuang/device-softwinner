#!/bin/bash

##���ƶ���

##����android logo

##����boot logo

##�������沼��

##���Ʊ�ֽ

##Ԥװapk

##����ͷ�����ļ�

##����build.prop����
#�����ң����ԣ�ʱ�������ȣ�ʱ���ʽ��Ʒ����أ����壬����������ʱ�䣬�������ƣ����뷨��

function note-chiphd() {
cat <<EOF
touch��
1)update wifi & bluetooth time stamp
EOF
}

#function prj_chiphd_help1() {
function prj_chiphd_help() {
	MainDevicePath=$1
	ChiphdDevicePathTop=$2
	ATop=$MainDevicePath/../../..
	
	echo "now update wifi time stamp ..."
	touch -c  ${ATop}/external/wpa_supplicant_8/* && echo "touch -c ${ATop}/external/wpa_supplicant_8/*"
	touch -c  ${ATop}/hardware/libhardware_legacy/* && echo "touch -c ${ATop}/hardware/libhardware_legacy/*"

	echo "now update bluetooth time stamp ..."
	touch -c  ${ATop}/external/bluetooth/*  && echo "touch -c ${ATop}/external/bluetooth/*"
	touch -c  ${ATop}/system/bluetooth/*  && echo "touch -c ${ATop}/system/bluetooth/*"
	note-chiphd
}


