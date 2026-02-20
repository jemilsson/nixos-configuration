const axios = require('axios');

module.exports = async function router(req, config) {
  console.log('Custom router called with request:', JSON.stringify(req.body, null, 2));
  
  // Clean the request by removing cache_control
  const cleanedBody = JSON.parse(JSON.stringify(req.body));
  
  // Remove cache_control from messages
  if (cleanedBody.messages) {
    cleanedBody.messages.forEach(message => {
      if (Array.isArray(message.content)) {
        message.content = message.content.map(content => {
          if (content && typeof content === 'object' && content.cache_control) {
            console.log('Removing cache_control from message content');
            const { cache_control, ...cleanContent } = content;
            return cleanContent;
          }
          return content;
        });
      }
    });
  }
  
  // Remove cache_control from system messages
  if (cleanedBody.system) {
    cleanedBody.system = cleanedBody.system.map(content => {
      if (content && typeof content === 'object' && content.cache_control) {
        console.log('Removing cache_control from system content');
        const { cache_control, ...cleanContent } = content;
        return cleanContent;
      }
      return content;
    });
  }

  // Extract model from the original model field (e.g., "venice,qwen3-4b" -> "qwen3-4b")
  const modelParts = cleanedBody.model.split(',');
  const veniceModel = modelParts[1] || modelParts[0];
  cleanedBody.model = veniceModel;
  
  console.log('Cleaned request body:', JSON.stringify(cleanedBody, null, 2));
  
  // Find Venice provider config
  const veniceProvider = config.providers?.find(p => p.name === 'venice') || 
                        config.Providers?.find(p => p.name === 'venice');
  
  if (!veniceProvider) {
    throw new Error('Venice provider not found in config');
  }

  try {
    // Make direct API call to Venice
    const response = await axios.post(veniceProvider.api_base_url, cleanedBody, {
      headers: {
        'Authorization': `Bearer ${veniceProvider.api_key}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('Venice API response:', response.status);
    return response.data;
  } catch (error) {
    console.error('Venice API error:', error.response?.data || error.message);
    throw error;
  }
}