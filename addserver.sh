
# ------------------------ variables -------------------------------------------------
postReceiveFile="post-receive"
vhostFile="/etc/httpd/conf.d/vhost.conf"

# ------------------------ get url ---------------------------------------------------
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

#------------------------------ get subfolder name ---------------------------------------
read -p "Use subfolder for web root? (y/n) " subfolder

if [ "$subfolder" == "y" ] || [ "$subfolder" == "Y" ]; then
  subfolder="bin"
  read -p "enter subfolder name, default is 'bin': " subfolder
  read -p "re-enter subfolder name, default is 'bin': " subfolderCheck

  if [ "$subfolder" != "$subfolderCheck" ]; then
    echo "sub folder name doesn't match"
    exit 0
  fi
  if [ "$subfolder" == "" ] && [ "$subfolderCheck" == "" ]; then
    subfolder="bin"
  fi
  echo "subfolder name: $subfolder"

else
  subfolder=0
fi

#------------------------ create git clone folder --------------------------------------
echo "Create git clone folder: " $url
mkdir "$url"
test -d "./$url"

#---------------------- create git folder on home/user ----------------------------------
gitFolderName="$url.git"

echo "Create git folder: " $gitFolderName
mkdir "$gitFolderName"
test -d "./$gitFolderName"

cd "./$gitFolderName"
git init --bare

test -d "./hooks"
cd "./hooks/"




######################### create and add commands to post-receive file ######################
echo "Create post-receive inside hooks/"

#---------------------------- set copy from url and to url -------------------------------------
if [ "$subfolder" != 0 ]; then
	copyFrom="/home/ec2-user/$url/$subfolder/"
else
	copyFrom="/home/ec2-user/$url/"
fi

copyTo="/var/www/html/$url/\$branch"

#----------------------- check or create branch folders -------------------------------------
echo "#!/bin/sh" > $postReceiveFile



echo "while read oldrev newrev refname" >> $postReceiveFile

echo "do" >> $postReceiveFile
echo "    branch=\$(git rev-parse --symbolic --abbrev-ref \$refname)" >> $postReceiveFile
echo "    if [ -d \"/var/www/html/$url/\$branch\" ]; then" >> $postReceiveFile
echo "      echo \"Check branch folder: \$branch, it exists\"" >> $postReceiveFile
echo "    else" >> $postReceiveFile
echo "      mkdir /var/www/html/$url/\$branch" >> $postReceiveFile
echo "      echo \"Create branch folder: /var/www/html/$url/\"\$branch" >> $postReceiveFile
echo "    fi" >> $postReceiveFile
echo "    " >> $postReceiveFile

#------------------------ set git work tree -------------------------------------------------
echo "    echo \"Update pushed to branch \$branch\"" >> $postReceiveFile
echo "    GIT_WORK_TREE=/home/ec2-user/$url" >> $postReceiveFile
echo "    export GIT_WORK_TREE" >> $postReceiveFile
echo "    git checkout -f \$branch" >> $postReceiveFile

#-------------------------- check folder before copying --------------------------------------
echo "    if [ -d \"$copyFrom\" ]; then" >> $postReceiveFile
echo "      cp -rf $copyFrom/* $copyTo" >> $postReceiveFile
echo "    else" >> $postReceiveFile
echo "      echo \"copy from directory: $copyFrom is not existed, skip copying\"" >> $postReceiveFile
echo "    fi" >> $postReceiveFile

echo "done" >> $postReceiveFile



chmod +x "./$postReceiveFile"

#------------------------------------ create server's folder ----------------------------------
echo "Create folder $url in /var/www/html/"
sudo mkdir "/var/www/html/$url"
sudo chown ec2-user "/var/www/html/$url"

echo "Check document root: /var/www/html/$url"
test -d "/var/www/html/$url"

#------------------------------------ register server on vhost.conf ----------------------------
echo "Add new server to vhost.conf"
sudo chown ec2-user $vhostFile

echo "" >> $vhostFile
echo "<VirtualHost *>" >> $vhostFile
echo "Servername $url" >> $vhostFile
echo "DocumentRoot /var/www/html/$url" >> $vhostFile
echo "</VirtualHost>" >> $vhostFile

sudo chown root $vhostFile

#=------------------------------------ restart Apache ---------------------------------------------
echo "Complete"
echo "Reload apache server conf"

sudo /etc/init.d/httpd reload
