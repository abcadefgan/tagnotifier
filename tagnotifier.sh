#!/bin/bash
#
#
#   ▀▀█▀▀ ▄▀▀▀▄ ▄▀▀▀▀ █▄  █ ▄▀▀▀▄ ▀▀█▀▀ ▀▀█▀▀ █▀▀▀▀ ▀▀█▀▀ █▀▀▀▀ █▀▀▀▄ 
#     █   █▀▀▀█ █ ▀▀█ █ ▀▄█ █   █   █     █   █▀▀     █   █▀▀   █▀▀▀▄ 
#     ▀   ▀   ▀  ▀▀▀  ▀   ▀  ▀▀▀    ▀   ▀▀▀▀▀ ▀     ▀▀▀▀▀ ▀▀▀▀▀ ▀   ▀ 
#                      - Anders K. Iden - 2025 -
#
#            to be used with the exec/keyhandler in sxiv
#
#  Assumes only one root tag, hierarchies involving several sublevels 
#  will be compressed to one!
#
#  put inside your $HOME/.config/(n)sxiv/exec/keyhandler e.g.
#
#  Takes sxiv / nsxiv's $file variable as input, or uses the first
#  command-line argument if launched outside sxiv.
#

# check if we have a $file variable or make one using $1

if [ -z $file ]
	then
		if [ -z $1 ]
		then
			echo "No file specified..."
			exit 1
		else
			file=$1
		fi
fi

#Getting hierarchical tags using exiftool, removing the title from exiftool's output

string=$(exiftool -hierarchicalsubject $file  | awk -F [:] '{print $2}')

# Tidying up string for creation of array, replacing commas with newlines to ease 
# the creation of an array — probably possible to solve this in a better way?

sorted_string=$(echo "$string" | sed 's/^ *//g;s/, /\n/g;s/ /_/g' | sort )
new_string=$(echo -e $sorted_string ) 

read -a tagsArray <<< "$new_string"

#Getting the first root tag and writing it to the temporary file tmpTagFile.txt

firstTag=$(echo "${array[0]}" | awk -F '|' '{print $1}')
echo "$firstTag" > tmpTagFile.txt

for tagg in "${tagsArray[@]}"
do

	# checking how many tags are under the roottag
	 
	numFields="$(echo "$tagg" | awk -F'|' '{print NF}')"
	checkTag=$(echo "$tagg" | awk -F '|' '{print $1}')

	# does tag read differ from the root tag?

	if [ "$checkTag" != "$firstTag"  ]
	then
		firstTag="$(echo $tagg | awk -F '|' '{print $1}')"
		echo "$firstTag" >> tmpTagFile.txt
	fi

	# if we have more than one tag under the root tag, run through all of them

	if [[ $numFields -gt 2 ]]
	then 
		for (( c=2;c<=$numFields;c++  ))
			do
				readTag=$readTag$(echo -e "$(echo $tagg|awk -F'|' -v nummer=$c '{print $nummer}')")", "
				readTag=$(echo -e "$readTag" | sed 's/, /\n\t/g;s/_/ /g')
			done

	# or just put the tag in the temp file
	
	else
		readTag=$(echo "$tagg" | awk -F '|' '{print $2}' | sed 's/_/ /g' )
	fi
		echo -e "\t$readTag" >> tmpTagFile.txt
	
	readTag=""
done

if ! [ -f tmpTagFile.txt ]; then
	echo "No tags found..."
	exit 1
fi

notify-send "Tags:" "$(cat tmpTagFile.txt)"

exit 0
