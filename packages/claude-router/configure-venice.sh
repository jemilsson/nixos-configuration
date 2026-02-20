#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.claude-code-router"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    error "Config file not found: $CONFIG_FILE"
    error "Please run 'ccr' first to initialize the configuration"
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    error "jq is required but not installed"
    exit 1
fi

log "Reading Venice API key from config..."

# Extract Venice API key from config
VENICE_API_KEY=$(jq -r '.providers[] | select(.name == "venice") | .api_key' "$CONFIG_FILE" 2>/dev/null || echo "")

if [[ -z "$VENICE_API_KEY" || "$VENICE_API_KEY" == "null" ]]; then
    error "Venice API key not found in config"
    error "Please ensure your config has a Venice provider with an API key"
    exit 1
fi

# Expand environment variables in API key
if [[ "$VENICE_API_KEY" == \$* ]]; then
    VENICE_API_KEY=$(eval echo "$VENICE_API_KEY")
fi

if [[ -z "$VENICE_API_KEY" ]]; then
    error "Venice API key is empty after environment variable expansion"
    exit 1
fi

log "Fetching available models from Venice API..."

# Fetch models from Venice API
MODELS_RESPONSE=$(curl -s -H "Authorization: Bearer $VENICE_API_KEY" \
    "https://api.venice.ai/api/v1/models" || true)

if [[ -z "$MODELS_RESPONSE" ]]; then
    error "Failed to fetch models from Venice API"
    exit 1
fi

# Parse model names
MODELS=$(echo "$MODELS_RESPONSE" | jq -r '.data[]?.id // empty' 2>/dev/null || true)

if [[ -z "$MODELS" ]]; then
    warn "No models found in API response, using fallback list"
    # Fallback model list
    MODELS="venice-uncensored
qwen-2.5-qwq-32b
qwen3-4b
mistral-31-24b
qwen3-235b
llama-3.2-3b
llama-3.3-70b
llama-3.1-405b
dolphin-2.9.2-qwen2-72b
qwen-2.5-vl
qwen-2.5-coder-32b
deepseek-r1-671b
deepseek-coder-v2-lite"
fi

log "Found models: $(echo "$MODELS" | wc -l) models"

# Convert models to JSON array
MODELS_JSON=$(echo "$MODELS" | jq -R -s 'split("\n") | map(select(length > 0))')

log "Updating config with fetched models..."

# Update the config with new models
jq --argjson models "$MODELS_JSON" '
  .providers |= map(
    if .name == "venice" then
      .models = $models
    else
      .
    end
  )
' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

log "Configuring router settings..."

# Function to find best model for a purpose
find_model() {
    local purpose="$1"
    case "$purpose" in
        "default")
            echo "$MODELS" | grep -E "(llama-3\.3-70b|mistral-31-24b|qwen3-235b)" | head -1 || echo "llama-3.3-70b"
            ;;
        "background")
            echo "$MODELS" | grep -E "(qwen.*coder|coder)" | head -1 || echo "qwen-2.5-coder-32b"
            ;;
        "think")
            echo "$MODELS" | grep -E "(deepseek.*r1|qwen.*qwq|reasoning)" | head -1 || echo "deepseek-r1-671b"
            ;;
        "longContext")
            echo "$MODELS" | grep -E "(llama-3\.1-405b|qwen3-235b|mistral-31-24b)" | head -1 || echo "llama-3.1-405b"
            ;;
        "webSearch")
            echo "$MODELS" | grep -E "(qwen.*vl|vision|multimodal)" | head -1 || echo "qwen-2.5-vl"
            ;;
    esac
}

# Find best models for each purpose
DEFAULT_MODEL=$(find_model "default")
BACKGROUND_MODEL=$(find_model "background")
THINK_MODEL=$(find_model "think")
LONG_CONTEXT_MODEL=$(find_model "longContext")
WEB_SEARCH_MODEL=$(find_model "webSearch")

log "Selected models:"
log "  Default: venice,$DEFAULT_MODEL"
log "  Background: venice,$BACKGROUND_MODEL"
log "  Think: venice,$THINK_MODEL"
log "  Long Context: venice,$LONG_CONTEXT_MODEL"
log "  Web Search: venice,$WEB_SEARCH_MODEL"

# Add Router configuration
jq --arg default "venice,$DEFAULT_MODEL" \
   --arg background "venice,$BACKGROUND_MODEL" \
   --arg think "venice,$THINK_MODEL" \
   --arg longContext "venice,$LONG_CONTEXT_MODEL" \
   --arg webSearch "venice,$WEB_SEARCH_MODEL" '
  .Router = {
    "default": $default,
    "background": $background,
    "think": $think,
    "longContext": $longContext,
    "longContextThreshold": 60000,
    "webSearch": $webSearch
  }
' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

log "Configuration updated successfully!"
log "Config file: $CONFIG_FILE"
log ""
log "You can now use:"
log "  ccr code 'your prompt'           - Uses default model ($DEFAULT_MODEL)"
log "  ccr start                        - Start the router server"
log "  ccr ui                           - Open web interface"