'use client'
import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function DashboardRedirect() {
  const { data: session, status } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (status === 'loading') return
    if (!session) {
      router.replace('/login')
      return
    }
    const role = session.user?.role
    if (role === 'RESTAURANT') router.replace('/restaurant/dashboard')
    else if (role === 'CAUSE') router.replace('/cause/dashboard')
    else if (role === 'ADMIN') router.replace('/admin')
    else router.replace('/')
  }, [session, status, router])

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="text-center">
        <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-3" />
        <p className="text-muted text-sm font-medium">Redirigiendo...</p>
      </div>
    </div>
  )
}
