'use client'
import { useEffect, useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser } from '@/lib/auth'

const CATEGORIES = [
  { label: 'Todos', value: 'Todos' },
  { label: '🌮 Mexicana', value: 'Mexicana' },
  { label: '🍔 Hamburguesas', value: 'Hamburguesas' },
  { label: '🍕 Pizza', value: 'Pizza' },
  { label: '🍣 Sushi', value: 'Sushi' },
  { label: '🍜 Asiática', value: 'Asiática' },
  { label: '🥗 Saludable', value: 'Saludable' },
  { label: '🍗 Pollo', value: 'Pollo' },
  { label: '🥪 Sandwiches', value: 'Sandwiches' },
  { label: '🍰 Postres', value: 'Postres' },
  { label: '☕ Café', value: 'Café' },
]

function RestaurantesPageInner() {
  const searchParams = useSearchParams()
  const causeParam = searchParams.get('cause')

  const [restaurants, setRestaurants] = useState([])
  const [loading, setLoading] = useState(true)
  const [category, setCategory] = useState('Todos')
  const [search, setSearch] = useState('')
  const [favCauseSlug, setFavCauseSlug] = useState(causeParam || null)

  useEffect(() => {
    const u = getUser()
    if (u?.role === 'CUSTOMER') {
      api.customer.getProfile()
        .then(res => {
          const profile = res.data
          if (profile?.favoriteCauseId && !causeParam) {
            // Get causes to find slug
            api.public.getCauses()
              .then(causesRes => {
                const favCause = (causesRes.data || []).find(c => c.id === profile.favoriteCauseId)
                if (favCause) setFavCauseSlug(favCause.slug)
              })
              .catch(() => {})
          }
        })
        .catch(() => {})
    }

    api.public.getRestaurants()
      .then(res => setRestaurants(res.data || []))
      .catch(() => setRestaurants([]))
      .finally(() => setLoading(false))
  }, [causeParam])

  const filtered = restaurants.filter(r => {
    const matchCat = category === 'Todos' || (r.category || '') === category
    const matchSearch = !search ||
      r.name.toLowerCase().includes(search.toLowerCase()) ||
      (r.description || '').toLowerCase().includes(search.toLowerCase())
    return matchCat && matchSearch
  })

  return (
    <div className="min-h-screen bg-background pb-28">
      {/* Nav */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14 gap-3">
          <Link href="/inicio" className="text-muted hover:text-primary transition-colors">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 12H5m7-7-7 7 7 7" />
            </svg>
          </Link>
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Restaurantes</h1>
        </div>
      </nav>

      <main className="max-w-xl mx-auto px-4 py-5">
        {/* Category chips */}
        <div className="flex gap-2 overflow-x-auto pb-2 mb-4 -mx-1 px-1" style={{ scrollbarWidth: 'none' }}>
          {CATEGORIES.map(cat => (
            <button
              key={cat.value}
              onClick={() => setCategory(cat.value)}
              className={`flex-shrink-0 text-xs font-bold px-4 py-2 rounded-full border-2 transition-all ${
                category === cat.value
                  ? 'bg-primary text-white border-primary'
                  : 'bg-white text-muted border-border hover:border-primary hover:text-primary'
              }`}
            >
              {cat.label}
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
            placeholder="Buscar restaurante..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="card text-center py-12 mt-4">
            <p className="text-4xl mb-3">🍽</p>
            <p className="text-[#2D2D2D] font-bold">Sin restaurantes por ahora</p>
            <p className="text-muted text-sm mt-1">Pronto habrá restaurantes Unitia cerca tuyo.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map(restaurant => {
              const href = `/r/${restaurant.slug}${favCauseSlug ? `?cause=${favCauseSlug}` : ''}`
              return (
                <Link
                  key={restaurant.id}
                  href={href}
                  className="card flex items-center gap-4 hover:shadow-md hover:border-primary transition-all"
                  style={{ borderWidth: 2, borderColor: 'transparent' }}
                >
                  {restaurant.logo ? (
                    <img src={restaurant.logo} alt={restaurant.name} className="w-16 h-16 rounded-2xl object-cover flex-shrink-0" />
                  ) : (
                    <div className="w-16 h-16 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-3xl">🍽</div>
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-extrabold text-[#2D2D2D]">{restaurant.name}</p>
                    {restaurant.description && (
                      <p className="text-sm text-muted line-clamp-2 mt-0.5 leading-relaxed">{restaurant.description}</p>
                    )}
                    <div className="flex items-center gap-2 mt-2">
                      <span className="inline-flex items-center gap-1 text-xs font-bold text-primary bg-primary-bg px-2 py-0.5 rounded-full">
                        ❤️ {restaurant.donationPercentage}% dona
                      </span>
                      {restaurant.address && (
                        <span className="text-xs text-muted truncate">{restaurant.address}</span>
                      )}
                    </div>
                  </div>
                  <span className="text-primary font-extrabold text-lg flex-shrink-0">→</span>
                </Link>
              )
            })}
          </div>
        )}
      </main>

    </div>
  )
}

export default function RestaurantesPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <RestaurantesPageInner />
    </Suspense>
  )
}
