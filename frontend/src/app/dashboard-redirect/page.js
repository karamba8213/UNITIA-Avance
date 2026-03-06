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
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-3" />
        <p className="text-gray-500 text-sm">Redirigiendo...</p>
      </div>
    </div>
  )
}
