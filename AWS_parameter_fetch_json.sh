#!/bin/bash

# Function to get the value of a parameter from AWS Parameter Store with exponential backoff
get_parameter_value() {
  local param_name="$1"
  local retries=0
  local max_retries=5
  local backoff=1

  while [ $retries -lt $max_retries ]; do
    result=$(aws ssm get-parameter --name "$param_name" --with-decryption --query 'Parameter.Value' --output text 2>&1)
    if [ $? -eq 0 ]; then
      echo "$result"
      return
    fi
    if [[ "$result" == *"ThrottlingException"* ]]; then
      ((retries++))
      echo "ThrottlingException, retrying in $backoff seconds..."
      sleep $backoff
      backoff=$((backoff * 2))
    else
      echo "Error retrieving parameter $param_name: $result"
      return
    fi
  done
}

# Function to get all parameters with exponential backoff
get_all_parameters() {
  local next_token=""
  local result=""
  local retries=0
  local max_retries=5
  local backoff=1

  while [ $retries -lt $max_retries ]; do
    if [ -z "$next_token" ]; then
      result=$(aws ssm describe-parameters --query 'Parameters[*].Name' --output text 2>&1)
    else
      result=$(aws ssm describe-parameters --query 'Parameters[*].Name' --next-token "$next_token" --output text 2>&1)
    fi

    if [ $? -eq 0 ]; then
      echo "$result"
      return
    fi
    if [[ "$result" == *"ThrottlingException"* ]]; then
      ((retries++))
      echo "ThrottlingException, retrying in $backoff seconds..."
      sleep $backoff
      backoff=$((backoff * 2))
    else
      echo "Error retrieving parameters: $result"
      return
    fi
  done
}

# Output JSON file
OUTPUT_FILE="parameters.json"

# Initialize an empty JSON object
echo "{}" > "$OUTPUT_FILE"

# Retrieve all parameters
PARAMETERS=$(get_all_parameters)

# Loop through each parameter and add it to the JSON file
for PARAMETER in $PARAMETERS; do
  VALUE=$(get_parameter_value "$PARAMETER")
  jq --arg key "$PARAMETER" --arg value "$VALUE" '.[$key] = $value' "$OUTPUT_FILE" > tmp.$$.json && mv tmp.$$.json "$OUTPUT_FILE"
done
