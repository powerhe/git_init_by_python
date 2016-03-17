#!/bin/bash

#############################################
# Init repo function
#############################################
branch_list=("alps-dev-l1.bsp.brm" "alps-trunk-l1.basic" "alps-trunk-l1.bsp" "alps-trunk-l1.tk" "alps-dev-kernel-3.18" "alps-trunk-m0.basic" "alps-trunk-m0.bsp" "alps-dev-m0.mp9-tel-config")
unset sel_no
unset manifest
function init_repo()
{
	for i in "${!branch_list[@]}" ; do
		echo "$i : ${branch_list[$i]}"
	done
	echo -n "Which branch would you like? [alps-XXX.XXX]"
	read sel_no

	echo "[Init Repo] mtk_repo init -u <source> -b <trunk> -m <manifest file>"
	echo "Please Modifyt the branch name"
	unset init_answer
	unset load_type
	unset daily_time
	read -n1 -p "Do you want to do this init repo operatiton[Y/N]?" init_answer
	case $init_answer in
	Y|y)
		echo "Fine, continue!"
		load_type="normal";;
	D|d)
		echo "Need daily build!"
		load_type="daily";;
	N|n)
		echo "Ok, Skip this operation!"
		return 0;;
	esac

	manifest="manifest-sub.xml"
	if [[ ${branch_list[$sel_no]} = "alps-dev-kernel-3.18" ]] ; then
		manifest="default.xml"
	fi

	if [[ ${branch_list[$sel_no]} = "alps-trunk-m0.basic" ]] ; then
		manifest="default.xml"
	fi

	if [[ $load_type = "normal" ]] ; then
		/mtkoss/git/mtk_repo init -u http://gerrit.mediatek.inc:8080/alps/platform/manifest -b ${branch_list[$sel_no]} -m $manifest
	elif [[ $load_type = "daily" ]] ; then
		read -p "Please enter into daily time! EXP: 2016_01_01_00_00" daily_time
		/mtkoss/git/mtk_repo init -u http://gerrit.mediatek.inc:8080/alps/platform/manifest -b refs/tags/t-${branch_list[$sel_no]}-db.$daily_time -m $manifest
	fi
}



##############################################
# Link hooks
##############################################
function link_hooks()
{
	echo "[Commit Hooks] ln -s ..."
	echo "Only for SWo git branch related operation."
	echo "If you are working for jungle or upstream, no need to link hook"
	unset link_answer
	read -n1 -p "Do you want to do this link operatiton[Y/N]?" link_answer
	case $link_answer in
	Y|y)
		echo "Fine, continue!";;
	N|n)
		echo "Ok, Skip this operation!"
		return 0;;
	esac
	ln -s /mtkoss/git/hooks/wsd/prepare-commit-msg .repo/repo/hooks/
}

##############################################
# mtk_repo sync code base operation
##############################################
echo "mtk_repo sync <project name>"
unset sync_project
unset sync_path
unset sel_path
cur_dir=$(pwd)
function print_lunch_project_name()
{
	n=1
	m=1
	i=1
	echo "enter into print_lunch_project_name"
	cat $cur_dir/.repo/manifests/* > project_tmp.list
	while read LINE
	do
		echo "enter into while"
		echo $LINE
		if [[ $LINE = *\<project* ]] ; then
			name=$(expr `echo $LINE | awk -F '"' '{print $4}'`)
			sync_project[$n]=$name
			path=$(expr `echo $LINE | awk -F '"' '{print $2}'`)
			sync_path[$m]=$path
			let m++
			let n++
		fi
	done < $cur_dir/project_tmp.list

	for i in "${!sync_project[@]}" ; do
		echo "$i : ${sync_project[$i]}"
	done
}

# Create the local branch for commit
function create_branch()
{
	local local_answer
	read -n1 -p "Do you want to do create the local branch[Y/N]?" local_answer
	case $local_answer in
	Y|y)
		echo "Fine, continue!"
		/mtkoss/git/mtk_repo start ${branch_list[$sel_no]} $sel_path;;
	N|n)
	        echo "Ok, Skip this operation!"
		return 0;;
	esac            
}

function sync()
{
	local answer
	local selection=
	print_lunch_project_name
	read -p "Which would you sync? [alps/...] "
	answer_arry=($REPLY)
	for i in "${!answer_arry[@]}" ; do
		if [ -z "${answer_arry[$i]}" ]
		then
			selection=no
		elif (echo -n ${answer_arry[$i]} | grep -q -e "^[0-9][0-9]*$")
		then
			if [ ${answer_arry[$i]} -le ${#sync_project[@]} ]
			then
				selection=${sync_project[${answer_arry[$i]}]}
				sel_path=${sync_path[${answer_arry[$i]}]}
			fi
		fi
		echo $selection
		echo $sel_path

		if [[ $selection = "no"  ]] ; then
			echo "Have no selection of project which need to sync!!!"
		fi
		mosesq /mtkoss/git/mtk_repo sync -j 24 -c -q --no-tags $selection
		create_branch
	done
}

##############################################
# Main Flow
##############################################
# init repo operations
init_repo

# link hooks
link_hooks

# sync code
sync

# Get code or make your changes
# update for new commit template
#git config --global commit.template /mtkeda/CI/gitconfig/.gitcommitms
#git config --global commit.template ~/.gitcommitmsg

echo "########## GIT Init Done ########## !!!"
