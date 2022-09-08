#!/bin/bash
#https://www.keycloak.org/docs-api/15.0/rest-api/#_clients_resource

set -e
# trap 'error' ERR

KEYCLOAK_HOST=localhost
KEYCLOAK_PORT=9977
KEYCLOAK_REALM=master
KEYCLOAK_CLIENT_ID=kong-demo
KEYCLOAK_CLIENT_SECRET=kong
KEYCLOAK_USERNAME=kong
KEYCLOAK_PASSWORD=kongstrong
KEYCLOAK_USER_EMAIL=kingkong@konghq.com
KEYCLOAK_ADMIN_PASSWORD=password
KEYCLOAK_ADMIN_USERNAME=admin



get_admin_token(){
     echo "Token Request"
     echo $KEYCLOAK_HOST
     TOKEN=$(curl -s --data "username=$KEYCLOAK_ADMIN_USERNAME&password=$KEYCLOAK_ADMIN_PASSWORD&grant_type=password&client_id=admin-cli" http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/realms/$KEYCLOAK_REALM/protocol/openid-connect/token | jq -r .access_token)     
     if [ -z "$TOKEN" ]
     then
       return 1
     else 
       echo $TOKEN
     fi     
}

create_user(){
     echo -e "\nCreating user"
     curl -s http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/admin/realms/$KEYCLOAK_REALM/users \
          -H "Content-Type: application/json" \
          -H "Authorization: bearer $TOKEN" \
          --data '{"firstName":"King","lastName":"Kong", "email":"'"$KEYCLOAK_USER_EMAIL"'", "enabled":"true", "username":"'"$KEYCLOAK_USERNAME"'","credentials":[{"type":"password","value":"'"$KEYCLOAK_PASSWORD"'","temporary":false}]}'
}


create_client(){
     echo -e "\n\nCreating Client"
     curl -s http://$KEYCLOAK_HOST:$KEYCLOAK_PORT/auth/admin/realms/$KEYCLOAK_REALM/clients \
          -H "Content-Type: application/json" \
          -H "Authorization: bearer $TOKEN" \
          --data '{"secret":"'"$KEYCLOAK_CLIENT_SECRET"'", "name":"kong-demo", "clientId":"'"$KEYCLOAK_CLIENT_ID"'","serviceAccountsEnabled":"true","directAccessGrantsEnabled":"true","redirectUris":["http://localhost:8000/*"]}'
     echo -e "\n"
}




do_nothing() {
     echo "Token Request"
     TOKEN=$(curl -s --data "username=admin&password=password&grant_type=password&client_id=admin-cli" http://localhost:9977/auth/realms/master/protocol/openid-connect/token | jq -r .access_token)

     echo $TOKEN


     echo -e "\nCreate User\n"
     curl -s http://localhost:9977/auth/admin/realms/master/users \
          -H "Content-Type: application/json" \
          -H "Authorization: bearer $TOKEN" \
          --data '{"firstName":"King","lastName":"Kong", "email":"kingkong@konghq.com", "enabled":"true", "username":"kong","credentials":[{"type":"password","value":"kong","temporary":false}]}'


     echo -e "\nCreate Client"
     curl -s http://localhost:9977/auth/admin/realms/master/clients \
          -H "Content-Type: application/json" \
          -H "Authorization: bearer $TOKEN" \
          --data '{"secret":"kong", "name":"kong-demo", "clientId":"kong-demo","serviceAccountsEnabled":"true","directAccessGrantsEnabled":"true","redirectUris":["http://localhost:8000/*"]}'

}


help(){
cat << EOF

This script will setup a user account and client in Keycloak.

Defaults:
-----------------------------------
User:               kong
Password:           kongstrong
Email:              kingkong@konghq.com

Client ID:          kong-demo
Client secret:      kong

Admin ID:           admin
Admin Password:     password

Host:               localhost
Port:               9977
Realm:              master


Overrides:
-----------------------------------
Options:
    -h              Keycloak hostname
    -p              Keycloak port
    -r              Keycloak realm
    -cid            Keycloak client ID
    -cs             Keycloak client secret
    -uid            Keycloak user ID
    -pw             Keycloak user password
    -e              Keycloak User email address
    --help          display help text
    -aid            Keycloak admin username
    -apw            Keycloak admin password
EOF
}


parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h)
        KEYCLOAK_HOST=$2
        shift
        ;;
    -p)
        KEYCLOAK_PORT=$2
        shift
        ;;
    -r)
        KEYCLOAK_REALM=$2
        shift
        ;;
    -cid)
        KEYCLOAK_CLIENT_ID=$2
        shift
        ;;
    -cs)
        KEYCLOAK_CLIENT_SECRET=$2
        shift
        ;;
    -uid)
        KEYCLOAK_USERNAME=$2
        shift
        ;;
    -pw)
        KEYCLOAK_PASSWORD=$2
        shift
        ;;
    -e)
        KEYCLOAK_USER_EMAIL=$2
        shift
        ;;
    -apw)
        KEYCLOAK_ADMIN_PASSWORD=$2
        shift
        ;;
    -aid)
        KEYCLOAK_ADMIN_USERNAME=$2
        shift
        ;;
    --help)
        help
        exit 0
        ;;
    esac
    shift
  done
}


main() {
    parse_args "$@"
    get_admin_token
    create_user
    create_client
}

main "$@"