FROM debian:buster
RUN apt-get update 
RUN apt-get install -y git
RUN apt-get install -y erlang
RUN apt-get install -y libsnappy-dev
RUN apt-get install -y build-essential
RUN apt-get install -y libssl-dev
WORKDIR /
ADD https://api.github.com/repos/joskwanten/vernemq/git/refs/heads/feature/set-mqtt-connect-timeout version.json
RUN git clone -b feature/set-mqtt-connect-timeout https://github.com/joskwanten/vernemq.git
# RUN git clone https://github.com/joskwanten/vernemq.git
WORKDIR /vernemq
RUN make rel
ENTRYPOINT ["/bin/bash"]


FROM debian:buster-slim

RUN apt-get update && \
    apt-get -y install bash procps openssl iproute2 curl jq libsnappy-dev && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

WORKDIR /vernemq

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    PATH="/vernemq/bin:$PATH" \
    VERNEMQ_VERSION="1.10.2"

COPY --chown=10000:10000 bin/vernemq.sh /usr/sbin/start_vernemq
COPY --chown=10000:10000 files/vm.args /vernemq/etc/vm.args

COPY --from=0 /vernemq/_build/default/rel/vernemq .

RUN chown -R 10000:10000 /vernemq && \
    ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109


VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

HEALTHCHECK CMD vernemq ping | grep -q pong

USER vernemq

CMD ["start_vernemq"]
