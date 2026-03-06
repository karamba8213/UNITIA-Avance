'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency } from '@/lib/auth'
import StatsCard from '@/components/dashboard/StatsCard'

function ProgressBar({ progress }) {
  if (progress === null) return null
  return (
    <div>
      <div className="flex justify-between text-sm mb-1">
        <span className="text-gray-500">Progreso hacia el objetivo</span>
        <span className="font-semibold text-primary">{progress}%</span>
      </div>
      <div className="h-3 bg-gray-200 rounded-full overflow-hidden">
        <div
          className="h-3 bg-gradient-to-r from-primary to-secondary rounded-full transition-all duration-500"
          style={{ width: `${progress}%` }}
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
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-gray-400">Cargando...</div>
    </div>
  )

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div>
          <span className="text-xl font-bold text-primary">Unitia</span>
          <span className="text-gray-400 ml-2 text-sm">· Causa</span>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-600 hidden sm:block">{user?.name}</span>
          <button onClick={logout} className="text-sm text-gray-500 hover:text-red-600">Salir</button>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-8">
        <div className="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{profile?.name}</h1>
            <p className="text-sm text-gray-500 mt-1">
              {dashboard?.restaurantCount || 0} restaurante{dashboard?.restaurantCount !== 1 ? 's' : ''} apoyándote
            </p>
          </div>
          <div className="flex gap-2">
            {profile?.slug && (
              <Link href={`/c/${profile.slug}`} target="_blank" className="btn-secondary text-sm">
                Ver página pública
              </Link>
            )}
            <Link href="/cause/settings" className="btn-primary text-sm">Editar perfil</Link>
          </div>
        </div>

        {/* Stats */}
        {dashboard && (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
            <StatsCard label="Total recaudado" value={formatCurrency(dashboard.totalRaised)} color="green" />
            <StatsCard label="Pendiente de cobro" value={formatCurrency(dashboard.donations.paid?.total || 0)} sub="Para confirmar" color="blue" />
            <StatsCard label="Por recibir" value={formatCurrency(dashboard.donations.pending?.total || 0)} color="yellow" />
            <StatsCard label="Restaurantes" value={dashboard.restaurantCount} color="primary" />
          </div>
        )}

        {/* Progress bar */}
        {dashboard?.progress !== null && dashboard?.progress !== undefined && profile?.targetAmount > 0 && (
          <div className="card mb-6">
            <div className="mb-4">
              <ProgressBar progress={dashboard.progress} />
              <p className="text-xs text-gray-400 mt-2">
                Objetivo: {formatCurrency(profile.targetAmount)}
              </p>
            </div>
          </div>
        )}

        {/* Donations to confirm */}
        {pendingDonations.length > 0 && (
          <div className="card mb-6">
            <h2 className="font-semibold text-gray-900 mb-4">
              Donaciones para confirmar <span className="badge-paid ml-2">{pendingDonations.length}</span>
            </h2>
            <div className="divide-y divide-gray-50">
              {pendingDonations.map(d => (
                <div key={d.id} className="py-3 flex items-center justify-between gap-4">
                  <div>
                    <p className="font-medium text-sm text-gray-900">{d.restaurant?.name}</p>
                    <p className="text-xs text-gray-400">{new Date(d.createdAt).toLocaleDateString('es-AR')}</p>
                    {d.notes && <p className="text-xs text-gray-500 mt-1">"{d.notes}"</p>}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-semibold text-green-700">{formatCurrency(d.amount)}</span>
                    <button
                      onClick={() => confirmDonation(d.id)}
                      disabled={confirming === d.id}
                      className="btn-primary text-xs px-3 py-1.5"
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
            <h2 className="font-semibold text-gray-900 mb-4">Actividad reciente</h2>
            <div className="divide-y divide-gray-50">
              {dashboard.recentDonations.map(d => (
                <div key={d.id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-sm">{d.restaurant?.name}</p>
                    <p className="text-xs text-gray-400">{new Date(d.order?.createdAt || d.createdAt).toLocaleDateString('es-AR')}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-sm">{formatCurrency(d.amount)}</p>
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
