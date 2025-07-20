#!/bin/bash

echo "🚀 创建 Let's hang 后端项目"
echo "=========================="

# 初始化npm项目
npm init -y

# 安装核心依赖
echo "📦 安装依赖包..."
npm install express prisma @prisma/client bcryptjs jsonwebtoken cors helmet express-rate-limit joi dotenv axios redis multer

# 安装开发依赖
npm install -D nodemon jest supertest

# 创建目录结构
echo "📁 创建项目结构..."
mkdir -p src/{controllers,middleware,routes,services,utils}
mkdir -p prisma
mkdir -p tests

# 更新package.json
echo "📝 配置package.json..."
cat > package.json << 'EOL'
{
  "name": "letshang-backend",
  "version": "1.0.0",
  "description": "Let's hang intelligent social platform backend",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "start:prod": "npm run db:deploy && npm start",
    "db:deploy": "npx prisma migrate deploy",
    "db:generate": "npx prisma generate",
    "db:push": "npx prisma db push",
    "db:studio": "npx prisma studio",
    "test": "jest"
  },
  "keywords": ["social", "ai", "recommendation", "backend"],
  "author": "Let's hang Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "prisma": "^5.0.0",
    "@prisma/client": "^5.0.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.7.0",
    "joi": "^17.9.0",
    "dotenv": "^16.0.3",
    "axios": "^1.4.0",
    "redis": "^4.6.0",
    "multer": "^1.4.5"
  },
  "devDependencies": {
    "nodemon": "^2.0.22",
    "jest": "^29.5.0",
    "supertest": "^6.3.3"
  }
}
EOL

# 创建Prisma Schema
echo "🗄️ 创建数据库Schema..."
cat > prisma/schema.prisma << 'EOL'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id              String    @id @default(uuid())
  email           String    @unique
  passwordHash    String?   @map("password_hash")
  name            String
  age             Int?
  gender          String?
  location        String?
  bio             String?
  avatarUrl       String?   @map("avatar_url")
  mbtiType        String?   @map("mbti_type")
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @updatedAt @map("updated_at")
  isActive        Boolean   @default(true) @map("is_active")
  emailVerified   Boolean   @default(false) @map("email_verified")
  lastLogin       DateTime? @map("last_login")

  socialAccounts  SocialAccount[]
  preferences     UserPreferences?
  interests       UserInterest[]
  organizedActivities Activity[] @relation("ActivityOrganizer")
  participations  ActivityParticipant[]
  matches         UserMatch[]
  calendarIntegrations CalendarIntegration[]

  @@map("users")
}

model SocialAccount {
  id             String  @id @default(uuid())
  userId         String  @map("user_id")
  platform       String
  platformUserId String? @map("platform_user_id")
  username       String?
  profileUrl     String? @map("profile_url")
  isPublic       Boolean @default(false) @map("is_public")
  createdAt      DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, platform])
  @@map("social_accounts")
}

model UserPreferences {
  id                     String   @id @default(uuid())
  userId                 String   @unique @map("user_id")
  groupSizePreference    String?  @map("group_size_preference")
  activityLevel          Int?     @map("activity_level")
  meetingStyle           String?  @map("meeting_style")
  budgetRange            String?  @map("budget_range")
  aiAnalysisEnabled      Boolean  @default(true) @map("ai_analysis_enabled")
  locationSharingEnabled Boolean  @default(true) @map("location_sharing_enabled")
  createdAt              DateTime @default(now()) @map("created_at")
  updatedAt              DateTime @updatedAt @map("updated_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("user_preferences")
}

model UserInterest {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  interest  String
  weight    Float    @default(1.0)
  createdAt DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, interest])
  @@map("user_interests")
}

model Activity {
  id                  String    @id @default(uuid())
  title               String
  description         String?
  category            String
  locationName        String?   @map("location_name")
  latitude            Decimal?  @db.Decimal(10, 8)
  longitude           Decimal?  @db.Decimal(11, 8)
  startTime           DateTime  @map("start_time")
  endTime             DateTime? @map("end_time")
  maxParticipants     Int?      @map("max_participants")
  currentParticipants Int       @default(0) @map("current_participants")
  price               Decimal   @default(0) @db.Decimal(10, 2)
  organizerId         String    @map("organizer_id")
  status              String    @default("active")
  imageUrl            String?   @map("image_url")
  requirements        String?
  tags                String[]  @default([])
  createdAt           DateTime  @default(now()) @map("created_at")
  updatedAt           DateTime  @updatedAt @map("updated_at")

  organizer     User                  @relation("ActivityOrganizer", fields: [organizerId], references: [id])
  participants  ActivityParticipant[]
  matches       UserMatch[]

  @@map("activities")
}

model ActivityParticipant {
  id         String    @id @default(uuid())
  activityId String    @map("activity_id")
  userId     String    @map("user_id")
  status     String    @default("joined")
  joinedAt   DateTime  @default(now()) @map("joined_at")
  rating     Int?
  review     String?

  activity Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)
  user     User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([activityId, userId])
  @@map("activity_participants")
}

model CalendarIntegration {
  id           String    @id @default(uuid())
  userId       String    @map("user_id")
  platform     String
  accessToken  String?   @map("access_token")
  refreshToken String?   @map("refresh_token")
  expiresAt    DateTime? @map("expires_at")
  isActive     Boolean   @default(true) @map("is_active")
  lastSync     DateTime? @map("last_sync")
  createdAt    DateTime  @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, platform])
  @@map("calendar_integrations")
}

model UserMatch {
  id                   String   @id @default(uuid())
  userId               String   @map("user_id")
  activityId           String   @map("activity_id")
  matchScore           Float    @map("match_score")
  recommendationReason String?  @map("recommendation_reason")
  shownAt              DateTime @default(now()) @map("shown_at")
  clicked              Boolean  @default(false)
  joined               Boolean  @default(false)
  feedbackScore        Int?     @map("feedback_score")

  user     User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  activity Activity @relation(fields: [activityId], references: [id], onDelete: Cascade)

  @@unique([userId, activityId])
  @@map("user_matches")
}
EOL

# 创建主应用文件
echo "⚡ 创建应用服务器..."
cat > src/app.js << 'EOL'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const activityRoutes = require('./routes/activities');

const app = express();

// 安全中间件
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

// 速率限制
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use(limiter);

// 基础中间件
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 健康检查
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: "Let's hang API",
    version: '1.0.0'
  });
});

// API路由
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/activities', activityRoutes);

// 404处理
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// 错误处理
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(\`🚀 Let's hang server running on port \${PORT}\`);
  console.log(\`📊 Health check: http://localhost:\${PORT}/health\`);
});

module.exports = app;
EOL

echo "🔐 创建认证路由..."
cat > src/routes/auth.js << 'EOL'
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// 用户注册
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, age, gender, location } = req.body;

    // 基本验证
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password and name are required' });
    }

    // 检查用户是否已存在
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // 加密密码
    const passwordHash = await bcrypt.hash(password, 12);

    // 创建用户
    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
        age: age ? parseInt(age) : null,
        gender,
        location
      },
      select: {
        id: true,
        email: true,
        name: true,
        age: true,
        gender: true,
        location: true,
        createdAt: true
      }
    });

    // 生成JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User created successfully',
      user,
      token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 用户登录
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );

    const { passwordHash, ...userWithoutPassword } = user;

    res.json({
      message: 'Login successful',
      user: userWithoutPassword,
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
EOL

echo "👤 创建用户路由..."
cat > src/routes/users.js << 'EOL'
const express = require('express');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// 获取用户列表 (简单版本)
router.get('/', async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        location: true,
        createdAt: true
      },
      take: 10
    });

    res.json({ users });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
EOL

echo "🎯 创建活动路由..."
cat > src/routes/activities.js << 'EOL'
const express = require('express');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// 获取活动列表
router.get('/', async (req, res) => {
  try {
    const activities = await prisma.activity.findMany({
      where: {
        status: 'active',
        startTime: {
          gte: new Date()
        }
      },
      include: {
        organizer: {
          select: {
            id: true,
            name: true
          }
        }
      },
      orderBy: {
        startTime: 'asc'
      },
      take: 20
    });

    res.json({ activities });
  } catch (error) {
    console.error('Get activities error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
EOL

# 创建环境变量文件
echo "⚙️ 创建环境配置..."
cat > .env.example << 'EOL'
# 数据库配置
DATABASE_URL="postgresql://username:password@localhost:5432/letshang_dev"

# JWT配置
JWT_SECRET="your-super-secure-jwt-secret-change-this-in-production"

# 服务器配置
PORT=3001
NODE_ENV="development"
CORS_ORIGIN="*"
EOL

# 创建.gitignore
cat > .gitignore << 'EOL'
# Dependencies
node_modules/
npm-debug.log*

# Environment
.env
.env.local

# Database
*.db
*.sqlite

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Build
dist/
build/

# Uploads
uploads/

# Prisma
prisma/migrations/dev.db*
EOL

# Railway部署配置
echo "🚀 创建部署配置..."
cat > railway.json << 'EOL'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "npm run start:prod",
    "healthcheckPath": "/health"
  }
}
EOL

echo "✅ 项目创建完成!"
echo ""
echo "下一步："
echo "1. npm install          # 安装依赖"
echo "2. 配置GitHub仓库并推送代码"
echo "3. 在Railway部署"
