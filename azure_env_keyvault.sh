#!/bin/bash
File=.env

VAULT_NAME="<keyvault-name"

if [[ -f "$File" ]]; then
    echo "$File exists; truncating..."
    > $File
fi
get_secret() {
    local secret_name=$1
    az keyvault secret show --name "$secret_name" --vault-name "$VAULT_NAME" --query "value" -o tsv
}

addEnv() {
    local key=$1
    local value=$2
    echo "$key=$value" >> .env
    echo "$key is updated :- $value"
}
#------
            # Database settings
            addEnv <ENV-NAME> "$(get_secret "<secret_name>")"
            addEnv <ENV-NAME2> "$(get_secret "<secret_name2>")"
echo "Secrets fetched and updated in .env file."
