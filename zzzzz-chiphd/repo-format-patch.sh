#!/bin/bash

################################################################################
####
################################################################################
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

# show green/good/great tip
function show_gtip() {
#	echo "num=$#"
#	echo "$@"
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e "\e[1;32m$mytipid\e[0m"
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

# ��repoͬ��Ŀ¼�´�git����
function repo_apply_git_patch() {
	if [ "$1" -a -f "$1" ]; then
		echo "-------------------------------------------------"
	else
		echo "no file $1"
		return 1
	fi
	
	git_patch_file="$1"
	#����Ŀ·��
	PrjPath="`sed -n '1p' $git_patch_file | sed "s/^project //" `"
	PatchPath=`pwd`
	if [ -d "$PrjPath" ]; then
		pFile="${PatchPath}/${git_patch_file}"
		cd "$PrjPath" && pwd
		if [ -f "$pFile" ]; then
			#�ȼ���Ƿ���Դ�,Ȼ����am
			echo -e "\e[1;33m apply --check : $pFile \e[0m" && git apply --check $pFile && echo "----------am $pFile ----------" && git apply --ignore-whitespace $pFile
			if [ "$?" == "0" ]; then
				#�ɹ�,����ɾ��patch�ļ���
				show_gtip "----------am $pFile ok, del it." && rm "$pFile"
			else
				#ʧ��,�˳�����
				show_vit "---- apply --check fail"
			fi
		else
			show_vit "no file : $pFile"
		fi
	else
		show_vit "no $PrjPath or get git-path error"
	fi
	cd "$PatchPath"
}


# ��repo diff�����Ĳ���
function apply_repo_patch() {
	if [ "$1" -a -f "$1" ]; then
		echo "now apply : $1"
	else
		echo "no file $1"
		return 1
	fi
	
	repo_patch_file="$1"

	#��Ŀ��ʼ�����ļ���
	lineRrjStartSet=`sed -n "/^project /=" $repo_patch_file | tr "\n" " "`
	#��ȡ��Ŀ���������ļ���
	lineRrjEndSet=""
	kk=0
	for i in $lineRrjStartSet
	do
		if [ $kk -eq 0 ]; then
			kk=`expr $kk + 1`
		else
			kk=`expr $kk + 1`
			lineRrjEndSet="$lineRrjEndSet `expr $i - 1`"
		fi
	done
	lineRrjEndSet=`echo $lineRrjEndSet | sed "s/^ //"`
	lineRrjEndSet="$lineRrjEndSet `sed -n '$=' $repo_patch_file`"

	#echo "$lineRrjStartSet"
	#echo "$lineRrjEndSet"

	#��ȡ���ⲹ��
	kk=0
	for i in $lineRrjStartSet
	do
		for j in $lineRrjEndSet
		do
			if [ $i -gt $j ]; then
				continue
			else
				kk=`expr $kk + 1`
				tempPrjFile="${repo_patch_file}.prj${kk}.patch"
				sed -n "$i,${j}p" "$repo_patch_file" > $tempPrjFile
				repo_apply_git_patch $tempPrjFile
				break
			fi
		done
	done
	
}


###################################################################################
##�����ʼ�������һ����ȫ־�ķ���tag����$1����
###################################################################################
function create_repo_MailPatch() {
	local TagName1=$1
	##local TagName2=$2  ##��δ��֤������������
	local TagName2="HEAD"
	
	if [ ! "$TagName1" ]; then
		echo "need para : tag or branch name"
		return 0
	fi

	local RepoPath=`pwd`
	local RepoName=${RepoPath##*/}
	local SDKPath=${RepoPath%/*}
	local SDKName=${SDKPath##*/}

	MY_DAY=$(date '+%Y%02m%02d')
	MY_TIME=$(date '+%02k%02M')
	MY_TIME_STAMP=${MY_DAY}   ##${MY_DAY}-${MY_TIME}

##���ɲ�����Ŀ¼
	local PatchsDir=${SDKPath}/patch/${MY_TIME_STAMP}/${RepoName}
##���ɲ�����git���¼
	local GitPatchRecordFile=${SDKPath}/patch/${MY_TIME_STAMP}/${RepoName}/PatchGitName.log
##��Ҫ���ɲ�����git�⼯��
	local DiffGitSet=""
	echo "getting diff $TagName1 $TagName2" 
	DiffGitSet=$(repo forall -p -c git diff --stat $TagName1 $TagName2 | grep "^project " | sed 's/project //')

	if [ "$DiffGitSet" ]; then
#		kk=0
		for CurGit in $DiffGitSet
		do
			show_vit "format-patch $CurGit"
			CurGitPatchPath=$PatchsDir/$CurGit
			mkdir -p $CurGitPatchPath
			## ����Ӧ��gitĿ¼�в�������
			cd $RepoPath/$CurGit && git format-patch $TagName1 -o $CurGitPatchPath && echo "$CurGit" >> $GitPatchRecordFile
			cd $RepoPath
		done
		
		show_vit "done : $TagName1 patchs"
	else
		show_vit "no diff between $TagName1 $TagName2"
	fi
}

###################################################################################
##Ӧ���ʼ�������һ����ȫ־�ķ���tag����$1����
###################################################################################
function patch_repo-git-patch() {
	local PatchsDir="$1" ##������repo��ӦĿ¼
	if [ "$PatchsDir" ]; then
		if [ ! -d "$PatchsDir" ]; then
			echo "no $PatchsDir"
			return 1
		fi
	else
		echo "need repo-git-patch-dir"
		return 0
	fi
	local GitPatchRecordFile="$PatchsDir/PatchGitName.log" ##��gitĿ¼��¼�ļ�
	if [ ! -f $GitPatchRecordFile ]; then
		echo "no $GitPatchRecordFile"
		return 1
	fi

	ApllyPatchCmd=aplly
	if [ "$2" -a "$2" == "am" ]; then
		ApllyPatchCmd=am
	fi

	local RepoPath=`pwd`
	local RepoName=${RepoPath##*/}
	local SDKPath=${RepoPath%/*}
	local SDKName=${SDKPath##*/}
	
	DiffGitSet=$(cat $GitPatchRecordFile | tr '[\r\n]' ' ')
	if [ "$DiffGitSet" ]; then
#		kk=0
		for CurGit in $DiffGitSet
		do
			show_vit "$ApllyPatchCmd patch at $CurGit"
			CurGitPatchPath=$PatchsDir/$CurGit
			CurGitPatchs=`ls $CurGitPatchPath`
			## ����Ӧ��gitĿ¼�д򲹶�
			cd $RepoPath/$CurGit

			for CurPatchFile in $CurGitPatchs
			do
				pFile=$RepoPath/$CurGit/$CurPatchFile
				if [ -f $pFile ]; then
					#�ȼ���Ƿ���Դ�,Ȼ����Ӧ��
					echo -e "\e[1;33m apply --check : $pFile \e[0m" && git apply --check $pFile && git $ApllyPatchCmd --ignore-whitespace $pFile
					if [ "$?" == "0" ]; then
						#�ɹ�,����ɾ��patch�ļ���
						show_gtip "----------$ApllyPatchCmd $pFile ok, del it." && rm "$pFile"
					else
						#ʧ��,�˳�����
						show_vit "---- apply --check fail"
						##break
					fi
				else
					show_vit "no file : $pFile"
				fi
			done

			cd $RepoPath
		done
		
		show_vit "done : $ApllyPatchCmd $TagName1 patchs"
	else
		show_vit "no diff"
	fi
	
}

# ##############################end of file


