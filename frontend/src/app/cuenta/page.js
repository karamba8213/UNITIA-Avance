'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { getUser, clearTokens } from '@/lib/auth'
import { api } from '@/lib/api'
import AddressAutocomplete from '@/components/AddressAutocomplete'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

function formatDate(d) {
  return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(d))
}

const ADDRESS_LABELS = ['Casa', 'Trabajo', 'Otro']

export default function CuentaPage() {
  const router = useRouter()
  const [user, setUser] = useState(null)
  const [customer, setCustomer] = useState(null)
  const [recentOrders, setRecentOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [phone, setPhone] = useState('')

  // Addresses state
  const [addresses, setAddresses] = useState([])
  const [showAddForm, setShowAddForm] = useState(false)
  const [newLabel, setNewLabel] = useState('Casa')
  const [newAddress, setNewAddress] = useState('')
  const [editingIdx, setEditingIdx] = useState(null)

  useEffect(() => {
    const u = getUser()
    if (!u || u.role !== 'CUSTOMER') {
      router.push('/login')
      return
    }
    setUser(u)

    Promise.all([
      api.customer.getProfile(),
      api.customer.getOrders(),
    ])
      .then(([profileRes, ordersRes]) => {
        const prof = profileRes.data
        setCustomer(prof)
        setPhone(prof.phone || '')
        setAddresses(prof.savedAddresses || [])
        setRecentOrders((ordersRes.data || []).slice(0, 3))
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  async function handleSave(e) {
    e.preventDefault()
    setSaving(true)
    setError('')
    setSaved(false)
    try {
      await api.customer.updateProfile({ phone: phone || undefined })
      setSaved(true)
      setTimeout(() => setSaved(false), 2500)
    } catch (err) {
      setError(err.message || 'Error al guardar')
    } finally {
      setSaving(false)
    }
  }

  async function saveAddresses(updated) {
    setAddresses(updated)
    try {
      await api.customer.updateProfile({ savedAddresses: updated })
    } catch {
      // revert on error
      setAddresses(addresses)
    }
  }

  function handleAddAddress() {
    if (!newAddress.trim()) return
    const updated = [...addresses, { label: newLabel, address: newAddress.trim() }]
    saveAddresses(updated)
    setNewAddress('')
    setNewLabel('Casa')
    setShowAddForm(false)
  }

  function handleDeleteAddress(idx) {
    saveAddresses(addresses.filter((_, i) => i !== idx))
  }

  function handleEditSave(idx) {
    if (!addresses[idx]?.address?.trim()) return
    setEditingIdx(null)
    saveAddresses([...addresses])
  }

  function handleLogout() {
    clearTokens()
    router.push('/login')
  }

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  const initials = user.name
    ? user.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  return (
    <div className="min-h-screen bg-background pb-28">
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14">
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Mi Cuenta</h1>
        </div>
      </nav>

      <main className="max-w-xl mx-auto px-4 py-6 space-y-5">
        {/* Avatar & Name */}
        <div className="card flex items-center gap-4">
          {user.image ? (
            <img src={user.image} alt={user.name} className="w-16 h-16 rounded-full object-cover flex-shrink-0" />
          ) : (
            <div className="w-16 h-16 rounded-full bg-primary flex items-center justify-center text-white font-extrabold text-xl flex-shrink-0">
              {initials}
            </div>
          )}
          <div className="min-w-0">
            <p className="font-extrabold text-[#2D2D2D] text-lg leading-tight">{user.name}</p>
            <p className="text-sm text-muted font-medium mt-0.5">{user.email}</p>
          </div>
        </div>

        {/* Phone */}
        <form onSubmit={handleSave} className="card space-y-4">
          <h2 className="font-extrabold text-[#2D2D2D]">Mis datos</h2>

          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
          )}
          {saved && (
            <div className="p-3 bg-green-50 border border-green-200 rounded-2xl text-green-700 text-sm font-bold">✓ Guardado correctamente</div>
          )}

          <div>
            <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Teléfono</label>
            <input
              type="tel"
              className="input"
              placeholder="+52 55 1234 5678"
              value={phone}
              onChange={e => setPhone(e.target.value)}
            />
          </div>

          <button type="submit" className="btn btn-primary w-full" disabled={saving}>
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
        </form>

        {/* Addresses */}
        <div className="card space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="font-extrabold text-[#2D2D2D]">Mis direcciones</h2>
            {!showAddForm && (
              <button
                onClick={() => setShowAddForm(true)}
                className="flex items-center gap-1 text-xs font-bold text-primary hover:text-primary/80 transition-colors"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-4 h-4">
                  <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
                </svg>
                Agregar
              </button>
            )}
          </div>

          {/* Saved addresses list */}
          {addresses.length === 0 && !showAddForm && (
            <div className="text-center py-5">
              <p className="text-3xl mb-2">📍</p>
              <p className="text-sm text-muted font-medium">Aún no tienes direcciones guardadas.</p>
              <p className="text-xs text-muted mt-0.5">Se usarán al hacer pedidos a domicilio.</p>
            </div>
          )}

          <div className="space-y-2">
            {addresses.map((addr, idx) => (
              <div key={idx} className="bg-background rounded-2xl p-3">
                {editingIdx === idx ? (
                  <div className="space-y-2">
                    <select
                      className="input text-sm py-2"
                      value={addr.label}
                      onChange={e => {
                        const updated = [...addresses]
                        updated[idx] = { ...updated[idx], label: e.target.value }
                        setAddresses(updated)
                      }}
                    >
                      {ADDRESS_LABELS.map(l => <option key={l}>{l}</option>)}
                    </select>
                    <AddressAutocomplete
                      value={addr.address}
                      onChange={val => {
                        const updated = [...addresses]
                        updated[idx] = { ...updated[idx], address: val }
                        setAddresses(updated)
                      }}
                      placeholder="Calle, número, colonia..."
                      className="input text-sm py-2"
                    />
                    <div className="flex gap-2">
                      <button onClick={() => handleEditSave(idx)} className="btn btn-primary btn-sm flex-1 text-xs">Guardar</button>
                      <button onClick={() => { setEditingIdx(null); setAddresses([...addresses]) }} className="btn btn-sm flex-1 text-xs bg-white border border-border">Cancelar</button>
                    </div>
                  </div>
                ) : (
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-base">
                      {addr.label === 'Casa' ? '🏠' : addr.label === 'Trabajo' ? '💼' : '📍'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-bold text-primary uppercase tracking-wide">{addr.label}</p>
                      <p className="text-sm text-[#2D2D2D] font-medium mt-0.5 leading-snug">{addr.address}</p>
                    </div>
                    <div className="flex gap-1 flex-shrink-0">
                      <button
                        onClick={() => setEditingIdx(idx)}
                        className="w-7 h-7 rounded-lg flex items-center justify-center text-muted hover:text-primary transition-colors"
                      >
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3.5 h-3.5">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M11 5H6a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-5" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                        </svg>
                      </button>
                      <button
                        onClick={() => handleDeleteAddress(idx)}
                        className="w-7 h-7 rounded-lg flex items-center justify-center text-muted hover:text-red-500 transition-colors"
                      >
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3.5 h-3.5">
                          <polyline points="3 6 5 6 21 6" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M19 6l-1 14H6L5 6" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M10 11v6M14 11v6" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 6V4h6v2" />
                        </svg>
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Add form */}
          {showAddForm && (
            <div className="bg-background rounded-2xl p-3 space-y-2 border-2 border-primary/20">
              <p className="text-xs font-bold text-[#2D2D2D]">Nueva dirección</p>
              <select
                className="input text-sm py-2"
                value={newLabel}
                onChange={e => setNewLabel(e.target.value)}
              >
                {ADDRESS_LABELS.map(l => <option key={l}>{l}</option>)}
              </select>
              <AddressAutocomplete
                value={newAddress}
                onChange={val => setNewAddress(val)}
                placeholder="Ej: Calle 5 de Mayo 123, Col. Centro"
                className="input text-sm py-2"
              />
              <div className="flex gap-2">
                <button onClick={handleAddAddress} className="btn btn-primary btn-sm flex-1 text-xs" disabled={!newAddress.trim()}>
                  Agregar
                </button>
                <button onClick={() => { setShowAddForm(false); setNewAddress('') }} className="btn btn-sm flex-1 text-xs bg-white border border-border">
                  Cancelar
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Recent orders */}
        {recentOrders.length > 0 && (
          <div className="card">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-extrabold text-[#2D2D2D]">Pedidos recientes</h2>
              <Link href="/mi-impacto" className="text-xs text-primary font-bold hover:underline">Ver todos</Link>
            </div>
            <div className="divide-y divide-border">
              {recentOrders.map(order => (
                <div key={order.id} className="py-3 flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-sm font-bold text-[#2D2D2D]">{order.restaurant?.name || 'Restaurante'}</p>
                    <p className="text-xs text-muted">{order.createdAt ? formatDate(order.createdAt) : ''}</p>
                    {order.cause?.name && (
                      <p className="text-xs text-primary font-bold mt-0.5">❤️ {order.cause.name}</p>
                    )}
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-sm font-extrabold text-[#2D2D2D]">{formatCurrency(order.subtotal || 0)}</p>
                    {order.donationAmount > 0 && (
                      <p className="text-xs text-primary font-bold">+{formatCurrency(order.donationAmount)}</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Logout */}
        <div className="card">
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-between text-left py-1 text-red-600 font-bold hover:text-red-700 transition-colors"
          >
            <span>Cerrar sesión</span>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
          </button>
        </div>
      </main>
    </div>
  )
}
