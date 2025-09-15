#!/bin/bash

# Usage:
#   Local: ./upload_to_ssm.sh path/to/.env wam-saudi-api-be-prod
#   Remote: curl -s https://github.com/aslamnk/script/upload_to_ssm.sh | bash -s path/to/.env wam-saudi-api-be-prod

set -euo pipefail

ENV_FILE="${1:-}"
PREFIX="${2:-}"
OUTPUT_FILE="parameters.txt"

if [[ -z "$ENV_FILE" || -z "$PREFIX" ]]; then
  echo "Usage: $0 <path_to_env_file> <parameter_prefix>"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: File '$ENV_FILE' not found."
  exit 1
fi

# Clear previous output file
> "$OUTPUT_FILE"

while IFS='=' read -r key value || [ -n "$key" ]; do
  # Skip comments and empty key lines
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

  # Trim whitespace
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)

  # If value is empty, replace with placeholder for SSM
  if [[ -z "$value" ]]; then
    echo "⚠️  $key is empty — storing placeholder '__EMPTY__' in SSM"
    value="__EMPTY__"
  fi

  PARAM_NAME="${PREFIX}/${key}"

  # Save mapping to output file
  echo "${key}: \"${PARAM_NAME}\"" >> "$OUTPUT_FILE"

  # Get current value if exists
  CURRENT_VALUE=$(aws ssm get-parameter \
    --name "$PARAM_NAME" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text 2>/dev/null || echo "__NOT_FOUND__")

  if [[ "$CURRENT_VALUE" == "__NOT_FOUND__" ]]; then
    echo "🆕 Creating parameter: $PARAM_NAME"
    aws ssm put-parameter \
      --name "$PARAM_NAME" \
      --value "$value" \
      --type "String"
  elif [[ "$CURRENT_VALUE" != "$value" ]]; then
    echo "✏️  Updating parameter (changed): $PARAM_NAME"
    aws ssm put-parameter \
      --name "$PARAM_NAME" \
      --value "$value" \
      --type "String" \
      --overwrite
  else
    echo "✅ Skipping (unchanged): $PARAM_NAME"
  fi

done < "$ENV_FILE"

echo "🎉 Done processing parameters under prefix: $PREFIX"
echo "📄 Parameter mapping saved to $OUTPUT_FILE"
