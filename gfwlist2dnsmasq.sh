#!/bin/sh
#
# Update Time 2021.11.29 zhudan
# rm ipset too support clash dns
#
# Created Time: 2016.12.06 zhangzf
# Translate the gfwlist in base64 to dnsmasq rules with ipset
#

MYDNSIP='127.0.0.1'
MYDNSPORT=$3
# IPSETNAME='gfwlist'

GFWURL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
GFWLIST_TMP_BASE64="/tmp/gfwlist.txt.base64"
GFWLIST_TMP="/tmp/gfw.conf"
DNSMASQ_GFW="/jffs/configs/dnsmasq.d/gfw.conf"

# curl & base64 command path
CURL=$(which curl)
CURLOPT="-s -k -o $GFWLIST_TMP_BASE64"
BASE64=$(which base64)

c_conf() {
	echo "# Updated on $(date '+%F %T')" >$GFWLIST_TMP
	
	cat <<-EOF >>$GFWLIST_TMP
	$(while read LINE; do \
		printf 'server=/.%s/%s#%s\n' $LINE $MYDNSIP $MYDNSPORT; \
# 		printf 'ipset=/.%s/%s\n' $LINE $IPSETNAME; \
	done)
EOF
}

gen(){
	echo "开始刷新gfw规则，过程可能较慢，请耐心等待"
	# download
	if [ ! -f $GFWLIST_TMP_BASE64 ]; then
		$CURL $CURLOPT $GFWURL
		[ "$?" -eq 0 ] || {
			echo "Gfwlist download failed."
			exit 1
		}
	fi
	# parse gfwlist	
	$BASE64 -d $GFWLIST_TMP_BASE64 \
		| grep -v \
			-e '^\s*$' \
			-e '^[\[!@@]' \
			-e '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]' \
		| sed \
			-e s'/^[@|]*//'g \
			-e s'/^http[s]*:\/\///'g \
			-e s'/[\/\%].*$//'g \
			-e s'/[^a-z]\+$//'g \
			-e s'/.*\*[^\.]*//'g \
			-e s'/^\.//'g 2>/dev/null \
		| grep -e '\.' \
		| sort -u \
		| c_conf

	rm $GFWLIST_TMP_BASE64 -f
	echo "更新GFW规则完毕"
	ln -snf $GFWLIST_TMP $DNSMASQ_GFW
	echo "GFW规则已建立到dnsmasq配置文件夹的软链，等待重启dnsmasq即可使用dnsmasq转发GFW域名到上游DNS"
}

#删除dns
del(){
	rm -rf $DNSMASQ_GFW
	rm -rf $GFWLIST_TMP;
}

case $ACTION in
	gen)
		gen
		;;
	del)
		del
		;;
	*)
		echo "暂不支持该命令"
		;;
esac
