date=$(date '+%Y-%m-%d-%H-%M')
fullbackup='/var/mariadb/backup'
incrbackup='/var/mariadb/increm'
archivepth='/var/mariadb/archive'
encryptkey='YOUR PASSWORD'

if [ $1 = 'full' ]; then
    rm -rf $fullbackup
    mariabackup --backup --user=root \
        --target-dir=$fullbackup

    mkdir -p $archivepth
    filename=$date-full.tar.gz.ssl
    sudo tar -czf - $fullbackup | openssl enc \
        -out $archivepth\$filename \
        -e -aes256 \
        -k $encryptkey

elif [ $1 = 'incr' ]; then
    rm -rf $incrbackup
    mariabackup --backup --user=root \
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