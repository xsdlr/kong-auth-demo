#!/bin/bash
set -e

kong start --conf /conf/kong.conf && tail -f /usr/local/kong/logs/error.log