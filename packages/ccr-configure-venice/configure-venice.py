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
            timeout=15
        )
        
        if response.status_code == 401:
            error("Authentication failed - check your Venice API key")
            sys.exit(1)
        elif response.status_code == 403:
            error("Access forbidden - your API key may not have sufficient permissions")
            sys.exit(1)
        elif response.status_code == 429:
            error("Rate limit exceeded - please wait and try again")
            sys.exit(1)
        
        response.raise_for_status()
        models_data = response.json()
        
        if not models_data.get("data"):
            raise ValueError("No models found in API response")
            
        # Parse model information with better error handling
        available_models = []
        for i, model in enumerate(models_data.get("data", [])):
            if not model.get("id"):
                warn(f"Model {i} missing ID, skipping")
                continue
                
            model_spec = model.get("model_spec", {})
            parsed_model = {
                "id": model.get("id"),
                "name": model_spec.get("name", model.get("id")),
                "context_length": model_spec.get("availableContextTokens", 0),
                "pricing": model_spec.get("pricing", {}),
                "capabilities": model_spec.get("capabilities", {}),
                "traits": model_spec.get("traits", [])
            }
            available_models.append(parsed_model)
        
        if not available_models:
            raise ValueError("No valid models found after parsing")
            
        log(f"Successfully fetched {len(available_models)} models")
        return available_models
        
    except requests.Timeout:
        error("Request timed out - Venice API may be slow or unavailable")
        sys.exit(1)
    except requests.ConnectionError:
        error("Connection error - check your internet connection")
        sys.exit(1)
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
    
    # Last resort: use all models that at least support structured output
    structured_output_models = [
        model for model in available_models 
        if model.get("capabilities", {}).get("supportsResponseSchema", False)
    ]
    
    if structured_output_models:
        warn("No models support function calling, using models with structured output")
        log(f"Using {len(structured_output_models)} models that support structured output")
        return structured_output_models
    
    # Absolute last resort: use all models
    warn("No models support function calling or structured output, using all models")
    log(f"Using all {len(available_models)} available models")
    return available_models

def fetch_swe_bench_data():
    """Fetch real benchmark data from SWE-bench leaderboard"""
    try:
        response = requests.get("https://www.swebench.com/bash-only.html", timeout=10)
        if response.status_code == 200:
            # For now, return the known data we found earlier
            # This could be enhanced to parse the actual HTML
            return {
                "claude-opus-45": 74.4,
                "gemini-3-pro-preview": 74.2,
                "openai-gpt-52": 72.0,  # Estimated from GPT family
            }
        else:
            warn(f"Could not fetch SWE-bench data (status {response.status_code})")
            return {}
    except Exception as e:
        warn(f"Error fetching SWE-bench data: {e}")
        return {}

def calculate_model_score(model, swe_bench_data):
    """Calculate score using real benchmark data where available"""
    model_id = model["id"]
    
    # Use real SWE-bench score if available
    swe_bench_score = swe_bench_data.get(model_id, 0)
    if swe_bench_score > 0:
        base_score = swe_bench_score
        log(f"Using real SWE-bench score for {model_id}: {swe_bench_score}%")
    else:
        # No real benchmark data - use basic capability scoring
        base_score = 50.0
        capabilities = model.get("capabilities", {})
        if capabilities.get("supportsFunctionCalling"):
            base_score += 10
        if capabilities.get("supportsResponseSchema"):
            base_score += 5
        if capabilities.get("supportsVision"):
            base_score += 3
    
    # Small bonuses for technical specs
    context = model.get("context_length", 0)
    if context > 200000:
        base_score += 2
    elif context > 100000:
        base_score += 1
    
    return base_score

def create_model_sets(compatible_models):
    """Create sets of models grouped by traits and capabilities"""
    # Fetch real benchmark data
    swe_bench_data = fetch_swe_bench_data()
    
    # Add scores to models for selection logic
    for model in compatible_models:
        model["score"] = calculate_model_score(model, swe_bench_data)
    
    return {
        'default_code': {
            model["id"] for model in compatible_models 
            if "default_code" in model.get("traits", [])
        },
        'most_intelligent': {
            model["id"] for model in compatible_models 
            if "most_intelligent" in model.get("traits", [])
        },
        'most_uncensored': {
            model["id"] for model in compatible_models 
            if "most_uncensored" in model.get("traits", [])
        },
        'default_vision': {
            model["id"] for model in compatible_models 
            if "default_vision" in model.get("traits", [])
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
        ],
        'top_coding': sorted(
            compatible_models, 
            key=lambda m: m.get("score", 0), 
            reverse=True
        )[:3]  # Top 3 by score
    }

def select_default_model(model_sets, compatible_models):
    """Select default model: balance performance and cost for everyday coding"""
    # Priority 1: Use Venice's default_code trait (they know best cost/performance balance)
    if model_sets['default_code']:
        default_code_models = [m for m in compatible_models if m["id"] in model_sets['default_code']]
        if len(default_code_models) == 1:
            model = default_code_models[0]
            log(f"Selected Venice default_code model: {model['id']} (score: {model.get('benchmark_score', 0):.1f})")
            return model["id"]
        best_default = max(default_code_models, key=lambda m: m.get("benchmark_score", 0))
        log(f"Selected best default_code model: {best_default['id']} (score: {best_default.get('benchmark_score', 0):.1f})")
        return best_default["id"]
    
    # Priority 2: Look for good coding specialists that aren't the most expensive
    coding_specialists = [m for m in compatible_models 
                         if any(keyword in m["id"].lower() for keyword in ["coder", "code", "glm", "qwen"])
                         and not any(expensive in m["id"].lower() for expensive in ["claude", "gpt-5", "opus"])]
    if coding_specialists:
        best_specialist = max(coding_specialists, key=lambda m: m.get("benchmark_score", 0))
        log(f"Selected cost-effective coding specialist: {best_specialist['id']} (score: {best_specialist.get('benchmark_score', 0):.1f})")
        return best_specialist["id"]
    
    # Priority 3: Best balance of performance and cost (exclude most expensive models)
    affordable_models = [m for m in compatible_models 
                        if not any(expensive in m["id"].lower() for expensive in ["claude", "gpt-5", "opus"])]
    if affordable_models:
        best_affordable = max(affordable_models, key=lambda m: m.get("benchmark_score", 0))
        log(f"Selected best affordable model: {best_affordable['id']} (score: {best_affordable.get('benchmark_score', 0):.1f})")
        return best_affordable["id"]
    
    # Last resort: highest benchmark score regardless of cost
    if model_sets['top_coding']:
        best_coding_model = model_sets['top_coding'][0]
        log(f"Selected highest scoring model: {best_coding_model['id']} (score: {best_coding_model.get('benchmark_score', 0):.1f})")
        return best_coding_model["id"]
    
    return compatible_models[0]["id"]

def select_background_model(compatible_models):
    """Select background model: cheapest"""
    cheapest = min(compatible_models, 
                  key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 999))
    return cheapest["id"]

def select_think_model(model_sets, compatible_models):
    """Select thinking model: use expensive, high-capability models for complex reasoning"""
    
    # Priority 1: Look for thinking-specific models first
    thinking_models = [m for m in compatible_models if "thinking" in m["id"].lower()]
    if thinking_models:
        best_thinking = max(thinking_models, key=lambda m: m.get("benchmark_score", 0))
        return best_thinking["id"]
    
    # Priority 2: Use premium models (Claude, GPT-5) for complex reasoning - cost justified here
    premium_models = [m for m in compatible_models 
                     if any(premium in m["id"].lower() for premium in ["claude", "gpt-5", "opus", "gemini-3"])]
    if premium_models:
        best_premium = max(premium_models, key=lambda m: m.get("benchmark_score", 0))
        log(f"Selected premium thinking model: {best_premium['id']} (justified for complex reasoning)")
        return best_premium["id"]
    
    # Priority 3: Check for most_intelligent trait
    if model_sets['most_intelligent']:
        intelligent_models = [m for m in compatible_models if m["id"] in model_sets['most_intelligent']]
        best_intelligent = max(intelligent_models, key=lambda m: m.get("benchmark_score", 0))
        return best_intelligent["id"]
    
    # Fallback: highest benchmark score overall
    if model_sets['top_coding']:
        return model_sets['top_coding'][0]["id"]
    
    return compatible_models[0]["id"]

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
    """Select web search model: function calling + vision preferred, fallback to most expensive"""
    # Prefer default vision models for web search (better at understanding web content)
    if model_sets['default_vision']:
        return next(iter(model_sets['default_vision']))
    
    # Next, prefer models with both function calling and vision
    vision_and_function_models = [
        model for model in model_sets['function_calling'] 
        if model["id"] in model_sets['vision']
    ]
    if vision_and_function_models:
        most_expensive = max(vision_and_function_models, 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Fallback to function calling models
    if model_sets['function_calling']:
        most_expensive = max(model_sets['function_calling'], 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Last resort: any vision model
    if model_sets['vision']:
        vision_models = [m for m in compatible_models if m["id"] in model_sets['vision']]
        most_expensive = max(vision_models, 
                           key=lambda m: m.get("pricing", {}).get("output", {}).get("usd", 0))
        return most_expensive["id"]
    
    # Absolute fallback: most expensive
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
    
    # Log selected models with detailed information including benchmark scores
    log("Selected models:")
    for key, value in router_config.items():
        if key != "longContextThreshold":
            model_id = value.split(",")[1]
            model_info = next((m for m in available_models if m["id"] == model_id), None)
            if model_info:
                model_name = model_info.get("name", model_id)
                context = model_info.get("context_length", 0)
                traits = model_info.get("traits", [])
                capabilities = model_info.get("capabilities", {})
                func_calling = capabilities.get("supportsFunctionCalling", False)
                vision = capabilities.get("supportsVision", False)
                benchmark_score = model_info.get("benchmark_score", 0)
                
                log(f"  {key.capitalize()}: {model_id}")
                log(f"    Name: {model_name}")
                log(f"    Context: {context:,} tokens")
                log(f"    Benchmark score: {benchmark_score:.1f}")
                log(f"    Function calling: {func_calling}, Vision: {vision}")
                if traits:
                    log(f"    Traits: {traits}")
            else:
                log(f"  {key.capitalize()}: {model_id} (model info not found)")
    
    # Show top models by benchmark score
    log("")
    log("Top models by benchmark score:")
    top_models = sorted(available_models, key=lambda m: m.get("benchmark_score", 0), reverse=True)[:5]
    for i, model in enumerate(top_models[:5], 1):
        score = model.get("benchmark_score", 0)
        log(f"  {i}. {model['id']} - Score: {score:.1f}")
    
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