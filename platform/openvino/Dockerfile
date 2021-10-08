FROM node:16.3-alpine3.13 AS builder
ARG GIT_COMMIT

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
RUN rm -f index.html
RUN ln -s /root/jsmpeg/platform/openvino/index.html index.html
RUN rm -f env.json
RUN ln -s /root/jsmpeg/platform/openvino/env.json env.json

CMD [ "/root/jsmpeg/init.sh"]
