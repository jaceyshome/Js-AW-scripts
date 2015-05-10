read -p "enter server url: " url
read -p "re-enter server url: " urlcheck

if [ "$url" == "" ]; then
    echo "error: url is empty"
    exit 0
elif [ "$urlcheck" == "" ]; then
    echo "error: url doesn't match"
    exit 0
elif [ "$url" != "$urlcheck" ]; then
    echo "error: url doesn't match"
    exit 0
else
    echo "Server name: $url"
fi

read -p "are you sure? (y/n) " confirm

if [ "$confirm" == "n" ] || [ "$confirm" == "N" ]; then
    exit 0
fi

gitFolderName="$url.git"
textColorRed='\033[0;31m'
textColorGreen='\033[0;32m'
defaultColor='\033[0m'

printf "Remove git folder: ${gitFolderName}"
if [ -d "./$gitFolderName" ]; then
    rm -rf ./$gitFolderName
    printf " [${textColorGreen}Done${defaultColor}]\n"
else
    printf " [${textColorRed}Failed${defaultColor}]"
    printf " Cannot find the git folder${defaultColor}\n"
fi

printf "Remove sub folder: ./${url}"
if [ -d "./$url" ]; then
    rm -rf ./$url
    printf " [${textColorGreen}Done${defaultColor}]\n"
else
    printf " [${textColorRed}Failed${defaultColor}]"
    printf " Cannot find the sub folder${defaultColor}\n"
fi

printf "Remove folder: /var/www/html/${url}"
if [ -d "/var/www/html/$url" ]; then
    sudo rm -rf /var/www/html/$url
    printf " [${textColorGreen}Done${defaultColor}]\n"
else
    printf " [${textColorRed}Failed${defaultColor}]"
    printf " Cannot find the folder${defaultColor}\n"
fi

printf "Search and delete record for server in vhost.f\n"

startMarker='<VirtualHost'
endMarker='</VirtualHost>'
vhostFile='/etc/httpd/conf.d/vhost.conf'

#check vhost.f whether it contains the record for vhost.f
urlLines=( $(grep -n $url$ $vhostFile | cut -f1 -d:) )
urlLinesLength=${#urlLines[@]}

if [ $urlLinesLength == 0 ]; then
  printf " [${textColorRed}Failed${defaultColor}]\n"
  printf "No record for server $url on $vhostFile ${defaultColor}\n"
  #skip if no record

else
    #search startMarkers and endMarkers' line numbers
    startMarkers=( $(grep -Fn $startMarker $vhostFile | cut -f1 -d:) )
    endMarkers=( $(grep -Fn $endMarker $vhostFile | cut -f1 -d:) )

    startMarkerLength=${#startMarkers[@]}
    endMarkerLength=${#endMarkers[@]}

    #search line numbers for lines containing server name
    startUrlLine=${urlLines[0]}
    endUrlLine=${urlLines[$urlLinesLength-1]}

    #find the delete range
    #between start line number and end line number
    for (( i = $startMarkerLength - 1; i >= 0; i-- )); do
        if [ ${startMarkers[$i]} -lt $startUrlLine ]; then
            startRange=${startMarkers[$i]}
            break
        fi
    done

    for (( j = 0; j < $endMarkerLength - 1; i++ )); do
        if [ ${endMarkers[$i]} -gt $endUrlLine ]; then
            endRange=${endMarkers[$i]}
            break
        fi
    done

    delete='d'

    cat $vhostFile | sed "$startRange,$endRange""$delete" > vhost.tmp

    #check vhost.tmp file
    #startMarkers line total numbers
    #should equal to endMarkers line total numbers

    startMarkers=( $(grep -Fn $startMarker $vhostFile | cut -f1 -d:) )
    endMarkers=( $(grep -Fn $endMarker $vhostFile | cut -f1 -d:) )

    startMarkerLength=${#startMarkers[@]}
    endMarkerLength=${#endMarkers[@]}

    if [ $startMarkerLength == $endMarkerLength ]; then
        #backup vhost.f
        dateAndTime=$(TZ=AEST date +"%Y-%m-%d-%H-%M-%S")
        backupFileName="vhost.f_"$dateAndTime
        cat $vhostFile > ./vhostbackup/$backupFileName
        printf "Back up vhost.f: ./vhostbackup/$backupFileName\n"

        #replace vhost.f by vhost.tmp
        sudo chown ec2-user "$vhostFile"
        cat vhost.tmp > $vhostFile
        rm -f vhost.tmp
        sudo chown root "$vhostFile"

        printf "Remove server record from vhost.f file [${textColorGreen}Done${defaultColor}]\n"

    fi
fi

echo  "[---------Completed---------]"
echo  "Reload apache server conf"

sudo /etc/init.d/httpd reload