hostname centos-7.local
export HOSTNAME="centos-7.local"
echo "centos-7.local" | cat > /etc/hostname
IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
cat > /etc/hosts << EOF
127.0.0.1 localhost.localdomain localhost
$IP centos-7.local centos-7
EOF
