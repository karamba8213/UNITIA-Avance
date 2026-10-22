'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency } from '@/lib/auth'

const EMPTY_ITEM = { name: '', description: '', price: '', category: '', imageUrl: '', isAvailable: true }

export default function MenuPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [form, setForm] = useState(EMPTY_ITEM)
  const [editing, setEditing] = useState(null)
  const [saving, setSaving] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') { router.push('/login'); return }
    loadMenu()
  }, [])

  async function loadMenu() {
    try {
      const res = await api.restaurant.getMenu()
      setItems(res.data)
    } catch (err) {
      if (err.status === 401) { clearTokens(); router.push('/login') }
    } finally {
      setLoading(false)
    }
  }

  function openNew() {
    setForm(EMPTY_ITEM)
    setEditing(null)
    setShowForm(true)
    setError('')
  }

  function openEdit(item) {
    setForm({
      name: item.name,
      description: item.description || '',
      price: item.price,
      category: item.category || '',
      imageUrl: item.imageUrl || '',
      isAvailable: item.isAvailable,
    })
    setEditing(item.id)
    setShowForm(true)
    setError('')
  }

  async function handleSave(e) {
    e.preventDefault()
    if (!form.name || !form.price) return
    setSaving(true)
    setError('')
    try {
      const payload = { ...form, price: parseFloat(form.price) }
      if (editing) {
        await api.restaurant.updateMenuItem(editing, payload)
      } else {
        await api.restaurant.createMenuItem(payload)
      }
      setShowForm(false)
      loadMenu()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(id) {
    if (!confirm('¿Deshabilitar este item?')) return
    try {
      await api.restaurant.deleteMenuItem(id)
      loadMenu()
    } catch (err) {
      alert(err.message)
    }
  }

  const grouped = items.reduce((map, item) => {
    const cat = item.category || 'Sin categoría'
    if (!map[cat]) map[cat] = []
    map[cat].push(item)
    return map
  }, {})

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center gap-3" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <Link href="/restaurant/dashboard" className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </Link>
        <h1 className="font-extrabold text-[#2D2D2D] flex-1">Menú</h1>
        <button onClick={openNew} className="btn btn-primary btn-sm">+ Agregar</button>
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {loading ? (
          <div className="text-center text-muted py-12 font-medium">Cargando menú...</div>
        ) : items.length === 0 ? (
          <div className="card text-center py-12">
            <p className="text-4xl mb-3">🍽</p>
            <p className="text-muted mb-5 font-medium">Tu menú está vacío.</p>
            <button onClick={openNew} className="btn btn-primary">Agregar primer item</button>
          </div>
        ) : (
          Object.entries(grouped).map(([cat, catItems]) => (
            <div key={cat} className="mb-6">
              <h2 className="text-xs font-extrabold text-muted uppercase tracking-widest mb-3 px-1">{cat}</h2>
              <div className="space-y-2">
                {catItems.map(item => (
                  <div key={item.id} className={`card flex items-center gap-3 p-4 ${!item.isAvailable ? 'opacity-50' : ''}`}>
                    {item.imageUrl ? (
                      <img src={item.imageUrl} alt={item.name} className="w-14 h-14 rounded-2xl object-cover flex-shrink-0" />
                    ) : (
                      <div className="w-14 h-14 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0">
                        <span className="text-2xl">🍽</span>
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-[#2D2D2D] text-sm">{item.name}</p>
                      {item.description && <p className="text-xs text-muted line-clamp-1 mt-0.5">{item.description}</p>}
                      <p className="font-extrabold text-primary text-sm mt-1">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button onClick={() => openEdit(item)} className="text-xs text-muted hover:text-primary px-3 py-2 rounded-xl hover:bg-primary-bg font-semibold transition-colors">
                        Editar
                      </button>
                      <button onClick={() => handleDelete(item.id)} className="text-xs text-red-400 hover:text-red-600 px-3 py-2 rounded-xl hover:bg-red-50 font-semibold transition-colors">
                        {item.isAvailable ? 'Quitar' : 'Inactivo'}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
      </main>

      {/* Form modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <h3 className="font-extrabold text-[#2D2D2D] text-lg mb-4">{editing ? 'Editar item' : 'Nuevo item'}</h3>
              {error && <p className="text-red-500 text-sm mb-3 font-medium">{error}</p>}
              <form onSubmit={handleSave} className="space-y-3">
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Nombre *</label>
                  <input className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
                </div>
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Precio *</label>
                  <input type="number" className="input" min="0" step="0.01" value={form.price} onChange={e => setForm(f => ({ ...f, price: e.target.value }))} required />
                </div>
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Categoría</label>
                  <input className="input" placeholder="Ej: Platos principales, Bebidas..." value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))} />
                </div>
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Descripción</label>
                  <textarea className="input resize-none" rows={2} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
                </div>
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">URL de imagen</label>
                  <input type="url" className="input" placeholder="https://..." value={form.imageUrl} onChange={e => setForm(f => ({ ...f, imageUrl: e.target.value }))} />
                </div>
                {editing && (
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" className="w-5 h-5 accent-primary rounded" checked={form.isAvailable} onChange={e => setForm(f => ({ ...f, isAvailable: e.target.checked }))} />
                    <span className="text-sm font-bold text-[#2D2D2D]">Disponible</span>
                  </label>
                )}
                <div className="flex gap-3 pt-2">
                  <button type="button" onClick={() => setShowForm(false)} className="btn btn-secondary flex-1 btn-sm">Cancelar</button>
                  <button type="submit" disabled={saving} className="btn btn-primary flex-1 btn-sm">
                    {saving ? 'Guardando...' : 'Guardar'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
