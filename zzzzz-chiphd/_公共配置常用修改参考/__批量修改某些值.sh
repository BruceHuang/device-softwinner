#!/bin/bash

#���ļ�
aaa=`find -name sys_config.fex`
##��Ҫ�޸ĵļ�
bbb="gc0328 sp0718 sp2518 gc0311 sp0a19 siv120d siv121d"

###
MainKey="camera_list_para"

##���ҵ���ÿ���ļ����д���
line=0
for f in $aaa
do
	#echo "$f"
	for kk in $bbb
	do
		##���Ƿ�ֵΪ0��
		##б��֮�ڵ�Ϊ������ʽ��^Ϊһ�п�ͷ��\s����հ��ַ���
		##\s*��Ϊ������հ��ַ�
    line=$(sed -n "/^$kk\s*=\s*0/="  $f)
    if [ "$line" ]; then  ##�ҵ��͸�Ϊ1
    	sed -i "s/^$kk\s*=\s*0/$kk                 = 1/" $f && echo "modify $f , $kk"
    else
    	ttt="`grep "$kk" $f`"
    	if [ "$ttt" ]; then
    		: #echo "$ttt"
    	else
    		##����
    		line=$(sed -n "/\[$MainKey\]/="  $f)
    		if [ "$line" ]; then
    			 line=`expr $line + 2`
    			 ##����һ��
    			 sed -i "$line i $kk                 = 1" $f
    		else
    			echo "err : not find $MainKey"
    		fi
    	fi
    fi
    ##��$line����һ��
    #sed -i "$line i \$\(call inherit-product-if-exists, \$\(LOCAL_PATH\)\/preApk\/ChiphdPreApk.mk\)" $f
	done
done


#############################################################
## end for this script file
#############################################################

