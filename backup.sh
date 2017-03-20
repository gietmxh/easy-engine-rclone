SERVER_NAME=vetinh1

TIMESTAMP=$(date +"%F")
BACKUP_DIR="/root/backup/$TIMESTAMP"
MYSQL_USER="root"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="EWBQalYS"
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0

mkdir -p "$BACKUP_DIR/mysql"

echo "Starting Backup Database";
databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`

for db in $databases; do
	$MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/mysql/$db.gz"
done
echo "Finished";
echo '';

echo "Starting Backup Website";
# Loop through /home directory
for D in /var/www/*; do
	if [ -d "${D}" ]; then #If a directory
		domain=${D##*/} # Domain name
		echo "- "$domain;
		zip -r $BACKUP_DIR/$domain.zip /var/www/$domain/htdocs/ -q -x /var/www/$domain/htdocs/wp-content/cache/**\* #Exclude cache
	fi
done
echo "Finished";
echo '';


size=$(du -sh $BACKUP_DIR | awk '{ print $1}')

echo "Starting Uploading Backup";
/usr/sbin/rclone move $BACKUP_DIR "remote:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
# Clean up
rm -rf $BACKUP_DIR
/usr/sbin/rclone -q --min-age 2w delete "remote:$SERVER_NAME" #Remove all backups older than 2 week
/usr/sbin/rclone -q --min-age 2w rmdirs "remote:$SERVER_NAME" #Remove all empty folders older than 2 week
echo "Finished";
echo '';

duration=$SECONDS
echo "Total $size, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
