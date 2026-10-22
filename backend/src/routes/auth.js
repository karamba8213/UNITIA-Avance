const { Router } = require('express')
const { z } = require('zod')
const rateLimit = require('express-rate-limit')
const authService = require('../services/authService')

const router = Router()

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, error: 'Too many requests' },
})

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2),
  role: z.enum(['RESTAURANT', 'CAUSE', 'CUSTOMER']),
  profile: z.object({
    name: z.string().optional(),
    description: z.string().optional(),
    address: z.string().optional(),
    phone: z.string().optional(),
    donationPercentage: z.number().min(15).max(100).optional(),
    story: z.string().optional(),
    targetAmount: z.number().min(0).optional(),
  }).optional().default({}),
})

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

const oauthSchema = z.object({
  provider: z.enum(['google', 'apple']),
  providerAccountId: z.string(),
  email: z.string().email(),
  name: z.string().optional(),
  image: z.string().optional(),
  role: z.enum(['RESTAURANT', 'CAUSE', 'CUSTOMER']).optional(),
})

router.post('/register', limiter, async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body)
    const result = await authService.register(data)
    res.status(201).json({ success: true, data: result })
  } catch (err) {
    next(err)
  }
})

router.post('/login', limiter, async (req, res, next) => {
  try {
    const data = loginSchema.parse(req.body)
    const result = await authService.login(data)
    res.json({ success: true, data: result })
  } catch (err) {
    next(err)
  }
})

// OAuth signin/signup — called by NextAuth after Google/Apple auth
router.post('/oauth', async (req, res, next) => {
  try {
    const data = oauthSchema.parse(req.body)
    const result = await authService.oauthLogin(data)
    res.json({ success: true, data: result })
  } catch (err) {
    next(err)
  }
})

router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body
    if (!refreshToken) return res.status(400).json({ success: false, error: 'Refresh token required' })
    const result = await authService.refresh(refreshToken)
    res.json({ success: true, data: result })
  } catch (err) {
    next(err)
  }
})

module.exports = router
