function transform(req) {
  console.log('Venice cleanup transformer - input:', JSON.stringify(req, null, 2));
  
  // Deep clone to avoid mutation issues
  const cleanedReq = JSON.parse(JSON.stringify(req));
  
  // Remove cache_control from all message content
  if (cleanedReq.messages) {
    cleanedReq.messages.forEach(message => {
      if (Array.isArray(message.content)) {
        message.content = message.content.map(content => {
          if (content && typeof content === 'object') {
            const { cache_control, ...cleanContent } = content;
            if (cache_control) {
              console.log('Removed cache_control from content:', cache_control);
            }
            return cleanContent;
          }
          return content;
        });
      }
    });
  }
  
  console.log('Venice cleanup transformer - output:', JSON.stringify(cleanedReq, null, 2));
  return cleanedReq;
}

module.exports = transform;