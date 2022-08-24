date=$(date '+%Y-%m-%d-%H-%M')
fullbackup='/var/mariadb/backup'
incrbackup='/var/mariadb/increm'
archivepth='/var/mariadb/archive'
encryptkey='YOUR KEY TO ENCRYPT'
dbuser='YOUR DB USERNAME'
dbpass='YOUR DB PASSWORD'

if [ $1 = 'full' ]; then
    rm -rf $fullbackup
    mkdir -p $fullbackup
    mariabackup --backup --user=$dbuser --password=$dbpass \
        --target-dir=$fullbackup

    mkdir -p $archivepth
    filename=$date-full.tar.gz.ssl
    tar -czf - $fullbackup | openssl enc \
        -out $archivepth/$filename \
        -e -aes256 \
        -k $encryptkey

elif [ $1 = 'incr' ]; then
    rm -rf $incrbackup
    mkdir -p $incrbackup
    mariabackup --backup --user=$dbuser --password=$dbpass \
        --target-dir=$incrbackup \
        --incremental-basedir=$fullbackup

        mkdir -p $archivepth
        filename=$date-incr.tar.gz.ssl
        sudo tar - czf - $incrbackup | openssl enc \
        -out $archivepth/$filename \
        -e aes256 \
        -k $encryptkey
fi

rclone sync $archivepth sftp:mariadb

for file in $archivepth/*.ssl; do
    if [[ $file == *-incr* ]] && [[ $file |= *$(date '+%Y-%m-%d')*]]; then
        rm $file
    fi
done
