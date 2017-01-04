
##�滻��Դ(Ŀǰֻ��֤jpgͼƬ��Ŀ����滻)
function do_chiphd_res_overlay_replace()
{
	local thisAAPT=
	local thisTop=`gettop`
	if [ "$thisTop" -a -d "$thisTop" ]; then
		thisAAPT=$thisTop/out/host/linux-x86/bin/aapt
  else
  	thisAAPT=$thisTop/device/softwinner/zzzzz-chiphd/apktool/aapt
  fi
  
  if [ -f $thisAAPT ]; then
  	: #echo "use aapt : $thisAAPT"
  else
  	return 1
  fi
  
  ##Ϊ�ָ�Ŀ¼״̬����
  local OldPath0=$(echo $OLDPWD)
  local OldPath1=$(echo $PWD)
  ##�����滻apk�Ķ���Ŀ¼
  local MyTargeTopPath=`echo $OUT/obj/APPS`
  ##�滻apk��Դ�Ķ���Ŀ¼
  local MyResOverlayTopPath=`echo $DEVICE/res-chiphd-overlay`
  if [ "$MyTargeTopPath" -a -d $MyTargeTopPath -a "$MyResOverlayTopPath" -a -d $MyResOverlayTopPath ]; then
  	local SubF=`ls -A $MyResOverlayTopPath`
  	if [ "$SubF" ]; then
  		##����ÿ��APKҪ�滻����Դ�ļ���
  		for f in $SubF
  		do
  			#echo "overlay replace $f"
  			if [ -d $MyResOverlayTopPath/$f ]; then
  				##��ȡĿ��apk·��
  				MyTargePath=`find $MyTargeTopPath -name "${f}*intermediates" -type d`
  				if [ "$MyTargePath" -a -d "$MyTargePath" ]; then
  					##��ȡĿ��apk
  					MyTarge=`find $MyTargePath -name "*.apk"`
  					if [ "$MyTarge" -a -f "$MyTarge" ]; then
  						##ʵ���滻
  						cd $MyResOverlayTopPath/$f
  						MyNewFiles=`find res -name "*.*" -type f`
  						if [ "$MyNewFiles" ]; then
  							$thisAAPT remove -v $MyTarge $MyNewFiles
  							$thisAAPT add -v $MyTarge $MyNewFiles
  							#echo "$thisAAPT remove -v $MyTarge $MyNewFiles"
  							#echo "$thisAAPT add -v $MyTarge $MyNewFiles"
  						fi
  					else
  						echo "no result about $f"
  					fi
  				fi
  			fi
  		done
  	fi
  fi

	##��Ŀ¼
  if [ "$OldPath0" -a -d "$OldPath0" ]; then
   cd $OldPath0
  fi
  if [ "$OldPath1" -a -d "$OldPath1" ]; then
   cd $OldPath1
  fi
}

