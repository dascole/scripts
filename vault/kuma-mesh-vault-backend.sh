# Enable the secrets engine
TOKEN=kongstrong

curl -i --header "X-Vault-Token: $TOKEN" --request POST \
     --data '{"type": "pki"}' \
     http://localhost:8200/v1/sys/mounts/kmesh-pki-default


# Tune the engine
curl -i --header "X-Vault-Token: $TOKEN" --request POST \
     --data '{"max_lease_ttl": "87600h"}' \
     http://localhost:8200/v1/sys/mounts/kmesh-pki-default/tune


# Create the root cert
#
curl --header "X-Vault-Token: $TOKEN" --request POST \
     --data '{"common_name": "Kong Mesh Default", "uri_sans": "spiffe://default", "ttl": "87600h"}' \
     http://localhost:8200/v1/kmesh-pki-default/root/generate/internal | jq .data.certificate -r


# Create the role for the DPPs
curl -i --header "X-Vault-Token: $TOKEN" --request POST \
     --data '{"allowed_uri_sans": "spiffe://default/*,kuma://*",
              "key_usage": "KeyUsageKeyEncipherment,KeyUsageKeyAgreement,KeyUsageDigitalSignature",
              "ext_key_usage": "ExtKeyUsageServerAuth,ExtKeyUsageClientAuth",
              "client_flag": true,
              "require_cn" :false,
              "allowed_domains": "mesh",
              "allow_subdomains": true,
              "basic_constraints_valid_for_non_ca": true,
              "max_ttl": "720h",
              "ttl": "720h"}' \
     http://localhost:8200/v1/kmesh-pki-default/roles/dataplane-proxies


# Create a policy and upload it
cat > kmesh-default-dataplane-proxies.hcl <<- EOM
path "kmesh-pki-default/issue/dataplane-proxies" {
  capabilities = ["create", "update"]
}
EOM

POLICY=$(jq -n --arg policy "$(cat kmesh-default-dataplane-proxies.hcl)" '{policy: $policy}')
curl -i --header "X-Vault-Token: $TOKEN" --request PUT \
     --data "$POLICY" \
     http://localhost:8200/v1/sys/policy/kmesh-default-dataplane-proxies



# Generate a token
curl --header "X-Vault-Token: $TOKEN" --request POST \
     --data '{"policies": ["kmesh-default-dataplane-proxies"]}' \
     http://localhost:8200/v1/auth/token/create -s| jq .auth.client_token -r