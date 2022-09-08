#!/bin/bash
SERVICE_NAME=httpbin
HOST=localhost
PORT=8001
TOKEN=kong

# Create a service
curl -H "kong-admin-token: $TOKEN" -i -X POST https://$HOST:$PORT/services \
  --data name=$SERVICE_NAME \
  --data url='http://httpbin.org/anything' -k

# Create a ton of routes
for i in {1..100}
do
  curl -s http://$HOST:$PORT/services/$SERVICE_NAME/routes -H "kong-admin-token: $TOKEN" --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode 'name=path'${i} --data-urlencode 'paths=/path'${i} --data-urlencode 'hosts=hosts'${i} --insecure -o /dev/null
done
