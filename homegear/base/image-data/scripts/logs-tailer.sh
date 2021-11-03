#!/bin/bash

tail -f /share/homegear/log/homegear-webssh.log &
tail -f /share/homegear/log/homegear-flows.log &
tail -f /share/homegear/log/homegear-scriptengine.log &
tail -f /share/homegear/log/homegear-management.log &
tail -f /share/homegear/log/homegear-influxdb.log &
tail -f /share/homegear/log/homegear.log &
child=$!

wait "$child"
