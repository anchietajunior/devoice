#!/bin/bash

# Create a self-signed certificate for code signing DeVoice
# This certificate will persist in your Keychain, so rebuilds won't require new permissions

CERT_NAME="DeVoice Development"

# Check if certificate already exists
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "✅ Certificate '$CERT_NAME' already exists"
    exit 0
fi

echo "Creating self-signed certificate for DeVoice..."

# Create certificate using certtool (creates in login keychain)
cat > /tmp/devoice-cert.cfg << EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
prompt             = no
[ req_distinguished_name ]
CN = $CERT_NAME
[ extensions ]
keyUsage = digitalSignature
extendedKeyUsage = codeSigning
EOF

# Generate key and certificate
openssl req -x509 -newkey rsa:2048 -keyout /tmp/devoice-key.pem -out /tmp/devoice-cert.pem -days 3650 -nodes -config /tmp/devoice-cert.cfg -extensions extensions 2>/dev/null

# Convert to p12
openssl pkcs12 -export -out /tmp/devoice.p12 -inkey /tmp/devoice-key.pem -in /tmp/devoice-cert.pem -passout pass:devoice 2>/dev/null

# Import to keychain
security import /tmp/devoice.p12 -k ~/Library/Keychains/login.keychain-db -P devoice -T /usr/bin/codesign 2>/dev/null

# Clean up temp files
rm -f /tmp/devoice-cert.cfg /tmp/devoice-key.pem /tmp/devoice-cert.pem /tmp/devoice.p12

# Trust the certificate for code signing
echo ""
echo "⚠️  IMPORTANT: You need to trust the certificate manually:"
echo ""
echo "1. Open 'Keychain Access' app"
echo "2. Find '$CERT_NAME' in 'login' keychain under 'My Certificates'"
echo "3. Double-click it → expand 'Trust' → set 'Code Signing' to 'Always Trust'"
echo "4. Close and enter your password"
echo ""
echo "After trusting, run: ./scripts/build-app.sh"
