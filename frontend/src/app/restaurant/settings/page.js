'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens } from '@/lib/auth'

export default function RestaurantSettingsPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [form, setForm] = useState({ name: '', description: '', address: '', phone: '', logo: '', donationPercentage: 15 })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [restaurantSlug, setRestaurantSlug] = useState('')

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') { router.push('/login'); return }
    api.restaurant.getProfile()
      .then(profileRes => {
        const p = profileRes.data
        setRestaurantSlug(p.slug)
        setForm({
          name: p.name || '',
          description: p.description || '',
          address: p.address || '',
          phone: p.phone || '',
          logo: p.logo || '',
          donationPercentage: p.donationPercentage || 15,
        })
      })
      .catch(err => { if (err.status === 401) { clearTokens(); router.push('/login') } })
      .finally(() => setLoading(false))
  }, [])

  async function handleSave(e) {
    e.preventDefault()
    setSaving(true)
    setError('')
    setSaved(false)
    try {
      await api.restaurant.updateProfile({
        ...form,
        donationPercentage: parseFloat(form.donationPercentage),
        logo: form.logo || undefined,
      })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center gap-3" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <Link href="/restaurant/dashboard" className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </Link>
        <h1 className="font-extrabold text-[#2D2D2D] flex-1">Configuración</h1>
        {restaurantSlug && (
          <Link href={`/r/${restaurantSlug}`} target="_blank" className="text-xs text-primary font-bold hover:underline">
            Ver página →
          </Link>
        )}
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {saved && (
          <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-2xl text-green-700 text-sm font-bold">
            ✓ Cambios guardados correctamente.
          </div>
        )}
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
        )}

        <form onSubmit={handleSave} className="space-y-4">
          <div className="card space-y-4">
            <h2 className="font-extrabold text-[#2D2D2D]">Perfil del restaurante</h2>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Nombre</label>
              <input className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Descripción</label>
              <textarea className="input resize-none" rows={2} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Dirección</label>
              <input className="input" value={form.address} onChange={e => setForm(f => ({ ...f, address: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                Teléfono WhatsApp
                <span className="text-muted font-normal ml-1">(para recibir notificaciones de pedidos)</span>
              </label>
              <input type="tel" className="input" placeholder="+521234567890" value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} />
              <p className="text-xs text-muted mt-1.5">Formato internacional: +52 seguido de 10 dígitos</p>
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Logo (URL)</label>
              <input type="url" className="input" placeholder="https://..." value={form.logo} onChange={e => setForm(f => ({ ...f, logo: e.target.value }))} />
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-extrabold text-[#2D2D2D]">Donación</h2>
            <p className="text-sm text-muted leading-relaxed">
              Los clientes eligen la causa al hacer su pedido. Todos los restaurantes apoyan a todas las causas de Unitia.
            </p>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                Porcentaje de donación por pedido
              </label>
              <div className="flex items-center gap-3">
                <input
                  type="number"
                  className="input w-28"
                  min="15"
                  max="100"
                  step="0.5"
                  value={form.donationPercentage}
                  onChange={e => setForm(f => ({ ...f, donationPercentage: e.target.value }))}
                />
                <span className="text-muted text-sm font-medium">% de cada pedido</span>
              </div>
              <p className="text-xs text-muted mt-1.5 bg-primary-bg rounded-xl px-3 py-2 font-medium">
                En un pedido de $1,000, donarías ${(1000 * form.donationPercentage / 100).toFixed(2)} a la causa.
              </p>
            </div>
          </div>

          <button type="submit" disabled={saving} className="btn btn-primary w-full">
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
        </form>
      </main>

    </div>
  )
}
