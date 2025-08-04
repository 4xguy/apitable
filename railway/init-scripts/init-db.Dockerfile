FROM apitable/init-db:latest

# Environment variables will be injected by Railway
ENV TZ=UTC
ENV ACTION=update

# The init-db script will run automatically
CMD ["./init-db.sh"]