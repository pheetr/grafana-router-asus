#!/bin/sh

[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)   # "nvram get odmpid" doesn't return value on RT-AX86U 
readonly SCRIPT_NAME="wifi_client_stats"
readonly DATA_TEMP_FILE=""
readonly DB_URL=""
readonly DB_ORG=""
readonly DB_BUCKET=""
readonly DB_TOKEN=""


wifi_client_stats()
{

  wifiInterface=$(nvram get wl_ifnames)
  #echo $wifiInterface   #debug

  for wlan in $wifiInterface; do
    clients=$(wl -i $wlan assoclist | awk '{print $2}')   #getting wireless client MAC addresses
    #printf "$wlan \n"   #debug

        for client in $clients; do
            #ip=$(grep -i $client /proc/net/arp | awk '{print $1}') #arp provided two IPs for a MAC address, even though VM on that system had unique MAC setting -> alternative source preferred
            ip=$(grep -i $client /var/lib/misc/dnsmasq.leases | awk '{print $3}') #grabbing IP from current DHCP lease table
            host=$(grep -i $client /var/lib/misc/dnsmasq.leases | awk '{print $4}') #grabbing hostname from current DHCP lease table

            if [ -z "$ip" ]; then
                ip=$clients
            fi

            if [ -z "$host" ]; then
                host=$clients
            fi

            #printf "$wlan \t "$client" \t "$ip" \t "$host" \\n"   #debug

            #wl -i $wlan sta_info $client   #debug all wifi infos
			
			#unit for rssi and noise metrics: dB
            rssi_antenna1=$(wl -i $wlan sta_info $client | awk '/per antenna rssi of last rx data frame/ {print $9}')
            rssi_antenna2=$(wl -i $wlan sta_info $client | awk '/per antenna rssi of last rx data frame/ {print $10}')
            rssi_antenna3=$(wl -i $wlan sta_info $client | awk '/per antenna rssi of last rx data frame/ {print $11}')
            rssi_antenna4=$(wl -i $wlan sta_info $client | awk '/per antenna rssi of last rx data frame/ {print $12}')

            rssi_antenna1_avg=$(wl -i $wlan sta_info $client | awk '/per antenna average rssi of rx data frames/ {print $9}')
            rssi_antenna2_avg=$(wl -i $wlan sta_info $client | awk '/per antenna average rssi of rx data frames/ {print $10}')
            rssi_antenna3_avg=$(wl -i $wlan sta_info $client | awk '/per antenna average rssi of rx data frames/ {print $11}')
            rssi_antenna4_avg=$(wl -i $wlan sta_info $client | awk '/per antenna average rssi of rx data frames/ {print $12}')

            noise_antenna1=$(wl -i $wlan sta_info $client | awk '/per antenna noise floor/ {print $5}')
            noise_antenna2=$(wl -i $wlan sta_info $client | awk '/per antenna noise floor/ {print $6}')
            noise_antenna3=$(wl -i $wlan sta_info $client | awk '/per antenna noise floor/ {print $7}')
            noise_antenna4=$(wl -i $wlan sta_info $client | awk '/per antenna noise floor/ {print $8}')

            #unit for rx and tx rate metrics: kbps
            rx_rate_pkt=$(wl -i $wlan sta_info $client | awk '/rate of last rx pkt:/ {print $6}')
            tx1_rate_pkt=$(wl -i $wlan sta_info $client | awk '/rate of last tx pkt:/ {print $6}')
            tx2_rate_pkt=$(wl -i $wlan sta_info $client | awk '/rate of last tx pkt:/ {print $9}')

            #total data transferred, in bytes
            rx_total_bytes=$(wl -i $wlan sta_info $client | awk '/rx data bytes/ {print $4}')
            tx_total_bytes=$(wl -i $wlan sta_info $client | awk '/tx total bytes/ {print $4}')

            #link bandwidth unit: MHz
            link_bandwidth=$(wl -i $wlan sta_info $client | awk '/link bandwidth/ {print $4}')
            tx_failures=$(wl -i $wlan sta_info $client | awk '/tx failures:/ {print $3}')
            rx_decrypt_failures=$(wl -i $wlan sta_info $client | awk '/rx decrypt failures:/ {print $4}')

            #idle and online unit: seconds
            idle=$(wl -i $wlan sta_info $client | awk '/idle/ {print $2}')
            online=$(wl -i $wlan sta_info $client | awk '/in network/ {print $3}')
            #rssi unit: dB
            rssi=$(wl -i $wlan rssi $client)

            if [ "$wlan" = eth6 ]; then 
              chann="2.4GHz"; else 
              chann="5GHz"; 
            fi

            tags="host=${ROUTER_MODEL},wifi=$wlan,client=$client,ip=$ip,hostname=$host,wifiBand=$chann"
            fields="tx_total_bytes=$tx_total_bytes,rx_total_bytes=$rx_total_bytes,tx2_rate_pkt=$tx2_rate_pkt,tx1_rate_pkt=$tx1_rate_pkt,rx_rate_pkt=$rx_rate_pkt,rssi=$rssi,online=$online,idle=$idle,rssi_antenna1=$rssi_antenna1,rssi_antenna2=$rssi_antenna2,rssi_antenna3=$rssi_antenna3,rssi_antenna4=$rssi_antenna4,rssi_antenna1_avg=$rssi_antenna1_avg,rssi_antenna2_avg=$rssi_antenna2_avg,rssi_antenna3_avg=$rssi_antenna3_avg,rssi_antenna4_avg=$rssi_antenna4_avg,noise_antenna1=$noise_antenna1,noise_antenna2=$noise_antenna2,noise_antenna3=$noise_antenna3,noise_antenna4=$noise_antenna4,link_bandwidth=$link_bandwidth,tx_failures=$tx_failures,rx_decrypt_failures=$rx_decrypt_failures"
            #echo $fields   #debug

            curdate=`date +%s` #date in seconds
            #curdate_="${curdate}000000000" #in case date needed in ns (InfluxDB 1.x)
            measurement="router_asus_wificlients"
            data="$measurement,$tags $fields $curdate"

            #echo $data >> $DATA_TEMP_FILE   #debug
            #echo $data   #debug
            #curl -is -XPOST "https://${DB_URL}/write?db=${DB_NAME}&u=${USER}&p=${PASS}" --data-binary "$data"  > /dev/null   #InfluxDB 1.x
            curl --insecure --request POST "https://${DB_URL}:8086/api/v2/write?org=${DB_ORG}&bucket=${DB_BUCKET}&precision=s" --header "Authorization: Token ${DB_TOKEN}" --data-raw "$data" #> /dev/null
        done;
  done;
}

#rm -f $DATA_TEMP_FILE
wifi_client_stats
