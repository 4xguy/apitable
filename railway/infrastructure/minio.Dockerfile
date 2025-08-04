FROM minio/minio:RELEASE.2023-01-25T00-19-54Z

# Set access keys from environment variables
ENV MINIO_ROOT_USER=${MINIO_ACCESS_KEY:-apitable}
ENV MINIO_ROOT_PASSWORD=${MINIO_SECRET_KEY:-apitable@com}

EXPOSE 9000 9001

CMD ["server", "--console-address", ":9001", "/data"]