#!/bin/bash

aaa=`find -name polaris_chiphd.mk`

##���ҵ���ÿ���ļ����д���
line=0
for f in $aaa
do
    line=$(sed -n '/modules.mk/='  $f)
    line=`expr $line + 1`
    #echo $line
    ##��$line����һ��
    sed -i "$line i \$\(call inherit-product-if-exists, \$\(LOCAL_PATH\)\/preApk\/ChiphdPreApk.mk\)" $f
done


#############################################################
## end for this script file
#############################################################

