#!/bin/bash
exec 1> >(tee -a /var/log/test.log)
exec 2> >(tee -a /var/log/test.log)

while true
trap ctrl_c INT
function ctrl_c() {
        echo "Exit from tools"
        exit 1
                  } 
do

# definition of paths to files to be copien (pathfrom) and the path where to copy (pathto)
gg() {
	pathfrom=''
	echo -n "Path to the copied file: "
  	read pathfrom
  	pathto=''
  	echo -n "The path where to put the file: "
  	read pathto
  	conf=''
  	echo -en "\nFrom  "$pathfrom
  	echo -en "\nTo  "$pathto
  	echo -en "\nAll is right? y/n: "
  	read conf
  	while [ "$conf" != "y" ]; do
  	gg
  	done
  }

# definition of a file with hosts in the format like: "Hostname 0.0.0.0" and count number of lines in a file
ho() {
	if [ -z "$1" ];
	then
	host='/root/.ssh/config'
	co="$(cat $host  | grep Hostname | awk '{ print $2 }' | wc -l)"
	else
	host="$1"
	co="$(cat $host  | grep Hostname | awk '{ print $2 }' | wc -l)"
	fi
  }


#chose between single comand from line or many commands from a file
lol(){
 	echo "Single or mass commands(s\m)"
 	read tt
 	case "$tt" in

# form an array of commands
s)
	echo "Type your command:"
	commands=''
	read commands
	massive[1]=$commands
	cn=1
  ;;

# form an array of commands
m)
	commands=''
	echo -en "Path to file with commands: "
	read commands
	conf2=''
	if [ "$commands" = "e" ];
	then
	echo -en "Chose exist commands file:\n"
	ls /home/admin/small_update/commands/
	read commands
	commands='/home/admin/small_update/commands/'$commands
	fi
	echo -en "Path to commands file: $commands"
	echo -en "\nAll is right? y/n: "
	read conf2
	while [ "$conf2" != "y" ]; do
	lol
	done
	massive=(*)
	cn="$(cat $commands | wc -l)"
	for (( z=1; z<=$cn; z++))
	do
	massive[$z]="$(cat $commands  | sed -n "$z"p)"
	done
  ;;
  esac
  }

# execution of commands from an array line by line
fil(){
	for ((z=1; z<=$cn; z++)) do
	ssh -o ConnectTimeout=10 admin@$hosts -t ${massive[$z]}
	done
	exit 0
  }

# copy or put to all server files
sall() {
	for (( x=1; x <=$co; x++))
	do
	hosts="$(cat $host  | grep Hostname | awk '{ print $2 }' | sed -n "$x"p)"
	case $1 in
cp)
	scp -o ConnectTimeout=10 $pathfrom admin@$hosts:$pathto #прямое копирование
  ;;
rcp)
	scp -o ConnectTimeout=10 admin@$hosts:$pathfrom $pathto #обратное копирование
  ;;
file)
	fil
  ;;
  esac
  done
  }         

# copying to
put() {
	gg
	ho $1
	conf=''
	sall cp
	exit 0
  }

# copying from
get() {
	gg
	ho $1
	conf=''
	sall rcp
	exit 0
  }


# remote commands
rcommand() {
	ho
	conf=''
	pas=''
	lol
	sall file
	exit 0
  }

case "$1" in
-p)
	put $2
  ;;

-c)
	rcommand
  ;;

-g)
	get $2
  ;;

-h)
	echo "-p put some thing to the servers"
	echo "-c some command to servers"
	echo "-g get some thing from the servers"
	exit 0
  ;;

*)
	echo "$1 is not an option"
	echo "-p put some thing to the servers"
	echo "-c some command to servers"
	echo "-g get some thing from the servers"
	exit 0
  ;;

esac

done
