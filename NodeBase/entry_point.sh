#!/bin/bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

if [ ! -e /opt/selenium/config.json ]; then
  echo No Selenium Node configuration file, the node-base image is not intended to be run directly. 1>&2
  exit 1
fi

if [ -z "$HUB_PORT_4444_TCP_ADDR" ]; then
  echo Not linked with a running Hub container 1>&2
  exit 1
fi

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

REMOTE_HOST_PARAM=""
if [ ! -z "$REMOTE_HOST" ]; then
  echo "REMOTE_HOST variable is set, appending -remoteHost"
  REMOTE_HOST_PARAM="-remoteHost $REMOTE_HOST"
fi

# TODO: Look into http://www.seleniumhq.org/docs/05_selenium_rc.jsp#browser-side-logs

if [ ! -d "/tmp/fbdir" ];
then
	mkdir /tmp/fbdir
fi

xvfb-run --server-args="$DISPLAY -screen 0 $GEOMETRY -fbdir /tmp/fbdir -ac +extension RANDR" \
  java -Dvideo.framerate=4 -Dvideo.xvfbscreen=/tmp/fbdir -cp /opt/selenium/selenium-video-node.jar:/opt/selenium/selenium-server-standalone.jar \
    org.openqa.grid.selenium.GridLauncher \
    -servlets com.aimmac23.node.servlet.VideoRecordingControlServlet -proxy com.aimmac23.hub.proxy.VideoProxy \
    -role node \
    -hub http://$HUB_PORT_4444_TCP_ADDR:$HUB_PORT_4444_TCP_PORT/grid/register \
    ${REMOTE_HOST_PARAM} \
    -nodeConfig /opt/selenium/config.json &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
wait $NODE_PID
