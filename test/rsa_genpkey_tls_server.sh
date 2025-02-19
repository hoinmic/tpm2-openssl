#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
set -eufx

function cleanup()
{
    kill -term $SERVER
    rm testkey.pem testcert.conf testcert.pem
}

cat > testcert.conf << EOF
[ req ]
default_bits        = 2048
default_keyfile     = testkey.pem
encrypt_key         = no
prompt              = no

distinguished_name  = cert_dn
x509_extensions     = cert_ext

[ cert_dn ]
countryName         = GB
commonName          = Common Name

[ cert_ext ]
basicConstraints    = critical, CA:FALSE
subjectAltName      = @alt_names

[ alt_names ]
DNS.1               = localhost
EOF

# create a RSAE private key and then generate a self-signed certificate for it
openssl req -provider tpm2 -provider default -x509 -config testcert.conf -out testcert.pem

# display content of the certificate
openssl x509 -text -noout -in testcert.pem

# start SSL server with RSA-PSS-RSAE signing, port 4431
openssl s_server -provider tpm2 -provider default \
                 -accept 4431 -www -key testkey.pem -cert testcert.pem &
SERVER=$!
trap "cleanup" EXIT

# start SSL client
curl --retry 5 --retry-connrefused --cacert testcert.pem https://localhost:4431/
