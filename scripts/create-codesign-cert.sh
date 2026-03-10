#!/bin/bash
# Creates a self-signed code signing certificate for persistent TCC permissions.
# The certificate is imported into the login keychain so that codesign produces
# a stable identity across rebuilds, letting macOS remember accessibility grants.

set -euo pipefail

CERT_NAME="${1:-Gather Windows Dev}"
VALIDITY_DAYS=7300  # ~20 years
TMPDIR_CERT="$(mktemp -d)"

cleanup() { rm -rf "$TMPDIR_CERT"; }
trap cleanup EXIT

# Check if certificate already exists
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "Certificate '$CERT_NAME' already exists in keychain."
    exit 0
fi

echo "Creating self-signed code signing certificate '$CERT_NAME'..."

KEYCHAIN="$(security default-keychain | tr -d ' "')"

# Generate RSA key + self-signed cert with code signing EKU
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$TMPDIR_CERT/key.pem" \
    -out "$TMPDIR_CERT/cert.pem" \
    -days "$VALIDITY_DAYS" \
    -subj "/CN=$CERT_NAME" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" \
    2>/dev/null

# Export as PKCS12
P12_PASS="$(openssl rand -hex 16)"
openssl pkcs12 -export \
    -inkey "$TMPDIR_CERT/key.pem" \
    -in "$TMPDIR_CERT/cert.pem" \
    -out "$TMPDIR_CERT/cert.p12" \
    -passout "pass:$P12_PASS" \
    -name "$CERT_NAME" \
    2>/dev/null

# Import into login keychain, allow codesign to use it
security import "$TMPDIR_CERT/cert.p12" \
    -k "$KEYCHAIN" \
    -T /usr/bin/codesign \
    -f pkcs12 \
    -P "$P12_PASS"

# Trust the certificate for code signing (requires login password once)
security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$TMPDIR_CERT/cert.pem"

# Allow codesign to access the key without prompting
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "" "$KEYCHAIN" 2>/dev/null || true

echo ""
echo "Certificate '$CERT_NAME' created and trusted for code signing."
echo "Verify with: security find-identity -v -p codesigning"
