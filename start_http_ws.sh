#!/bin/sh

DIR_JSMPEG=/root/jsmpeg
LOG=/var/tmp/jsmpeg_rc.log

display_help() {
	echo "Usage: $0 rtsp_ip rtsp_port ws_relay_port_src ws_relay_port_dst" >&2
	exit 1
}

run_jobs() {
	echo nohup http-server ${DIR_JSMPEG} -p ${http_server_port} --cgi >> ${LOG}
	nohup http-server ${DIR_JSMPEG} -p ${http_server_port} --cgi >/dev/null 2>&1 &
	echo nohup node ${DIR_JSMPEG}/websocket-relay.js supersecret ${ws_relay_port_src} ${ws_relay_port_dst} >> ${LOG}
	nohup node ${DIR_JSMPEG}/websocket-relay.js supersecret ${ws_relay_port_src} ${ws_relay_port_dst} >/dev/null 2>&1 &
	echo PORT=${http_upload_port} UPLOAD_DIR=${DIR_JSMPEG} UPLOAD_TMP_DIR=/tmp/ http-server-upload >> ${LOG}
	PORT=${http_upload_port} UPLOAD_DIR=${DIR_JSMPEG} UPLOAD_TMP_DIR=/tmp/ http-server-upload >/dev/null 2>&1 &
	while true
	do
		curl -v -X DESCRIBE -m 3 $URL_RTSP > /dev/null 2>&1
		if [ "$?" -eq 0 ]; then
			# echo ffmpeg -nostdin -rtsp_transport tcp -i $URL_RTSP -f mpegts -codec:v mpeg1video  "http://${rtsp_ip}:${ws_relay_port_src}/supersecret"
			ffmpeg -nostdin -rtsp_transport tcp -i $URL_RTSP -r 30 -q 0 -f mpegts -codec:v mpeg1video  "http://${rtsp_ip}:${ws_relay_port_src}/supersecret" >/dev/null 2>&1
			sleep 1
		else
			sleep 3
		fi
	done
}

case "$1" in
	-h | --help)
		display_help
		exit 0
		;;
esac

cat /dev/null > ${LOG}
if [ "$#" -eq 4 ]; then
	rtsp_ip=$1
	rtsp_port=$2
	ws_relay_port_src=$3
	ws_relay_port_dst=$4
else
	while [ ! -f "${DIR_JSMPEG}/env.json" ]
	do
		sleep 3
	done
	echo "Use ${DIR_JSMPEG}/env.json" >> ${LOG}
	for s in $(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ${DIR_JSMPEG}/env.json); do
		echo $s >> ${LOG}
		export $s
	done
fi

if [ -z "${rtsp_ip}" ]; then
	DEFAULT_ROUTE=$(ip route show default | awk '/default/ {print $3}')
	echo DEFAULT_ROUTE=${DEFAULT_ROUTE} >> ${LOG}
	if [ ! -z "${DEFAULT_ROUTE}" ]; then
		rtsp_ip=${DEFAULT_ROUTE}
	else
		rtsp_ip="127.0.0.1"
	fi
fi

URL_RTSP="rtsp://${rtsp_ip}:${rtsp_port}/${rtsp_url_path}"
echo ${URL_RTSP} >> ${LOG}
killall node ffmpeg http-server http-server-upload >/dev/null 2>&1

run_jobs