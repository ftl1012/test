#!/bin/bash
########################################################################
#This scripts is checking your host system: the cpu ,i/o,mem,network,
# version 1.0
# date: 2018/10/02 14:42:52 
# author: 小a玖拾柒
########################################################################

logdir="/opt/appserver"
dateStamp=`date +"%F %T"`

# 日志记录
function log(){
	type=$1
	log=$2
	mkdir -p ${logdir}
	touch ${logdir}/install.log
	touch ${logdir}/cpuload.log
	touch ${logdir}/io.log
	touch ${logdir}/network.log
	touch ${logdir}/cpu.log
	if [[ ${type} == 'cpu' ]]; then
		echo ${log} >> ${logdir}/cpu.log 2>&1
	elif [[ ${type} == 'cpuload' ]]; then
		echo ${log} >> ${logdir}/cpuload.log 2>&1 
	elif [[ ${type} == 'io' ]]; then
		echo ${log} >> ${logdir}/io.log 2>&1
	elif [[ ${type} == 'network' ]]; then
		echo "${log}" >> ${logdir}/network.log 2>&1
	else
		echo "${log}" >> ${logdir}/install.log 2>&1
	fi
}

#统计cpu的负载信息
function check_cpuload(){
	echo "cpuload" "checking cpuload......................[start]"
	log "cpuload" "checking cpuload.......................[start]"
	rm -rf ${cpuload_tmp}   
	local time=`uptime |awk '{print $1}'`
	local status=`uptime |awk '{print $2}'`
	local using_Time=`uptime |awk '{print $3}'|sed 's#,##g'`
	local users=`uptime |awk '{print $4" "$5}'|sed 's#,##g'`
	local load_average=`uptime |awk '{print $6,$7":",$8,$9,$10}'`
	local cpuload_tmp=`mktemp /tmp/cpuload.XXX`
cat <<EOF >>${cpuload_tmp} 2>&1
#############################################################################
#                            CPU Load INFO                                  #
#############################################################################
+|  Time   |  Status |  Using  |  Users   |        load average            |+
+---------------------------------------------------------------------------+
+| ${time}|   ${status}    |  ${using_Time}   |  ${users} |${load_average} |+
+---------------------------------------------------------------------------+
EOF
	mv ${cpuload_tmp}  ${logdir}/cpuload.log 
	echo "checking cpuload.......................[end]"
	log "cpuload" "checking cpuload........................[end]"
}

# 检查CPU使用率信息
function check_cpu(){
	log "info" "checking cpu............................[start]"
	echo "checking cpu............................[start]"
	rm -rf ${cpu_tmp}
	cpu_tmp=`mktemp /tmp/cpu.XXX`
	cat <<EOF >>${cpu_tmp} 2>&1
#############################################################################
#                            CPU Stat INFO                                  #
#############################################################################
-procs-   -----------memory----------  ---swap-- -----io---- --system--  -----cpu-----
 r  b    swpd   free   buff  cache    si   so   bi    bo    in   cs us  sy  id  wa  st
`vmstat 3 3|sed '1,2d'` 
EOF
	mv ${cpu_tmp} ${logdir}/cpu.log 
	echo "checking cpu............................[end]"
	log "info" "checking cpu............................[end]"
}

# 检查IO
function check_io(){
	log "mem" "checking io............................[start]"
	echo "io" "checking io............................[start]"
	rm -rf ${IO_tmp}   
	local IO_tmp=`mktemp /tmp/io.XXX`
cat <<EOF >>${IO_tmp}  2>&1
`iostat`
EOF
	mv ${IO_tmp}  ${logdir}/io.log
	echo "checking io............................[end]"
	log "io" "checking io............................[end]"
}

# 统计Mem的使用率
function check_mem(){
	log "mem" "checking mem............................[start]"
	echo "checking mem............................[start]"
	rm -rf ${mem_tmp}   
	local mem_tmp=`mktemp /tmp/mem.XXX`
cat <<EOF >>${mem_tmp} 2>&1
`free -m`
EOF
	mv ${mem_tmp} ${logdir}/mem.log 
	echo "checking mem............................[start]"
	log "mem" "checking mem............................[end]"
}

# 设置环境变量
function env(){
	echo "setting evn............................[start]"
	log "info" "setting evn............................[start]"
	rm -rf ${logdir}  
	if [[ -z ${logdir} ]]; then
		mkdir -p ${logdir}
		echo "mkdir ${logdir} Sussessfully!........[done]"
		log "info" "mkdir ${logdir} Sussessfully!........[done]"
	else
		log "info" "${logdir} : No such file or directory"  
		mkdir -p ${logdir}
		echo "mkdir ${logdir} Sussessfully!........[done]"
		log "info" "mkdir ${logdir} Sussessfully!........[done]"
	fi
	export LANG="en_US.UTF-8"               
	log "info" "set Lang as en_US.UTF-8............................[done]"  
	echo "set Lang as en_US.UTF-8............................[done]"  
	user=`whoami`    
	ipInfo=`who -m|awk -F'(' '{print $2}'|sed 's#)##g'`   
	PID=`echo $$`			 
	baseDir=`dirname $0`	 
	baseSh=`basename $0`	 
	logger -i -p local0.notice -t "Webserver" -s "[${dateStamp}]|${user}|${ipInfo}]|${baseDir}/${baseSh}|${PID}|" 
	echo "[${dateStamp}]|${user}|${ipInfo}]|${baseDir}/${baseSh}|${PID}|" 
	echo "setting evn............................[end]"
	log "info" "setting evn............................[end]"
}

# 检查后台进程
function check_jobs(){
	echo "checking system jobs............................[start]"
	log "info" "checking system jobs............................[start]"
	jobs_num=`jobs -l | wc -l`
	if [[ ${jobs_num} -eq 0 ]]; then
		echo "checking system jobs............................[done]"
		log "info" "checking system jobs............................[done]"
		return 0
	elif [[ ${jobs_num} -ne 0 ]]; then
		echo "This session has session in background,please open other session"
		log "info" "This session has session in background,please open other session"
		exit 1
	fi
	echo "checking system jobs............................[end]"
	log "info" "checking system jobs............................[end]"
}

# 检查网络
function check_network(){
	log "network" "checking network............................[start]"
	echo "checking network............................[start]"
	rm -rf ${network_tmp}   
	local Ipaddr=`ifconfig |sed -n '2p'|awk -F':' '{print $2}'|sed 's#  Bcast##g'`
	local Netmask=`ifconfig |sed -n '2p'|awk -F':' '{print $4}'`
	local GateWay=`route  -n|tail -1|awk '{print $2}'`
	local netWorkAdatper_num=`lspci | grep net |wc -l`
	local ipInfo=`who -m|awk -F'(' '{print $2}'|sed 's#)##g'`
	local network_tmp=`mktemp /tmp/network.XXX`
cat <<EOF >${network_tmp}
#########################################################################
#                            Network  INFO                              #
#########################################################################
+|  IPADDR      |        Netmask     |     GateWay    |      From      |+
+-----------------------------------------------------------------------+
+| ${Ipaddr}|   ${Netmask}    |  ${GateWay}   |  ${ipInfo} |+
+-----------------------------------------------------------------------+
EOF
	cat ${network_tmp}  >> ${logdir}/network.log 2>&1
	echo "checking network............................[end]"
	log "network" "checking network............................[end]"
}

# 设置alias
function make_alias(){
    echo "making alias............................[start]"
	log "info" "making alias............................[start]"
	local bashrcFile=/`whoami`/.bashrc
	local flag=`cat /root/.bashrc |grep 'alias_falg'|wc -l`
	if [[ ${flag} -eq 0 ]]; then
		cat <<EOF >>${bashrcFile}
    alias  rm='rm -f'                           
   	alias ..='cd ..'            
    alias ...='cd ../..'            
    alias ....='cd ../../../'       
    alias egrep='egrep --color=auto' 
    alias grep='grep --color=auto'   
    alias l.='ls -d .* --color=auto' 
    alias ll='ls -l --color=auto'    
    alias ls='ls --color=auto'       
    alias l='ls -AlF'                
    alias md='mkdir' 
    #alias_flag
EOF
	else
		return 1
	fi
	source /`whoami`/.bashrc
	echo "making alias............................[end]"
	log "info" "making alias............................[end]"
}

function welcome(){
cat <<EOF
########################################################################
#	                Welcome to user AutoInstallTool
# 								version: 1.0
# 								d a te : ${dateStamp} 
# 								author : 小a玖拾柒
########################################################################
EOF
	check_jobs
	env
	check_mem
	check_io
	check_cpu
	check_network
	check_cpuload
}

function main(){
	welcome
	make_alias

}
	
# 执行程序
main