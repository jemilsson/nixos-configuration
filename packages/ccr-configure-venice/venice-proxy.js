#!/usr/bin/env node

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 3457;

// Proxy middleware that strips cache_control
const veniceProxy = createProxyMiddleware({
  target: 'https://api.venice.ai',
  changeOrigin: true,
  pathRewrite: {
    '^/proxy': ''
  },
  onProxyReq: (proxyReq, req, res) => {
    if (req.body) {
      console.log('Original request body:', JSON.stringify(req.body, null, 2));
      
      // Remove cache_control from messages
      if (req.body.messages) {
        req.body.messages.forEach(message => {
          if (Array.isArray(message.content)) {
            message.content = message.content.map(content => {
              if (content && typeof content === 'object' && content.cache_control) {
                console.log('Removing cache_control from content');
                const { cache_control, ...cleanContent } = content;
                return cleanContent;
              }
              return content;
            });
          }
        });
      }
      
      // Also remove from system messages
      if (req.body.system) {
        req.body.system = req.body.system.map(content => {
          if (content && typeof content === 'object' && content.cache_control) {
            console.log('Removing cache_control from system content');
            const { cache_control, ...cleanContent } = content;
            return cleanContent;
          }
          return content;
        });
      }
      
      console.log('Cleaned request body:', JSON.stringify(req.body, null, 2));
      
      // Update the proxy request
      const bodyData = JSON.stringify(req.body);
      proxyReq.setHeader('Content-Type', 'application/json');
      proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
      proxyReq.write(bodyData);
    }
  },
});

// Parse JSON middleware
app.use(express.json());

// All requests go through the proxy
app.use('/proxy', veniceProxy);

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Venice proxy server running on http://127.0.0.1:${PORT}`);
  console.log('Configure venice provider to use: http://127.0.0.1:3457/proxy/api/v1/chat/completions');
});