#!/bin/sh
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


#If subfolder != 0 create folder for subfolder firstly
if [ "$subfolder" != 0 ]; then
			 echo "Create git clone folder: " $url
			 mkdir "$url"
			 test -d "./$url"
fi


gitFolderName="$url.git"

echo "Create git folder: " $gitFolderName
mkdir "$gitFolderName"
test -d "./$gitFolderName"

cd "./$gitFolderName"
git init --bare

test -d "./hooks"
cd "./hooks/"

echo "Create post-receive inside hooks/"



if [ "$subfolder" != 0 ]; then
		echo "#!/bin/sh" > "post-recieve"
		echo "while read oldrev newrev refname" >> "post-receive"
		echo "do" >> "post-receive"
		echo "    branch=$(git rev-parse --symbolic --abbrev-ref $refname)" >> "post-receive"
		echo "    echo Update pushed to branch $branch" >> "post-receive"
		echo "    GIT_WORK_TREE=/home/ec2-user/$url" >> "post-receive"
		echo "    export GIT_WORK_TREE" >> "post-receive"
		echo "    git checkout -f $branch" >> "post-receive"
		echo "    cp -r /home/ec2-user/$url/$subfolder/* /var/www/html/$url/$branch" >> "post-receive"
		echo "done" >> "post-receive"
else
		echo "#!/bin/sh" > "post-recieve"
		echo "while read oldrev newrev refname" >> "post-receive"
		echo "do" >> "post-receive"
		echo "    branch=$(git rev-parse --symbolic --abbrev-ref $refname)" >> "post-receive"
		echo "    echo Update pushed to branch $branch" >> "post-receive"
		echo "    GIT_WORK_TREE=/home/ec2-user/$url" >> "post-receive"
		echo "    export GIT_WORK_TREE" >> "post-receive"
		echo "    git checkout -f $branch" >> "post-receive"
		echo "    cp -r /home/ec2-user/$url/* /var/www/html/$url/$branch" >> "post-receive"
		echo "done" >> "post-receive"

fi

chmod +x "./post-receive"

echo "Create folder $url in /var/www/html/"
sudo mkdir "/var/www/html/$url"
sudo chown ec2-user "/var/www/html/$url"

echo "Check document root: /var/www/html/$url"
test -d "/var/www/html/$url"

echo "Add new server to vhost.conf"
#change vhost.conf owner to ec2-user
sudo chown ec2-user "/etc/httpd/conf.d/vhost.conf"

echo "" >> "/etc/httpd/conf.d/vhost.conf"
echo "<VirtualHost *>" >> "/etc/httpd/conf.d/vhost.conf"
echo "Servername $url" >> "/etc/httpd/conf.d/vhost.conf"
echo "DocumentRoot /var/www/html/$url" >> "/etc/httpd/conf.d/vhost.conf"
echo "</VirtualHost>" >> "/etc/httpd/conf.d/vhost.conf"

sudo chown root "/etc/httpd/conf.d/vhost.conf"

echo "Complete"
echo "Reload apache server conf"

sudo /etc/init.d/httpd reload
