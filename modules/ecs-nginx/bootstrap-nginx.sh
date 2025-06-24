#!/bin/sh
set -e

# Download nginx.conf from S3 with retry logic (up to 5 attempts)
MAX_RETRIES=5
for i in $(seq 1 $MAX_RETRIES); do
  aws s3 cp "s3://$NGINX_CONF_BUCKET/$NGINX_CONF_KEY" /etc/nginx/nginx.conf && break
  echo "Attempt $i to download nginx.conf failed. Retrying in 2 seconds..."
  sleep 2
done

# Print the downloaded nginx.conf for debugging
echo "--- /etc/nginx/nginx.conf content ---"
cat /etc/nginx/nginx.conf
echo "--- end nginx.conf ---"

# Validate nginx config before starting
if ! nginx -t -c /etc/nginx/nginx.conf; then
  echo "nginx config test failed! Exiting."
  exit 1
fi

# Start nginx
exec nginx -g 'daemon off;'
