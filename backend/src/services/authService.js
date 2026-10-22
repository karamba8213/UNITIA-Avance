const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const prisma = require('../config/database')

function generateSlug(name) {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
}

async function uniqueSlug(base, model) {
  let slug = generateSlug(base)
  let count = 1
  while (true) {
    const existing = await prisma[model].findUnique({ where: { slug } })
    if (!existing) return slug
    slug = `${generateSlug(base)}-${++count}`
  }
}

async function register({ email, password, name, role, profile }) {
  const existing = await prisma.user.findUnique({ where: { email } })
  if (existing) {
    const err = new Error('Email already in use')
    err.status = 409
    throw err
  }

  const hashed = await bcrypt.hash(password, 12)

  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: { email, password: hashed, name, role },
    })

    if (role === 'RESTAURANT') {
      const slug = await uniqueSlug(profile.name || name, 'restaurant')
      await tx.restaurant.create({
        data: {
          userId: newUser.id,
          name: profile.name || name,
          slug,
          description: profile.description,
          address: profile.address,
          phone: profile.phone,
          donationPercentage: profile.donationPercentage ?? 15.0,
        },
      })
    } else if (role === 'CAUSE') {
      const slug = await uniqueSlug(profile.name || name, 'cause')
      await tx.cause.create({
        data: {
          userId: newUser.id,
          name: profile.name || name,
          slug,
          description: profile.description || '',
          story: profile.story || '',
          targetAmount: profile.targetAmount ?? 0,
        },
      })
    } else if (role === 'CUSTOMER') {
      await tx.customer.create({
        data: {
          userId: newUser.id,
          phone: profile.phone,
        },
      })
    }

    return newUser
  })

  return signTokens(user)
}

async function login({ email, password }) {
  const user = await prisma.user.findUnique({ where: { email } })
  if (!user) {
    const err = new Error('Invalid credentials')
    err.status = 401
    throw err
  }

  const valid = await bcrypt.compare(password, user.password)
  if (!valid) {
    const err = new Error('Invalid credentials')
    err.status = 401
    throw err
  }

  return signTokens(user)
}

// OAuth login: find or create user, then return tokens
async function oauthLogin({ provider, providerAccountId, email, name, image, role }) {
  // Try to find existing user by email
  let user = await prisma.user.findUnique({ where: { email } })

  if (!user) {
    // New OAuth user — default role is CUSTOMER
    const assignedRole = role || 'CUSTOMER'
    const profileName = name || email.split('@')[0]

    user = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email,
          password: '', // OAuth users have no password
          name: profileName,
          role: assignedRole,
          provider,
          providerAccountId,
          image: image || null,
        },
      })

      if (assignedRole === 'RESTAURANT') {
        const slug = await uniqueSlug(profileName, 'restaurant')
        await tx.restaurant.create({
          data: {
            userId: newUser.id,
            name: profileName,
            slug,
            donationPercentage: 15.0,
          },
        })
      } else if (assignedRole === 'CAUSE') {
        const slug = await uniqueSlug(profileName, 'cause')
        await tx.cause.create({
          data: {
            userId: newUser.id,
            name: profileName,
            slug,
            description: '',
            story: '',
          },
        })
      } else if (assignedRole === 'CUSTOMER') {
        await tx.customer.create({
          data: {
            userId: newUser.id,
          },
        })
      }

      return newUser
    })
  } else {
    // Update OAuth metadata if needed
    if (!user.provider) {
      await prisma.user.update({
        where: { id: user.id },
        data: { provider, providerAccountId, image: image || undefined },
      })
    }
  }

  return signTokens(user)
}

function signTokens(user) {
  const payload = { id: user.id, email: user.email, role: user.role, name: user.name }
  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  })
  const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  })
  return { accessToken, refreshToken, user: payload }
}

async function refresh(token) {
  let payload
  try {
    payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET)
  } catch {
    const err = new Error('Invalid refresh token')
    err.status = 401
    throw err
  }

  const user = await prisma.user.findUnique({ where: { id: payload.id } })
  if (!user) {
    const err = new Error('User not found')
    err.status = 401
    throw err
  }

  return signTokens(user)
}

module.exports = { register, login, oauthLogin, refresh }
