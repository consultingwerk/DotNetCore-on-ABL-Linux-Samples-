#!/usr/bin/env bash
# Creates throw-away test certificates for demo 3.
# NOTHING here is secret and nothing is committed: 03-security/certs/ is git-ignored.
#   ca.pem        demo CA
#   partner.pem   signed by ca.pem        -> chain validates
#   stranger.pem  signed by otherca.pem   -> chain fails (untrusted root)
#   expired.pem   signed by ca.pem, already expired
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=${1:-$HERE/certs}
rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT"

mkca () {   # $1 = base name, $2 = CN
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$1-key.pem" -out "$1.pem" -subj "/CN=$2/O=PUG Challenge Demo" 2>/dev/null
}
mkleaf () { # $1 = base, $2 = CN, $3 = CA base, $4 = days
  openssl req -newkey rsa:2048 -nodes -keyout "$1-key.pem" -out "$1.csr" \
    -subj "/CN=$2/O=PUG Challenge Demo" 2>/dev/null
  openssl x509 -req -in "$1.csr" -CA "$3.pem" -CAkey "$3-key.pem" \
    -CAcreateserial -days "$4" -out "$1.pem" 2>/dev/null
  rm -f "$1.csr"
}

mkca ca      "Demo Root CA"
mkca otherca "Unrelated Root CA"
mkleaf partner  "partner.example"  ca       825
mkleaf stranger "stranger.example" otherca  825

# an already-expired leaf: backdate with faketime if available, else -days 1 and note it
openssl req -newkey rsa:2048 -nodes -keyout expired-key.pem -out expired.csr \
  -subj "/CN=expired.example/O=PUG Challenge Demo" 2>/dev/null
openssl x509 -req -in expired.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -days 1 -not_before 20200101000000Z -not_after 20200102000000Z \
  -out expired.pem 2>/dev/null || \
openssl x509 -req -in expired.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -days 1 -out expired.pem 2>/dev/null
rm -f expired.csr

echo "test material in $OUT:"
for f in ca.pem otherca.pem partner.pem stranger.pem expired.pem; do
  printf '  %-14s %s\n' "$f" "$(openssl x509 -in "$f" -noout -subject -enddate | tr '\n' ' ')"
done
