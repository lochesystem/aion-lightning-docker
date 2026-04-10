FROM eclipse-temurin:8-jdk-jammy

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /opt/aion/game

ENTRYPOINT ["/entrypoint.sh"]
