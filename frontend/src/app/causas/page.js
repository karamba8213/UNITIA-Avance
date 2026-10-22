'use client'
import { useEffect, useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser } from '@/lib/auth'

const CATEGORIES = ['Todas', 'Educación', 'Alimentación', 'Medio ambiente', 'Salud', 'Animales', 'General']

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

function CausasPageInner() {
  const router = useRouter()
  const searchParams = useSearchParams()

  const [causes, setCauses] = useState([])
  const [loading, setLoading] = useState(true)
  const [category, setCategory] = useState('Todas')
  const [search, setSearch] = useState('')
  const [codeInput, setCodeInput] = useState('')
  const [codeError, setCodeError] = useState('')
  const [user, setUser] = useState(null)
  const [favoriteCauseId, setFavoriteCauseId] = useState(null)

  useEffect(() => {
    const u = getUser()
    setUser(u)
    if (u?.role === 'CUSTOMER') {
      api.customer.getProfile()
        .then(res => setFavoriteCauseId(res.data?.favoriteCauseId || null))
        .catch(() => {})
    }

    api.public.getCauses()
      .then(res => setCauses(res.data || []))
      .catch(() => setCauses([]))
      .finally(() => setLoading(false))
  }, [])

  function handleCodeSubmit(e) {
    e.preventDefault()
    const slug = codeInput.trim().toLowerCase()
    if (!slug) return
    const found = causes.find(c => c.slug === slug)
    if (found) {
      router.push(`/c/${slug}`)
    } else {
      setCodeError('Código no encontrado. Verificá el código e intentá de nuevo.')
      setTimeout(() => setCodeError(''), 3000)
    }
  }

  const filtered = causes.filter(cause => {
    const matchCat = category === 'Todas' || (cause.category || 'General') === category
    const matchSearch = !search ||
      cause.name.toLowerCase().includes(search.toLowerCase()) ||
      (cause.description || '').toLowerCase().includes(search.toLowerCase())
    return matchCat && matchSearch
  })

  return (
    <div className="min-h-screen bg-background pb-28">
      {/* Nav */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-2xl mx-auto px-4 flex items-center justify-between h-14">
          <Link href="/" className="text-lg font-extrabold text-primary">Unitia</Link>
          {user?.role !== 'CUSTOMER' && (
            <Link href="/register?role=RESTAURANT" className="text-xs font-bold text-muted hover:text-primary transition-colors">
              Sumar mi restaurante →
            </Link>
          )}
        </div>
      </nav>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {/* Title */}
        <div className="mb-5">
          <h1 className="text-2xl font-extrabold text-[#2D2D2D] mb-1">Apoya una causa</h1>
          <p className="text-sm text-muted font-medium">
            Cada pedido que hagas dona un porcentaje a la causa que elijas.
          </p>
        </div>

        {/* Cause code input */}
        <form onSubmit={handleCodeSubmit} className="mb-4">
          <div className="flex gap-2">
            <input
              type="text"
              className="input flex-1 text-sm"
              placeholder="Tengo un código de causa..."
              value={codeInput}
              onChange={e => { setCodeInput(e.target.value); setCodeError('') }}
            />
            <button
              type="submit"
              className="btn btn-primary btn-sm px-4 flex items-center gap-1.5"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-4 h-4">
                <polyline points="20 6 9 17 4 12" />
              </svg>
              Ir
            </button>
          </div>
          {codeError && (
            <p className="text-red-500 text-xs mt-1.5 font-medium">{codeError}</p>
          )}
        </form>

        {/* Category chips */}
        <div className="flex gap-2 overflow-x-auto pb-2 mb-4 -mx-1 px-1" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`flex-shrink-0 text-xs font-bold px-4 py-2 rounded-full border-2 transition-all ${
                category === cat
                  ? 'bg-primary text-white border-primary'
                  : 'bg-white text-muted border-border hover:border-primary hover:text-primary'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative mb-5">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-muted pointer-events-none">
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            type="text"
            className="input pl-10 text-sm"
            placeholder="Buscar causa..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        {/* Causes list */}
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="card text-center py-10">
            <p className="text-4xl mb-3">❤️</p>
            <p className="text-muted font-medium text-sm">
              {causes.length === 0 ? 'No hay causas disponibles por el momento.' : 'No encontramos causas con esos filtros.'}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map(cause => {
              const isFavorite = favoriteCauseId && cause.id === favoriteCauseId
              return (
                <Link
                  key={cause.id}
                  href={`/c/${cause.slug}`}
                  className="card hover:shadow-md transition-all group block"
                  style={{ borderWidth: 2, borderColor: isFavorite ? '#FF7A1A' : 'transparent' }}
                >
                  <div className="flex items-start gap-4">
                    {cause.logo ? (
                      <img src={cause.logo} alt={cause.name} className="w-16 h-16 rounded-2xl object-cover flex-shrink-0" />
                    ) : (
                      <div className="w-16 h-16 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-2xl">❤️</div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-extrabold text-[#2D2D2D]">{cause.name}</p>
                        {isFavorite && (
                          <span className="text-xs font-bold text-primary bg-primary-bg px-2 py-0.5 rounded-full flex-shrink-0">Tu causa ❤️</span>
                        )}
                      </div>
                      {cause.description && (
                        <p className="text-xs text-muted line-clamp-2 mt-1 leading-relaxed">{cause.description}</p>
                      )}
                    </div>
                  </div>

                  <div className="mt-3">
                    {cause.targetAmount > 0 ? (
                      <>
                        <div className="h-2 bg-border rounded-full overflow-hidden mb-1.5">
                          <div
                            className="h-full bg-primary rounded-full"
                            style={{ width: `${Math.min(100, ((cause.totalRaised || 0) / cause.targetAmount) * 100)}%` }}
                          />
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-primary font-bold">{formatCurrency(cause.totalRaised || 0)} recaudados</span>
                          <span className="text-xs text-muted font-medium">meta {formatCurrency(cause.targetAmount)}</span>
                        </div>
                      </>
                    ) : (
                      <span className="text-sm text-primary font-bold">{formatCurrency(cause.totalRaised || 0)} recaudados</span>
                    )}
                  </div>

                  <div className="flex items-center justify-end mt-3 pt-3 border-t border-border">
                    <span className="text-xs font-bold text-primary group-hover:underline">Ver causa →</span>
                  </div>
                </Link>
              )
            })}
          </div>
        )}

      </main>

      {/* Floating ranking button */}
      <Link
        href="/causas/ranking"
        className="fixed bottom-24 right-4 z-40 flex items-center gap-2 bg-white border-2 border-primary text-primary font-extrabold text-sm px-4 py-3 rounded-2xl shadow-lg hover:bg-primary hover:text-white transition-all"
        style={{ boxShadow: '0 4px 20px rgba(255,122,26,0.25)' }}
      >
        <span>🏆</span>
        <span>Ranking</span>
      </Link>

    </div>
  )
}

export default function CausasPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <CausasPageInner />
    </Suspense>
  )
}
