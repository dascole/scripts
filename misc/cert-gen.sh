#!/bin/bash

# Generate root CA private key
openssl genrsa -out rootCA.key 4096

# Create root CA certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Root CA"

# Generate server private key
openssl genrsa -out kong.example.com.key 2048

# Create server CSR
openssl req -new -key kong.example.com.key -out kong.example.com.csr -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=kong.example.com"

# Create server.ext file for SANs
cat > kong.example.com.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = kong.example.com
EOF

# Sign server CSR with root CA
openssl x509 -req -in kong.example.com.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out kong.example.com.crt -days 365 -sha256 -extfile kong.example.com.ext

# Clean up
rm kong.example.com.csr
rm rootCA.srl

echo "Root CA and server key pair generated successfully."
