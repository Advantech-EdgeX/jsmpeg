FROM node:16.3-alpine3.13 AS builder
ARG GIT_COMMIT
ENV platform openvino rtsp_ip rtsp_port rtsp_url_path

WORKDIR /root

LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2018, 2019: Advantech'

RUN npm install ws
RUN npm -g install http-server
RUN npm -g install http-server-upload

RUN mkdir jsmpeg
WORKDIR /root/jsmpeg
COPY archive .
RUN echo ${GIT_COMMIT} > version.git
RUN ln -s /root/jsmpeg/tool/ffmpeg /usr/local/bin/ffmpeg
RUN ln -s /root/jsmpeg/tool/jq-linux64 /usr/local/bin/jq
RUN ln -s /root/jsmpeg/tool/curl /usr/local/bin/curl

CMD ["sh", "-c", "/root/jsmpeg/init.sh -p ${platform} --rtsp_ip ${rtsp_ip} --rtsp_port ${rtsp_port} --rtsp_url_path ${rtsp_url_path}" ]
