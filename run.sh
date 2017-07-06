#!/bin/bash
set -e

kong start --nginx-conf conf/custom_nginx.template && tail -f /usr/local/kong/logs/error.log