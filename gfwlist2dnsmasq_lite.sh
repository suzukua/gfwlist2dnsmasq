#!/bin/sh
#
# Update Time 2021.11.29 suzukua
# rm ipset too support clash dns
#
# Created Time: 2016.12.06 zhangzf
# Translate the gfwlist in base64 to dnsmasq rules with ipset
#

MYDNSIP=${2:-127.0.0.1}
MYDNSPORT=${3:-23453}
IPSETNAME=${4:-dnsmasq_gfw}
IPSETNAME6=${5:-dnsmasq_gfw6}

GFWURL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
#GFWURL="https://raw.githubusercontent.com/hezhijie0327/GFWList2AGH/main/gfwlist2domain/blacklist_lite.txt"
#GFWURL="https://raw.githubusercontent.com/hezhijie0327/GFWList2AGH/main/gfwlist2domain/blacklist_full.txt"

GFW_TMP="/tmp/gfw.txt"
GFWLIST_TMP="/home/runner/work/publish/gfw_lite.conf"
# DNSMASQ_GFW="/jffs/configs/dnsmasq.d/gfw.conf"

# curl & base64 command path
CURL=$(which curl)
CURLOPT="-s -k -o $GFW_TMP"

c_conf() {
	echo "# Updated on:$(date '+%F %T')" > $GFWLIST_TMP
	
	while read LINE; do 
		if [ "$(filter "$LINE")" -eq "0" ]; then
      			printf 'server=/.%s/%s#%s\n' $LINE $MYDNSIP $MYDNSPORT >> $GFWLIST_TMP
 			printf 'ipset=/.%s/%s,%s\n' $LINE $IPSETNAME $IPSETNAME6 >> $GFWLIST_TMP
  		fi
	done
}

#排除某些规则
filter(){
	rule="$1"
	echo "$(echo "$rule" | grep -Ec "asuscomm\.com|asus\.com|dns\.google|m-team\.cc|eu\.org")"
}

addDomain(){
	echo "fast.com\nsydney.bing.com\nrclone.org\nspeed.cloudflare.com\ndocker.com\ndocker.io\nomdbapi.com\nmetacubex.one\nooklaserver.net\ndash.cloudflare.com\nip.sb" >> $GFW_TMP
}

gen(){
	echo "开始下载GFW规则，过程可能较慢，请耐心等待"
	# download
        # 检查文件是否存在，如果存在则删除
        if [ -f "$GFW_TMP" ]; then
          rm "$GFW_TMP"
        fi
          # 下载每个URL的内容并追加到文件
        curl "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt" >> "$GFW_TMP"
        curl "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/QuantumultX/Copilot/Copilot.list" >> "$GFW_TMP"
	curl "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/QuantumultX/TikTok/TikTok.list" >> "$GFW_TMP"
        echo "下载完成，所有内容已合并到 $output_file"
	addDomain
	# parse gfwlist	
	cat $GFW_TMP \
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
                        -e 's/[^,]*,\([^,]*\).*/\1/' \
		| grep -e '\.' \
		| sort -u \
                | uniq \
		| c_conf
		
	rows=$(grep -c "$IPSETNAME" $GFWLIST_TMP)
	sed -i "1i# Rows:${rows}" $GFWLIST_TMP
	rm $GFW_TMP -f
	echo "更新GFW规则完毕"
}

#删除dns
del(){
	#rm -rf $DNSMASQ_GFW
	rm -rf $GFWLIST_TMP;
}

pwd
echo #################
ls -lah
command=$1
case $command in
	(gen)
		gen
		;;
	(del)
		del
		;;
	(*)
		echo "暂不支持该命令${command}，只支持gen、del"
		;;
esac
