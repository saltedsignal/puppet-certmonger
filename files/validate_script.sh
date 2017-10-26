status=$(ipa-getcert list -f '/tmp/server.crt' | grep 'status' | awk 'BEGIN{fs=":"};{print $2};' | tr -d ' ')
if [ "$status" != "MONITORING" ]
  exit 1
