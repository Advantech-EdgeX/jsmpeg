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
			if [ "$PLATFORM" = "nvds" ]; then
				ffmpeg -nostdin -i $URL_RTSP -f mpegts -codec:v mpeg1video "http://${HOST_IP}:${ws_relay_port_src}/supersecret" >/dev/null 2>&1
			else
				ffmpeg -nostdin -rtsp_transport tcp -i $URL_RTSP -r 30 -q 0 -f mpegts -codec:v mpeg1video "http://${HOST_IP}:${ws_relay_port_src}/supersecret" >/dev/null 2>&1
			fi
			sleep 1
		else
			sleep 3
		fi
	done
}

cat /dev/null > ${LOG}
echo "arg number $#" >> ${LOG}
echo "args $@" >> ${LOG}

case "$1" in
	-h | --help)
		display_help
		exit 0
		;;
	-p | --platform)
		if [ -n "$2" ]; then
			echo "handle arg -p value $2" >> ${LOG}
			PLATFORM=${2}
			rm -f /root/jsmpeg/index.html
			ln -s /root/jsmpeg/platform/${2}/index.html /root/jsmpeg/index.html
			rm -f /root/jsmpeg/env.json
			ln -s /root/jsmpeg/platform/${2}/env.json /root/jsmpeg/env.json
			shift
		fi
		shift
		;;
esac

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

DEFAULT_ROUTE=$(ip route show default | awk '/default/ {print $3}')
echo DEFAULT_ROUTE=${DEFAULT_ROUTE} >> ${LOG}
if [ ! -z "${DEFAULT_ROUTE}" ]; then
	HOST_IP=${DEFAULT_ROUTE}
else
	HOST_IP="127.0.0.1"
fi

if [ -z "${rtsp_ip}" ]; then
	rtsp_ip=${HOST_IP}
fi

URL_RTSP="rtsp://${rtsp_ip}:${rtsp_port}/${rtsp_url_path}"
echo ${URL_RTSP} >> ${LOG}
killall node ffmpeg http-server http-server-upload >/dev/null 2>&1

run_jobs
