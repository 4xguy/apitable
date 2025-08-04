FROM rabbitmq:3.11.9-management

# Set default user and password from environment variables
ENV RABBITMQ_DEFAULT_USER=${RABBITMQ_USERNAME:-apitable}
ENV RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD:-apitable@com}

EXPOSE 5672 15672