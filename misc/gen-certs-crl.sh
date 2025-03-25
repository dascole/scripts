#!/bin/bash

openssl genrsa -out ca.key 4096

openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=Konger"

cat > openssl.cnf <<EOF
[ req ]
default_bits        = 2048
default_keyfile     = server.key
distinguished_name  = req_distinguished_name
req_extensions      = req_ext
prompt              = no
string_mask         = utf8only

[ req_distinguished_name ]
countryName         = US
stateOrProvinceName = California
localityName        = San Francisco
organizationName    = My Company
commonName          = crl.konghq.com

[ req_ext ]
subjectAltName = @alt_names
crlDistributionPoints = URI:http://google.com:8080/crl/my_crl.pem

[alt_names]
DNS.1 = crl.konghq.com
DNS.2 = mtls.konghq.com
EOF

openssl genrsa -out server.key 2048

openssl req -new -key server.key -out server.csr -config openssl.cnf

openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extfile openssl.cnf -extensions req_ext

openssl x509 -in server.crt -text -noout | grep -A 4 "CRL Distribution Points"
