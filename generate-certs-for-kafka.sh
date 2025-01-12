#!/bin/bash

# Create the certs directory if it doesn't exist
mkdir -p certs

# Generate CA key and certificate
openssl req -new -x509 -keyout certs/ca.key -out certs/ca.crt -days 3650 -subj "/CN=ca"

# Generate server key and certificate signing request (CSR)
openssl req -new -keyout certs/server.key -out certs/server.csr -subj "/CN=redpanda"

# Sign the server certificate with the CA
openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 3650

# Generate client key and certificate signing request (CSR)
openssl req -new -keyout certs/client.key -out certs/client.csr -subj "/CN=client"

# Sign the client certificate with the CA
openssl x509 -req -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/client.crt -days 3650

# Clean up CSR files
rm certs/server.csr certs/client.csr

echo "Certificates generated in the certs directory:"
ls -l certs