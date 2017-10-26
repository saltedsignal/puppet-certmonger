status=$(ipa-getcert list -f '/tmp/server.crt' | grep 'status' | awk 'BEGIN{fs=":"};{print $2};' | tr -d ' ')
if [ "$status" == "MONITORING" ];
then
  exit 0
else
  exit 1
fi
