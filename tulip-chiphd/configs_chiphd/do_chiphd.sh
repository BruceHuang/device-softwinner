#!/bin/bash

####����Ƿ�lunch
function chiphd_check_lunch()
{
	if [ "$DEVICE" ]; then
		echo "lunch : path $DEVICE"
	else
		echo 'not lunch'
	fi
}

####ѡ����Ŀ����
function lunch-chiphd()
{
	if [ "$(chiphd_check_lunch)" == "not lunch" ]; then
		echo "not lunch"
		return 0
	else
		thisDevice=`echo $DEVICE`
	fi

	local ConfigsFName=chiphd_config.sh
	local ConfigsPath=${thisDevice}/configs_chiphd
	local ProductSetTop=${ConfigsPath}/custom
##�������пͻ���������
#	local ProductSet=`find $ConfigsPath -name $ConfigsFName`

	local ProductSetShort=`find $ProductSetTop -name $ConfigsFName | awk -F/ '{print $(NF-2) "/" $(NF-1)}'`
	local ProductSelExitName=select/exit
	local ProductShortSelSet="$ProductSetShort $ProductSelExitName"
	
	
	local ProductSel=
	
	select MySEL in $ProductShortSelSet; do
		case $MySEL in
			"$ProductSelExitName")
				echo -e "   selected \e[1;31m$MySEL\e[0m"
				break;
			;;
			*)
				if [ "$MySEL" ]; then
					#echo "$ProductSetTop/$MySEL"
					if [ -d "$ProductSetTop/$MySEL" ]; then
						echo -e "   selected \e[1;31m$MySEL\e[0m"
						ProductSel=$MySEL
						break;
					else
						echo -e "   error selected \e[1;31m$MySEL\e[0m"
					fi
				else
					echo -e "  \e[1;31m error selected \e[0m"
				fi
			;;
		esac ####end case
	done ####end select
	
	local ProductSelPath="$ProductSetTop/$MySEL"
	if [ "$ProductSel" -a -d "$ProductSelPath" -a ! "$ProductSelPath" = "$ProductSetTop/" ]; then
		echo "${ProductSelPath}/$ConfigsFName" > ${ConfigsPath}/NowCustom.sh
	fi
}

