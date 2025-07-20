const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    message: '🚀 Let\'s hang API is running!',
    version: '1.0.0'
  });
});

// 根路径
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Let\'s hang API! 🎉',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      test: '/api/test'
    }
  });
});

// 测试API端点
app.get('/api/test', (req, res) => {
  res.json({
    message: 'API is working perfectly!',
    timestamp: new Date().toISOString(),
    data: {
      users: 0,
      activities: 0,
      status: 'ready for deployment'
    }
  });
});

// 模拟用户端点
app.get('/api/users', (req, res) => {
  res.json({
    message: 'Users endpoint working!',
    users: [],
    count: 0
  });
});

// 404处理
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    availableRoutes: ['/', '/health', '/api/test', '/api/users']
  });
});

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`🚀 Let's hang server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌐 Home: http://localhost:${PORT}/`);
  console.log(`🧪 Test: http://localhost:${PORT}/api/test`);
});

module.exports = app;
