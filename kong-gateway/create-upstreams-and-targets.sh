#!/bin/bash
PROTO=http
HOST=localhost
PORT=38001
TOKEN=admin
WORKSPACE=default


for i in {1..50}
do
# Create an upstream and store the resulting ID
  ID=$(curl -H 'kong-admin-token: admin' $PROTO://$HOST:$PORT/$WORKSPACE/upstreams --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'name=upstream'${i} --data-urlencode 'algorithm=round-robin'  --insecure -s | jq .id -r)

# Create the targets
curl -H 'kong-admin-token: admin'  $PROTO://$HOST:$PORT/$WORKSPACE/upstreams/$ID/targets  --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode  'upstream='${ID} --data-urlencode target=httpbin.org:80

# Get the upstream name
upstream_name=$(curl -H "kong-admin-token:admin" $PROTO://$HOST:$PORT/$WORKSPACE/upstreams -s | jq .data[].name -r)

# Create a service and store the resulting ID
SERVICE_ID=$(curl -H 'kong-admin-token: admin' $PROTO://$HOST:$PORT/$WORKSPACE/services --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'name=service'${i} --data-urlencode url=http://$upstream_name  --insecure -s | jq .id -r)

# Create the routes
  curl -s http://$HOST:$PORT/services/$SERVICE_ID/routes -H "kong-admin-token: $TOKEN" --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode 'name=path'${i} --data-urlencode 'paths=/path'${i} --insecure -o /dev/null
done