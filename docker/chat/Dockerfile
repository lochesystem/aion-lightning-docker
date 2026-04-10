FROM eclipse-temurin:8-jre-jammy

COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /opt/aion/chat

ENTRYPOINT ["/entrypoint.sh"]
