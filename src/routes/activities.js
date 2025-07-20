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
