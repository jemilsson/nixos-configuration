#!/usr/bin/env python3

import json
import os
import sys
import requests
import argparse
from pathlib import Path

def log(message):
    print(f"\033[32m[INFO]\033[0m {message}")

def warn(message):
    print(f"\033[33m[WARN]\033[0m {message}")

def error(message):
    print(f"\033[31m[ERROR]\033[0m {message}", file=sys.stderr)

def get_api_key(args, config_file):
    """Get API key from command line args or config file"""
    if args.api_key:
        log("Using API key from command line")
        return args.api_key, create_or_update_config(args.api_key, config_file)
    else:
        return read_api_key_from_config(config_file)

def create_or_update_config(api_key, config_file):
    """Create new config or update existing with API key"""
    config_dir = config_file.parent
    
    if not config_file.exists():
        log("Creating new config file...")
        config_dir.mkdir(exist_ok=True)
        return {
            "providers": [{
                "name": "venice",
                "api_base_url": "https://api.venice.ai/api/v1/chat/completions",
                "api_key": api_key,
                "models": []
            }]
        }
    
    # Load and update existing config
    try:
        with open(config_file) as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        error(f"Invalid JSON in config file: {e}")
        sys.exit(1)
    
    # Find or create Venice provider
    venice_provider = None
    for provider in config.get("providers", []):
        if provider.get("name") == "venice":
            venice_provider = provider
            break
    
    if not venice_provider:
        config.setdefault("providers", []).append({
            "name": "venice",
            "api_base_url": "https://api.venice.ai/api/v1/chat/completions",
            "api_key": api_key,
            "models": []
        })
    else:
        venice_provider["api_key"] = api_key
    
    return config

def read_api_key_from_config(config_file):
    """Read API key from existing config file"""
    if not config_file.exists():
        error(f"Config file not found: {config_file}")
        error("Please run 'ccr' first to initialize the configuration, or provide --api-key")
        sys.exit(1)
    
    log("Reading Venice API key from config...")
    
    try:
        with open(config_file) as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        error(f"Invalid JSON in config file: {e}")
        sys.exit(1)
    
    # Find Venice provider
    venice_provider = None
    for provider in config.get("providers", []):
        if provider.get("name") == "venice":
            venice_provider = provider
            break
    
    if not venice_provider:
        error("Venice provider not found in config")
        error("Please run 'ccr' first to initialize, or provide --api-key")
        sys.exit(1)
    
    api_key = venice_provider.get("api_key", "")
    
    # Expand environment variables
    if api_key.startswith("$"):
        env_var = api_key[1:]
        api_key = os.environ.get(env_var, "")
    
    if not api_key:
        error("Venice API key is empty")
        error("Please provide --api-key or set the environment variable")
        sys.exit(1)
    
    return api_key, config

def fetch_venice_models(api_key):
    """Fetch model information from Venice API"""
    log("Fetching available models from Venice API...")
    
    try:
        response = requests.get(
            "https://api.venice.ai/api/v1/models",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=10
        )
        response.raise_for_status()
        models_data = response.json()
        
        if not models_data.get("data"):
            raise ValueError("No models found in API response")
            
        # Parse model information
        available_models = []
        for model in models_data.get("data", []):
            if model.get("id"):
                model_spec = model.get("model_spec", {})
                available_models.append({
                    "id": model.get("id"),
                    "name": model_spec.get("name", model.get("id")),
                    "context_length": model_spec.get("availableContextTokens", 0),
                    "pricing": model_spec.get("pricing", {}),
                    "capabilities": model_spec.get("capabilities", {}),
                    "traits": model_spec.get("traits", [])
                })
        
        return available_models
        
    except (requests.RequestException, ValueError) as e:
        error(f"Failed to fetch models from API: {e}")
        error("Cannot proceed without model information from Venice API")
        sys.exit(1)

def filter_compatible_models(available_models):
    """Filter to models that support function calling (structured output preferred but not required)"""
    # First try models with both capabilities
    both_capabilities = [
        model for model in available_models 
        if (model.get("capabilities", {}).get("supportsFunctionCalling", False) and
            model.get("capabilities", {}).get("supportsResponseSchema", False))
    ]
    
    # If we have models with both, use them
    if both_capabilities:
        log(f"Using {len(both_capabilities)} models that support both function calling and structured output")
        return both_capabilities
    
    # Otherwise, just require function calling
    function_calling_models = [
        model for model in available_models 
        if model.get("capabilities", {}).get("supportsFunctionCalling", False)
    ]
    
    if function_calling_models:
        log(f"Using {len(function_calling_models)} models that support function calling")
        return function_calling_models
    
    # Last resort: use all models
    warn("No models support function calling, using all models")
    log(f"Using all {len(available_models)} available models")
    return available_models

def create_model_sets(compatible_models):
    """Create sets of models grouped by traits and capabilities"""
    return {
        'default_code': {
            model["id"] for model in compatible_models 
            if "default_code" in model.get("traits", [])
        },
        'most_intelligent': {
            model["id"] for model in compatible_models 
            if "most_intelligent" in model.get("traits", [])
        },
        'code_optimized': {
            model["id"] for model in compatible_models 
            if model.get("capabilities", {}).get("optimizedForCode", False)
        },
        'reasoning': {
            model["id"] for model in compatible_models 
            if model.get("capabilities", {}).get("supportsReasoning", False)
        },
        'function_calling': [
            model for model in compatible_models 
            if model.get("capabilities", {}).get("supportsFunctionCalling", False)
        ],
        'vision': {
            model["id"] for model in compatible_models 
            if model.get("capabilities", {}).get("supportsVision", False)
        },
        'long_context': [
            model for model in compatible_models 
            if model.get("context_length", 0) > 100000
        ]
    }

def select_default_model(model_sets, compatible_models):
    """Select default model: prefer default_code trait, fallback to most expensive"""
    if model_sets['default_code']:
        return next(iter(model_sets['default_code']))
    if model_sets['code_optimized']:
        return next(iter(model_sets['code_optimized']))
    
    # Fallback to most expensive (usually most capable)
    most_expensive = max(compatible_models, 
                        key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
    return most_expensive["id"]

def select_background_model(compatible_models):
    """Select background model: cheapest"""
    cheapest = min(compatible_models, 
                  key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 999))
    return cheapest["id"]

def select_think_model(model_sets, compatible_models):
    """Select thinking model: most_intelligent trait, reasoning, or best available"""
    
    if model_sets['most_intelligent']:
        # If multiple, pick the most expensive one
        intelligent_models = [m for m in compatible_models if m["id"] in model_sets['most_intelligent']]
        if len(intelligent_models) == 1:
            return intelligent_models[0]["id"]
        most_expensive = max(intelligent_models, 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    if model_sets['reasoning']:
        # If multiple reasoning models, pick the most expensive one
        reasoning_models = [m for m in compatible_models if m["id"] in model_sets['reasoning']]
        if len(reasoning_models) == 1:
            return reasoning_models[0]["id"]
        most_expensive = max(reasoning_models, 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Fallback to most expensive (usually most capable)
    most_expensive = max(compatible_models, 
                        key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
    return most_expensive["id"]

def select_long_context_model(model_sets, compatible_models):
    """Select long context model: longest context + most expensive among long context models"""
    if model_sets['long_context']:
        most_expensive = max(model_sets['long_context'],
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Fallback: most expensive (usually has good context)
    most_expensive = max(compatible_models, 
                        key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
    return most_expensive["id"]

def select_web_search_model(model_sets, compatible_models):
    """Select web search model: function calling + most expensive, fallback to vision"""
    if model_sets['function_calling']:
        most_expensive = max(model_sets['function_calling'], 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    if model_sets['vision']:
        vision_models = [m for m in compatible_models if m["id"] in model_sets['vision']]
        most_expensive = max(vision_models, 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Fallback: most expensive
    most_expensive = max(compatible_models, 
                        key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
    return most_expensive["id"]

def create_router_config(model_sets, compatible_models):
    """Create router configuration with selected models"""
    return {
        "default": f"venice,{select_default_model(model_sets, compatible_models)}",
        "background": f"venice,{select_background_model(compatible_models)}",
        "think": f"venice,{select_think_model(model_sets, compatible_models)}",
        "longContext": f"venice,{select_long_context_model(model_sets, compatible_models)}",
        "longContextThreshold": 60000,
        "webSearch": f"venice,{select_web_search_model(model_sets, compatible_models)}"
    }

def update_config_and_save(config, available_models, router_config, config_file):
    """Update config with models and router settings, then save"""
    # Use openrouter transformer that removes cache_control
    venice_transformer = {
        "use": ["openrouter"]
    }
    
    # Update Venice provider with models and transformer
    for provider in config.get("providers", []):
        if provider.get("name") == "venice":
            provider["models"] = [m["id"] for m in available_models]
            provider["transformer"] = venice_transformer
            break
    
    # Also update uppercase Providers if it exists
    for provider in config.get("Providers", []):
        if provider.get("name") == "venice":
            provider["models"] = [m["id"] for m in available_models]
            provider["transformer"] = venice_transformer
            break
    
    # If Providers is empty but providers exists, copy to Providers
    if not config.get("Providers") and config.get("providers"):
        config["Providers"] = config["providers"]
        for provider in config["Providers"]:
            if provider.get("name") == "venice":
                provider["transformer"] = venice_transformer
    
    config["Router"] = router_config
    
    # Remove custom router and transformer paths since we use built-ins
    config.pop("CUSTOM_ROUTER_PATH", None)
    config.pop("transformers", None)
    config.pop("REQUEST_TRANSFORMERS", None)
    
    # Enable logging to debug transformer issues
    config["LOG"] = True
    config["LOG_LEVEL"] = "debug"
    
    # Log selected models
    log("Selected models:")
    for key, value in router_config.items():
        if key != "longContextThreshold":
            model_id = value.split(",")[1]
            model_name = model_id
            for model in available_models:
                if model["id"] == model_id:
                    model_name = model["name"]
                    break
            log(f"  {key.capitalize()}: {model_id} ({model_name})")
    
    # Save config
    try:
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
    except IOError as e:
        error(f"Failed to write config file: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Configure Venice AI models for claude-code-router")
    parser.add_argument("--api-key", help="Venice API key (if not provided, will read from config)")
    args = parser.parse_args()
    
    config_file = Path.home() / ".claude-code-router" / "config.json"
    
    # Get API key and config
    api_key, config = get_api_key(args, config_file)
    
    # Fetch and process models
    available_models = fetch_venice_models(api_key)
    log(f"Found {len(available_models)} models")
    
    compatible_models = filter_compatible_models(available_models)
    model_sets = create_model_sets(compatible_models)
    
    # Create router configuration
    router_config = create_router_config(model_sets, compatible_models)
    
    # Update and save config
    update_config_and_save(config, available_models, router_config, config_file)
    
    log("Configuration updated successfully!")
    log(f"Config file: {config_file}")
    log("")
    log("You can now use:")
    log("  ccr code 'your prompt'           - Uses default model")
    log("  ccr start                        - Start the router server")
    log("  ccr ui                           - Open web interface")

if __name__ == "__main__":
    main()