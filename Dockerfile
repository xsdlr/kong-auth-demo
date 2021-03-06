FROM kong:latest
MAINTAINER Habor Huang, haborhuang@whispir.cc

ENV KONG_DATABASE postgres
ENV KONG_LUA_PACKAGE_PATH /kong-plugins/?.lua;;
ENV KONG_CUSTOM_PLUGINS custom-token-auth

ADD kong/ /kong-plugins/kong/
ADD run.sh /

RUN chmod +x run.sh

# Clear entrypoint of base image
ENTRYPOINT []
CMD ["/run.sh"]

EXPOSE 8000 8443 8001 7946