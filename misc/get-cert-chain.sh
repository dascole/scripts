#!/bin/bash

# Generate root CA private key
openssl genrsa -out rootCA.key 4096

# Create root CA certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Root CA"

# Generate intermediary CA 1 private key
openssl genrsa -out intermediary1.key 2048

# Create intermediary CA 1 CSR
openssl req -new -key intermediary1.key -out intermediary1.csr -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Intermediary CA 1"

# Create intermediary CA 1 certificate
openssl x509 -req -in intermediary1.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out intermediary1.crt -days 1825 -sha256 -extfile <(
cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:TRUE,pathlen:1
keyUsage = digitalSignature, keyCertSign, cRLSign
EOF
)

# Generate intermediary CA 2 private key
openssl genrsa -out intermediary2.key 2048

# Create intermediary CA 2 CSR
openssl req -new -key intermediary2.key -out intermediary2.csr -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=Intermediary CA 2"

# Create intermediary CA 2 certificate
openssl x509 -req -in intermediary2.csr -CA intermediary1.crt -CAkey intermediary1.key -CAcreateserial -out intermediary2.crt -days 1825 -sha256 -extfile <(
cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:TRUE,pathlen:0
keyUsage = digitalSignature, keyCertSign, cRLSign
EOF
)

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

# Sign server CSR with intermediary CA 2
openssl x509 -req -in kong.example.com.csr -CA intermediary2.crt -CAkey intermediary2.key -CAcreateserial -out kong.example.com.crt -days 365 -sha256 -extfile kong.example.com.ext

# Clean up
rm kong.example.com.csr
rm rootCA.srl
rm intermediary1.csr
rm intermediary1.srl
rm intermediary2.csr
rm intermediary2.srl

echo "Root CA, two intermediary CAs, and server key pair generated successfully."
