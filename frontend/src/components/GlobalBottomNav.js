'use client'
import { useEffect, useState } from 'react'
import { usePathname } from 'next/navigation'
import { getUser } from '@/lib/auth'
import BottomNav from './BottomNav'

const HIDDEN_PATHS = ['/login', '/register', '/(auth)/login', '/(auth)/register', '/chat']

const ROLE_MAP = {
  CUSTOMER: 'customer',
  RESTAURANT: 'restaurant',
  CAUSE: 'cause',
}

export default function GlobalBottomNav() {
  const pathname = usePathname()
  const [role, setRole] = useState(null)

  useEffect(() => {
    const user = getUser()
    setRole(user?.role || null)
  }, [pathname])

  if (HIDDEN_PATHS.some(p => pathname === p || pathname.startsWith(p))) return null
  if (!role || !ROLE_MAP[role]) return null

  return <BottomNav role={ROLE_MAP[role]} />
}
