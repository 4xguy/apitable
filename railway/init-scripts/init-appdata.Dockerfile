FROM apitable/init-appdata:latest

# Environment variables will be injected by Railway
ENV TZ=UTC

# The init script will run automatically
CMD ["./init-appdata.sh"]