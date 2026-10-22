'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency } from '@/lib/auth'
import StatsCard from '@/components/dashboard/StatsCard'

function ProgressBar({ progress }) {
  if (progress === null || progress === undefined) return null
  return (
    <div>
      <div className="flex justify-between text-sm mb-2">
        <span className="text-muted font-semibold">Progreso hacia el objetivo</span>
        <span className="font-extrabold text-primary">{progress}%</span>
      </div>
      <div className="h-3 bg-border rounded-full overflow-hidden">
        <div
          className="h-3 bg-gradient-to-r from-primary to-primary-light rounded-full transition-all duration-500"
          style={{ width: `${Math.min(progress, 100)}%` }}
        />
      </div>
    </div>
  )
}

export default function CauseDashboard() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [dashboard, setDashboard] = useState(null)
  const [profile, setProfile] = useState(null)
  const [pendingDonations, setPendingDonations] = useState([])
  const [loading, setLoading] = useState(true)
  const [confirming, setConfirming] = useState(null)

  useEffect(() => {
    if (!user || user.role !== 'CAUSE') {
      router.push('/login')
      return
    }
    loadData()
  }, [])

  async function loadData() {
    try {
      const [dashRes, profileRes, donationsRes] = await Promise.all([
        api.cause.getDashboard(),
        api.cause.getProfile(),
        api.donations.list({ status: 'PAID', limit: 10 }),
      ])
      setDashboard(dashRes.data)
      setProfile(profileRes.data)
      setPendingDonations(donationsRes.data.donations || [])
    } catch (err) {
      if (err.status === 401) {
        clearTokens()
        router.push('/login')
      }
    } finally {
      setLoading(false)
    }
  }

  async function confirmDonation(id) {
    setConfirming(id)
    try {
      await api.donations.confirm(id)
      setPendingDonations(d => d.filter(x => x.id !== id))
      loadData()
    } catch (err) {
      alert(err.message)
    } finally {
      setConfirming(null)
    }
  }

  function logout() {
    clearTokens()
    router.push('/')
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center justify-between" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div>
          <span className="text-xl font-extrabold text-primary">Unitia</span>
          <span className="text-muted ml-2 text-sm font-medium">· Causa</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-muted font-medium hidden sm:block">{user?.name}</span>
          <button onClick={logout} className="text-sm text-muted hover:text-red-500 font-semibold transition-colors">Salir</button>
        </div>
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6">
        <div className="mb-6 flex items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-extrabold text-[#2D2D2D]">{profile?.name}</h1>
            <p className="text-sm text-muted mt-1 font-medium">
              {dashboard?.restaurantCount || 0} restaurante{dashboard?.restaurantCount !== 1 ? 's' : ''} apoyándote
            </p>
          </div>
          <div className="flex gap-2 flex-shrink-0">
            {profile?.slug && (
              <Link href={`/c/${profile.slug}`} target="_blank" className="btn btn-secondary btn-sm">
                Ver página
              </Link>
            )}
          </div>
        </div>

        {/* Stats */}
        {dashboard && (
          <div className="grid grid-cols-2 gap-3 mb-6">
            <StatsCard label="Total recaudado" value={formatCurrency(dashboard.totalRaised)} color="green"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>} />
            <StatsCard label="Pendiente de cobro" value={formatCurrency(dashboard.donations.paid?.total || 0)} sub="Para confirmar" color="blue"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>} />
            <StatsCard label="Por recibir" value={formatCurrency(dashboard.donations.pending?.total || 0)} color="yellow"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>} />
            <StatsCard label="Restaurantes" value={dashboard.restaurantCount} color="primary"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path strokeLinecap="round" strokeLinejoin="round" d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path strokeLinecap="round" strokeLinejoin="round" d="M7 2v20"/><path strokeLinecap="round" strokeLinejoin="round" d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3zm0 0v7"/></svg>} />
          </div>
        )}

        {/* Progress bar */}
        {dashboard?.progress !== null && dashboard?.progress !== undefined && profile?.targetAmount > 0 && (
          <div className="card mb-6">
            <ProgressBar progress={dashboard.progress} />
            <p className="text-xs text-muted mt-2 font-medium">
              Objetivo: {formatCurrency(profile.targetAmount)}
            </p>
          </div>
        )}

        {/* Donations to confirm */}
        {pendingDonations.length > 0 && (
          <div className="card mb-4">
            <h2 className="font-extrabold text-[#2D2D2D] mb-4 flex items-center gap-2">
              Para confirmar
              <span className="badge-paid">{pendingDonations.length}</span>
            </h2>
            <div className="divide-y divide-border">
              {pendingDonations.map(d => (
                <div key={d.id} className="py-3 flex items-center justify-between gap-4">
                  <div>
                    <p className="font-bold text-sm text-[#2D2D2D]">{d.restaurant?.name}</p>
                    <p className="text-xs text-muted">{new Date(d.createdAt).toLocaleDateString('es-MX')}</p>
                    {d.notes && <p className="text-xs text-muted mt-1">"{d.notes}"</p>}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-extrabold text-green-600">{formatCurrency(d.amount)}</span>
                    <button
                      onClick={() => confirmDonation(d.id)}
                      disabled={confirming === d.id}
                      className="btn btn-primary btn-sm"
                    >
                      {confirming === d.id ? '...' : 'Confirmar'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Recent donations */}
        {dashboard?.recentDonations?.length > 0 && (
          <div className="card">
            <h2 className="font-extrabold text-[#2D2D2D] mb-4">Actividad reciente</h2>
            <div className="divide-y divide-border">
              {dashboard.recentDonations.map(d => (
                <div key={d.id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="font-bold text-sm text-[#2D2D2D]">{d.restaurant?.name}</p>
                    <p className="text-xs text-muted">{new Date(d.order?.createdAt || d.createdAt).toLocaleDateString('es-MX')}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-extrabold text-sm text-[#2D2D2D]">{formatCurrency(d.amount)}</p>
                    <span className={`badge-${d.status.toLowerCase()}`}>{d.status}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>

    </div>
  )
}
