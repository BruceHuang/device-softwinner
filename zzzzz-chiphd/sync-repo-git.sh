#!/bin/bash
############################################################
## auto sync repo and check diff
############################################################
##��ȡrepo����������ip
function RL_repo_get_chiphd_mirror_server_ip()
{
	echo 192.168.1.20
}

##��ȡrepo����������user name
#function RL_repo_get_chiphd_mirror_server_user()
#{
#	echo git
#}

##��ȡrepoԶ����
#echo "auto sync repo function"
function RL_repo_get_remote_name()
{
	local remote_name=$(cat .repo/manifest.xml | grep 'remote\s*name' | sed 's/.*name="\([^"]*\)"*/\1/')
	if [ "$remote_name" ]; then
		echo $remote_name
	else
		echo exdroid
	fi
}

##��ȡrepoԶ�̿�·��
function RL_repo_get_remote_path()
{
	local remote_path=$(cat .repo/manifest.xml | grep 'fetch\s*=\s*"' | sed 's/.*=\s*"\([^"]*\)".*$/\1/')
	if [ "$remote_path" ]; then
		echo $remote_path
	else
		echo "error_path"
	fi
}

##��ȡrepoͬ����֧
function RL_repo_get_revision_branch()
{
	local remote_branch=$(grep 'revision="' .repo/manifest.xml | sed 's/.*revision=\s*"\([^"]*\)".*$/\1/')
	if [ "$remote_branch" ]; then
		echo $remote_branch
	else
		echo "develop"
	fi
}

##���repoԶ�̿�·���Ƿ���ڼ��Ϸ�
function RL_repo_verify_remote_path()
{
	local rRepoPath=$(RL_repo_get_remote_path)
	local REPO_SERVER_IP=$(RL_repo_get_chiphd_mirror_server_ip)
	local thisServerAddr=$(get_my_ip_addr)
	local retVal=""

	if [ "$thisServerAddr" != "$REPO_SERVER_IP" ]; then
		##����20������
		retVal=$(ssh git@${REPO_SERVER_IP} "if [ -d ${rRepoPath} -a -d ${rRepoPath}/repo.git ]; then echo 1; else echo 0; fi")
	else
		retVal=$(if [ -d ${rRepoPath} -a -d ${rRepoPath}/repo.git ]; then echo 1; else echo 0; fi)
	fi

	if [ $retVal == "1" ]; then
		echo "verified path"
	else
		echo "error_path"
	fi
}

##ͬ�����д���
function RL_repo_remote_update()
{
	r_name=$1 #$(RL_repo_get_remote_name)
	if [ "$r_name" ]; then
		echo "now get remote-$r_name repo-git data ..."
		echo "repo forall -c 'pwd && git fetch $r_name'"
		repo forall -c "pwd && git fetch $r_name"
	else
		echo "get remote name fail"
	fi
}

##�Ƚϴ���log
function RL_repo_diff_log()
{
	lf1="$1"
	lf2="$2"
	r_branch="$3"
	if [ -f "$lf1" -a -f "$lf2" ]; then
		diff_commit="$(grep -wvf "$lf1" "$lf2" | sed 's/^commit\s*//' | tr '[\r\n]' ' ')"
		#echo "$diff_commit"
		if [ "$diff_commit" ]; then
			line=0
			show_gtip "need git diff $r_branch at:"
			for commitId in $diff_commit ; do
				line=`sed -n "/$commitId/=" $lf2`
				line=$(expr $line - 1)
				sed -n "${line}p" $lf2
			done
			show_gtip "                      end git-repo path"
		else
			show_gtip "Remote branch $r_branch up-to-date already"
		fi
	else
		echo "no file : $lf1 or $lf2"
	fi
}

##�Ƚϴ���log,��������Ӧ��git��
function RL_repo_diff_log_and_fetch()
{
	lf1="$1"
	lf2="$2"
	r_repoName="$3"
	r_branch="$4"
	if [ -f "$lf1" -a -f "$lf2" ]; then
		local sha1_f1="`sha1sum $lf1 | awk '{print $1}'`"
		local sha1_f2="`sha1sum $lf2 | awk '{print $1}'`"
		##ʹ��sha1sum���ٱȽ�
		if [ "$sha1_f1" == "$sha1_f2" ]; then
			diff_commit=
		else
			awk --posix '$1=="commit" && $2 ~ /^[0-9a-f]{40}$/ && NF==2  {printf "%s\n%s\n",x,$0};{x=$0}' $lf1 > ${lf1}.sha1sum.log
			awk --posix '$1=="commit" && $2 ~ /^[0-9a-f]{40}$/ && NF==2  {printf "%s\n%s\n",x,$0};{x=$0}' $lf2 > ${lf2}.sha1sum.log
			local_diff_f1="$lf1"
			local_diff_f2="$lf2"
			if [ -f ${lf1}.sha1sum.log -a -f ${lf2}.sha1sum.log ]; then
				local_diff_f1="${lf1}.sha1sum.log"
				local_diff_f2="${lf2}.sha1sum.log"
			fi
			diff_commit="$(grep -wvf "$local_diff_f1" "$local_diff_f2" | sed 's/^commit\s*//' | tr '[\r\n]' ' ')"
		fi
		#echo "$diff_commit"
		if [ "$diff_commit" ]; then
			#������¼�ļ���
			local aosp_top=$(gettop)
			if [ "$CHIPHD_ANDROID_SCRIPT_PATH" ]; then
				if [ -d $CHIPHD_ANDROID_SCRIPT_PATH/history ]; then
					:
				else
					mkdir $CHIPHD_ANDROID_SCRIPT_PATH/history
				fi
			else
				CHIPHD_ANDROID_SCRIPT_PATH=device/softwinner/zzzzz-chiphd
				mkdir -p $aosp_top/$CHIPHD_ANDROID_SCRIPT_PATH/history
			fi
			local CHIPHDHistoryDir=${aosp_top}/$CHIPHD_ANDROID_SCRIPT_PATH/history

		  local fetchGitPath=""
		  local local_r_branch=${r_repoName}/$r_branch
		  local TempTimeStamp=$(date '+%Y%02m%02d_%02k%02M')
			line=0
			show_wtip "need git diff ${r_repoName}/$r_branch at:"
			for commitId in $diff_commit ; do
				line=`sed -n "/$commitId/=" $lf2`
				line=$(expr $line - 1)
				fetchGitPath=$(sed -n "${line}p" $lf2)
				fetchGitPathTName=${CHIPHDHistoryDir}/${TempTimeStamp}__${fetchGitPath//\//.}.txt
				echo -e "Update \e[1;32m$fetchGitPath\e[0m" && $(cd $fetchGitPath && git log ${local_r_branch} -1 >> $fetchGitPathTName && git fetch $r_repoName && git log ${local_r_branch} -1 >> $fetchGitPathTName)
			done
			show_wtip "                      end git-repo path"
		else
			show_gtip "Remote branch ${r_repoName}/$r_branch up-to-date already"
		fi
	else
		echo "no file : $lf1 or $lf2"
	fi
}

##��ȡ��֧log
function RL_repo_get_branch_log()
{
	if [ "$1" -a "$2" ]; then
		local logBranch="$1"
		local logFile="$2"
		local NowPwd=$(gettop)
		if [ "$NowPwd" ]; then : ; else NowPwd=$(pwd); fi
		echo "get log from $logBranch" > $logFile
		repo forall -c "pwd && git log $logBranch -1" | sed "s:^.*${NowPwd}/::" >> $logFile
	fi
}

##��ȡ�����log($1ΪԶ�̿���,��֧���̶�Ϊdevelop, $2Ϊlogfile����,���android��·��)
# Զ�̿��Ŀ¼����winner_sync�ļ�,��ʾ��������ȫ־��汾, log�ļ�д��chiphd_sync_winner
function RL_repo_mirror-repo_get_branch_log()
{
	local REPO_SERVER_IP=$(RL_repo_get_chiphd_mirror_server_ip)
	local thisServerAddr=$(get_my_ip_addr)
	local ChiphdSyncWinnerFlagFile=winner_sync
	local ChiphdSyncWinnerFlag=chiphd_sync_winner
	if [ -z "$thisServerAddr" ]; then
		echo "get this server ip address error : $thisServerAddr"
		return 1
	fi

	local rRepoPath=$(RL_repo_get_remote_path)
	if [ "$rRepoPath" == "error_path" ]; then
		echo 'get repo remote path error'
		return 1
	fi
	#��ȡͬ����֧
	local rRepoBranch=$(RL_repo_get_revision_branch)
	
	if [ "$1" -a "$2" ]; then
		local remoteName="$1"
		local logFile="$2"

		ssh git@$REPO_SERVER_IP "cd $rRepoPath && if [ -f $ChiphdSyncWinnerFlagFile ]; then echo $ChiphdSyncWinnerFlag; else repo forall -c 'pwd && git log $rRepoBranch -1' 2>/dev/null ; fi " > ${logFile}
		
		##ע�ⷵ�غ���
		if [ -f ${logFile} -a "`sed -n '1p' ${logFile} | grep $ChiphdSyncWinnerFlag`" ]; then
			#echo "`cat ${logFile} | grep $ChiphdSyncWinnerFlag`"
			return 0
		fi

		##��ȡrepo��·����ת'/'Ϊ'.'����������ȡ��Ŀ¼���ڵ��к�
		local ppRepoPath=$(sed -n '1'p ${logFile})
		ppRepoPath=$(echo ${ppRepoPath%/*} | sed 's%/%.%g')

		##�ų�repo.git��manifest.gitĿ¼
		local allPathLine=$(sed -n "/${ppRepoPath}/=" ${logFile})
		local kk=0
		for tline in $allPathLine ; do
			kk=$(expr $kk + 1)
			if [ $kk == 3 ]; then
				kk=$tline
				break
			fi
		done
		sed -n "$kk,$"p ${logFile} > ${logFile}.tmp

		##�滻Ϊ��ǰandroid·����ַ
		echo "get log from $remoteName/${rRepoBranch}" > $logFile
		sed "s%^.*${ppRepoPath}/platform/\(.*\).git%\1%"  ${logFile}.tmp  | sed "s%^.*${ppRepoPath}/\(.*\).git%\1%"  >> ${logFile}
	fi
}

##��ʾͬ����ʷ��¼
function RL_repo_show_sync_history()
{
	#7���ڵ�ͬ����¼
	local day_find=100
	local str_temp=`echo -e "${day_find}\0346\0227\0245\0345\0206\0205\0347\0232\0204\0345\0220\0214\0346\0255\0245\0350\0256\0260\0345\0275\0225"`

	if [ -d $CHIPHD_ANDROID_SCRIPT_PATH/history ]; then
		if [ "`find $CHIPHD_ANDROID_SCRIPT_PATH/history -name "*.txt" -mtime -${day_find} -print`" ]; then
			show_gtip "------------------------------"
			echo $str_temp && find $CHIPHD_ANDROID_SCRIPT_PATH/history -name "*.txt" -mtime -${day_find} -print
			show_gtip "------------------------------"
		fi
	fi
}

## ��鹫�����ÿ�ĸ���
function RL_repo_fetch_chiphd_device()
{
    local OldPath=`pwd`
    local GitUserAtServer=git@192.168.1.20
    local tDeviceDir=`echo device/softwinner/*-chiphd | sed 's:device/softwinner/zzzzz-chiphd::'`
    if [ "$tDeviceDir" ]; then ##����chiphd��device����
        for pDir in $tDeviceDir
        do
            if [ -d "$pDir" -a -d "$pDir/.git" ]; then
                cd $pDir
                ##��ȡ Զ�̿�����
                local tRemoteName="`git remote -v | awk 'NR==1 {print $1}'`"
                ##��ȡ Զ�̿�URL
                local tRemoteUrl="`git remote -v | awk 'NR==1 {print $2}'`"
                ##��ȡ Զ�̿�·��
                #local tRemoteDir="${tRemoteUrl/#ssh:\/\/git@192.168.1.20/}"
                local tRemoteDir="`echo $tRemoteUrl | sed "s/^.*${GitUserAtServer}//"`"
                tRemoteDir=$(echo $tRemoteDir | sed "s://git_repo:/git_repo:")
                ##��ȡ ��ǰ��֧��
                local tNowBrach="`git symbolic-ref HEAD 2> /dev/null`" && tNowBrach=${tNowBrach##*/}
                ##����Զ�̿��Ӧ��֧���ͼ�����
                if [ "$tNowBrach" -a "`git branch -r | grep "${tNowBrach}$"`" ]; then
                	local thisLog=$(git log $tNowBrach --pretty=format:'%H' --abbrev-commit -1)
                	local thisRemoteLog=$(ssh $GitUserAtServer "cd ${tRemoteDir} && git log $tNowBrach --pretty=format:'%H' --abbrev-commit -1")
                	if [ "$thisLog" == "$thisRemoteLog" ]; then
                	    #local NotFetchTip=
                	    if [ "$tNowBrach" == "develop" ]; then
                	        echo "$pDir not fetch"
                	    else
                	    #���Ǽ��develop��֧, todo ���ⲿ�ִ���Ҫ��Ϊ����
                	        local thisDevelopLog=$(git log develop --pretty=format:'%H' --abbrev-commit -1)
                	        local thisDevelopRemoteLog=$(ssh $GitUserAtServer "cd ${tRemoteDir} && git log develop --pretty=format:'%H' --abbrev-commit -1")
                	        if [ "$thisDevelopLog" == "$thisDevelopRemoteLog" ]; then
                	            echo "$pDir not fetch"
                	        else
                	            echo -e "\e[1;32m$pDir\e[0m git fetch $tRemoteName" && git fetch $tRemoteName
                    	    fi
                	    fi
                	else
                		echo -e "\e[1;32m$pDir\e[0m git fetch $tRemoteName" && git fetch $tRemoteName
                	fi
                else
                	echo "$tNowBrach : no branch or no remote branch"
                fi

                #######��AndroidĿ¼
                cd $OldPath
            fi
        done
    fi
}

##����
function RL_repo_do_remote_sync()
{
	##����Ƿ�chiphd server
	if [ "`IS_CHIPHD_SERVER_BY_IP`" == "false" ]; then
		return 0
	fi

	##��һ������ļ�����ֹ���ն�ͬʱ���ô˺���
	my_time_stamp=$(date '+%Y%02m%02d_%02k%02M')
	doing_sync_flag="${CHIPHD_ANDROID_SCRIPT_PATH}/DoSync__*.stamp"
	if [ "`ls $doing_sync_flag 2>/dev/null`" ]; then
		echo "other shell may do sync now, no sync for `ls $doing_sync_flag`"
		return 0
	fi
	doing_sync_now_flag="${CHIPHD_ANDROID_SCRIPT_PATH}/DoSync__${my_time_stamp}.stamp"
	touch $doing_sync_now_flag

    RL_repo_fetch_chiphd_device

	need_sync="sync"
	repo_name=$(RL_repo_get_remote_name)
	r_track_branch=$(RL_repo_get_revision_branch)
	old_logf="${CHIPHD_ANDROID_SCRIPT_PATH}/old_${repo_name}.log"
	new_logf="${CHIPHD_ANDROID_SCRIPT_PATH}/new_${repo_name}.log"
	old_logf_bak="${CHIPHD_ANDROID_SCRIPT_PATH}/old_${repo_name}.log.txt"
	new_logf_bak="${CHIPHD_ANDROID_SCRIPT_PATH}/new_${repo_name}.log.txt"

	##���Զ�̿��Ƿ�����Զ�ͬ��(��Ҫ���ڴ�汾����),����ȡlog
	echo "create $new_logf" && RL_repo_mirror-repo_get_branch_log ${repo_name} $new_logf
	if [ -f ${new_logf} -a "`sed -n '1p' $new_logf | grep chiphd_sync_winner`" ]; then
		show_wtip "    SDK update from allwinner now... , stop auto-sync"
		##ɾ������ļ�
		if [ "`ls $doing_sync_flag 2>/dev/null`" ]; then
			rm "`ls $doing_sync_flag 2>/dev/null`"
		fi
		RL_repo_show_sync_history
		return 0
	fi
	##��ȡ���ؿ�log
	echo "create $old_logf" && RL_repo_get_branch_log "${repo_name}/${r_track_branch}" $old_logf
	#�Ƚ��ύid����ʾ���θ��µĿ�
	RL_repo_diff_log_and_fetch $old_logf $new_logf ${repo_name} ${r_track_branch}

	##ɾ������ļ�
	if [ "`ls $doing_sync_flag 2>/dev/null`" ]; then
		rm "`ls $doing_sync_flag 2>/dev/null`"
	fi

	RL_repo_show_sync_history
}

#############################################################
## end for this script file
#############################################################
