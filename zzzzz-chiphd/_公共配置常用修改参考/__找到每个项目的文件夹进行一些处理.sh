#!/bin/bash
###��configs_chiphd/custom����
#���ļ��ļ�ȷ����ĿĿ¼������sed�滻Ϊ�¼�Ŀ¼
#aaa=`find -name chiphd_config.sh | sed  's:chiphd_config.sh::g'` # ÿ����Ŀ�ĸ�Ŀ¼
aaa=`find -name chiphd_config.sh | sed  's:chiphd_config.sh:adevice/configs/:g'`
##��Ҫ�޸ĵļ�
#bbb="gc0328 sp0718 sp2518 gc0311 sp0a19 siv120d siv121d"

###
#MainKey="camera_list_para"

##���ҵ���ÿ���ļ����д���
line=0
for f in $aaa
do
	#echo "$f"
	cp ./media_profiles.xml $f   ##���ļ������滻
done


#############################################################
## end for this script file
#############################################################

