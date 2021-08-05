FROM node:16.3-alpine3.13 AS builder

WORKDIR /root

LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2018, 2019: Advantech'

RUN npm install ws
RUN npm -g install http-server
RUN npm -g install http-server-upload

RUN mkdir jsmpeg
WORKDIR /root/jsmpeg
COPY . .
RUN ln -s /root/jsmpeg/tool/ffmpeg /usr/local/bin/ffmpeg
RUN ln -s /root/jsmpeg/tool/jq-linux64 /usr/local/bin/jq
RUN ln -s /root/jsmpeg/tool/curl /usr/local/bin/curl

CMD [ "/root/jsmpeg/start_http_ws.sh"]
