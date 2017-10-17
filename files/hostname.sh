hostname centos.local
export HOSTNAME="centos.local"
IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
cat > /etc/hosts < EOF
127.0.0.1 localhost
::1 localhost localhost6
$IP centos.local
