#!/bin/sh

PATH=/sbin:/usr/sbin:/bin:/usr/bin

SSH=22
FTP=20,21
DNS=53
SMTP=25,465,587
POP3=110,995
IMAP=143,993
HTTP=80,443
IDENT=113
NTP=123
MYSQL=3306
NET_BIOS=135,137,138,139,445
DHCP=67,68


initialize()
{
	iptables -F
	iptables -X
	iptables -Z
	iptables -P INPUT   ACCEPT
	iptables -P OUTPUT  ACCEPT
	iptables -P FORWARD ACCEPT
}

finailize()
{
	/etc/init.d/iptables save &&
	/etc/init.d/iptables restart &&
	return 0
	return 1
}

if [ "$1" == "dev" ]
then
	iptables() { echo "iptables $@"; }
	finailize() { echo "finailize"; }
fi

initialize

iptables -P INPUT   DROP
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP


iptables -A INPUT -i lo -j ACCEPT

if [ "$LOCAL_NET" ]
then
	iptables -A INPUT -p tcp -s $LOCAL_NET -j ACCEPT
fi

if [ "${ALLOW_HOSTS}" ]
then
	for allow_host in ${ALLOW_HOSTS[@]}
	do
		iptables -A INPUT -p tcp -s $allow_host -j ACCEPT
	done
fi

if [ "${DENY_HOSTS}" ]
then
	for deny_host in ${DENY_HOSTS[@]}
	do
		iptables -A INPUT -s $deny_host -m limit --limit 1/s -j LOG --log-prefix "deny_host: "
		iptables -A INPUT -s $deny_host -j DROP
	done
fi

iptables -A INPUT  -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -N STEALTH_SCAN
iptables -A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
iptables -A STEALTH_SCAN -j DROP

iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN

iptables -A INPUT -f -j LOG --log-prefix 'fragment_packet:'
iptables -A INPUT -f -j DROP

iptables -N PING_OF_DEATH
iptables -A PING_OF_DEATH -p icmp --icmp-type echo-request \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 10 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_PING_OF_DEATH \
         -j RETURN

iptables -A PING_OF_DEATH -j LOG --log-prefix "ping_of_death_attack: "
iptables -A PING_OF_DEATH -j DROP

iptables -A INPUT -p icmp --icmp-type echo-request -j PING_OF_DEATH

iptables -N SYN_FLOOD
iptables -A SYN_FLOOD -p tcp --syn \
         -m hashlimit \
         --hashlimit 200/s \
         --hashlimit-burst 3 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_SYN_FLOOD \
         -j RETURN


iptables -A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
iptables -A SYN_FLOOD -j DROP

iptables -A INPUT -p tcp --syn -j SYN_FLOOD

iptables -N HTTP_DOS
iptables -A HTTP_DOS -p tcp -m multiport --dports $HTTP \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 100 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_HTTP_DOS \
         -j RETURN


iptables -A HTTP_DOS -j LOG --log-prefix "http_dos_attack: "
iptables -A HTTP_DOS -j DROP

iptables -A INPUT -p tcp -m multiport --dports $HTTP -j HTTP_DOS

iptables -A INPUT -p tcp -m multiport --dports $IDENT -j REJECT --reject-with tcp-reset



iptables -A INPUT -d 192.168.1.255   -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 192.168.1.255   -j DROP
iptables -A INPUT -d 255.255.255.255 -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 255.255.255.255 -j DROP
iptables -A INPUT -d 224.0.0.1       -j LOG --log-prefix "drop_broadcast: "
iptables -A INPUT -d 224.0.0.1       -j DROP


iptables -A INPUT -p icmp -j ACCEPT

iptables -A INPUT -p tcp -m multiport --dports $HTTP -j ACCEPT

iptables -A INPUT -p tcp -m multiport --dports $SSH -j ACCEPT


if [ "$LIMITED_LOCAL_NET" ]
then

	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $SSH -j ACCEPT


	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $FTP -j ACCEPT


	iptables -A INPUT -p tcp -s $LIMITED_LOCAL_NET -m multiport --dports $MYSQL -j ACCEPT
fi


if [ "$ZABBIX_IP" ]
then

	iptables -A INPUT -p tcp -s $ZABBIX_IP --dport 10050 -j ACCEPT
fi

iptables -A INPUT  -j LOG --log-prefix "drop: "
iptables -A INPUT  -j DROP

trap 'finailize && exit 0' 2
echo "In 30 seconds iptables will be automatically reset."
echo "Don't forget to test new SSH connection!"
echo "If there is no problem then press Ctrl-C to finish."
sleep 30
echo "rollback..."
initialize
