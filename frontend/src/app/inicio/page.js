'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { getUser } from '@/lib/auth'
import { api } from '@/lib/api'
import { useCause } from '@/context/CauseContext'
import { useLocale } from '@/context/LocaleContext'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

export default function InicioPage() {
  const router = useRouter()
  const { t } = useLocale()
  const { selectedCause, openSelector } = useCause()
  const [user, setUser] = useState(null)
  const [causes, setCauses] = useState([])
  const [restaurants, setRestaurants] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const u = getUser()
    if (!u || u.role !== 'CUSTOMER') {
      router.push('/login')
      return
    }
    setUser(u)

    Promise.all([
      api.public.getCauses(),
      api.public.getRestaurants(),
    ])
      .then(([causesRes, restaurantsRes]) => {
        setCauses(causesRes.data || [])
        setRestaurants(restaurantsRes.data || [])
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  const firstName = user.name?.split(' ')[0] || user.name

  return (
    <div className="min-h-screen bg-background pb-36">
      {/* Header */}
      <div className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 h-14 flex items-center justify-between">
          <span className="text-lg font-extrabold text-primary">{t('common.appName')}</span>
          <Link href="/cuenta" className="w-9 h-9 rounded-full bg-primary-bg flex items-center justify-center text-primary hover:bg-primary/10 transition-colors">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
          </Link>
        </div>
      </div>

      <main className="max-w-xl mx-auto px-4 py-6 space-y-7">
        {/* Greeting */}
        <div>
          <h1 className="text-2xl font-extrabold text-[#2D2D2D]">
            Hola, {firstName} 👋
          </h1>
          <p className="text-sm text-muted font-medium mt-1">
            Pide en restaurantes que apoyan causas reales.
          </p>
          <div className="flex items-center gap-1.5 mt-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3.5 h-3.5 text-green-600 flex-shrink-0">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <p className="text-xs font-bold text-green-700">Precios idénticos al restaurante</p>
          </div>
        </div>

        {/* Causa seleccionada */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-extrabold text-[#2D2D2D]">{t('cause.today')}</h2>
            <button onClick={openSelector} className="text-xs text-muted font-bold hover:text-primary">{t('cause.change')}</button>
          </div>

          {selectedCause ? (
            <button
              onClick={openSelector}
              className="w-full card block hover:shadow-md transition-all text-left"
              style={{ borderWidth: 2, borderColor: '#F27F0D' }}
            >
              <div className="flex items-center gap-3">
                {selectedCause.logo ? (
                  <img src={selectedCause.logo} alt={selectedCause.name} className="w-14 h-14 rounded-2xl object-cover flex-shrink-0" />
                ) : (
                  <div className="w-14 h-14 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-2xl">❤️</div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="font-extrabold text-[#2D2D2D]">{selectedCause.name}</p>
                    <span className="text-xs font-bold text-primary bg-primary-bg px-2 py-0.5 rounded-full flex-shrink-0">{t('cause.selected')}</span>
                  </div>
                  {selectedCause.description && (
                    <p className="text-xs text-muted line-clamp-2 mt-0.5 leading-relaxed">{selectedCause.description}</p>
                  )}
                  <div className="mt-2">
                    {selectedCause.targetAmount > 0 ? (
                      <>
                        <div className="h-1.5 bg-border rounded-full overflow-hidden">
                          <div
                            className="h-full bg-primary rounded-full"
                            style={{ width: `${Math.min(100, ((selectedCause.totalRaised || 0) / selectedCause.targetAmount) * 100)}%` }}
                          />
                        </div>
                        <div className="flex items-center justify-between mt-1">
                          <p className="text-xs text-primary font-bold">{formatCurrency(selectedCause.totalRaised || 0)} recaudados</p>
                          <p className="text-xs text-muted font-medium">meta {formatCurrency(selectedCause.targetAmount)}</p>
                        </div>
                      </>
                    ) : (
                      <p className="text-xs text-primary font-bold">{formatCurrency(selectedCause.totalRaised || 0)} recaudados</p>
                    )}
                  </div>
                </div>
              </div>
            </button>
          ) : (
            <button
              onClick={openSelector}
              className="w-full card border-2 border-dashed border-primary/40 hover:border-primary transition-all text-center py-5"
            >
              <p className="text-2xl mb-1">❤️</p>
              <p className="font-bold text-primary text-sm">{t('cause.choose')}</p>
              <p className="text-xs text-muted mt-0.5">{t('cause.chooseSubtitle')}</p>
            </button>
          )}
        </section>

        {/* Featured Causes */}
        {causes.length > 0 && (
          <section>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-base font-extrabold text-[#2D2D2D]">{t('cause.active')}</h2>
              <Link href="/causas" className="text-sm text-primary font-bold hover:underline">{t('cause.all')}</Link>
            </div>
            <div className="flex gap-3 overflow-x-auto pb-2 -mx-1 px-1" style={{ scrollbarWidth: 'none' }}>
              {causes.slice(0, 5).map(cause => (
                <Link
                  key={cause.id}
                  href={`/c/${cause.slug}`}
                  className="flex-shrink-0 w-44 card p-3 hover:shadow-md transition-all hover:border-primary text-left block"
                  style={{ borderWidth: 2, borderColor: selectedCause?.id === cause.id ? '#F27F0D' : 'transparent' }}
                >
                  {cause.logo ? (
                    <img src={cause.logo} alt={cause.name} className="w-full h-24 rounded-xl object-cover mb-2" />
                  ) : (
                    <div className="w-full h-24 rounded-xl bg-primary-bg flex items-center justify-center text-3xl mb-2">❤️</div>
                  )}
                  <p className="font-bold text-[#2D2D2D] text-sm line-clamp-2 leading-snug">{cause.name}</p>
                  <div className="mt-2">
                    {cause.targetAmount > 0 ? (
                      <>
                        <div className="h-1.5 bg-border rounded-full overflow-hidden">
                          <div className="h-full bg-primary rounded-full" style={{ width: `${Math.min(100, ((cause.totalRaised || 0) / cause.targetAmount) * 100)}%` }} />
                        </div>
                        <p className="text-xs text-primary font-bold mt-1">{formatCurrency(cause.totalRaised || 0)}</p>
                        <p className="text-[10px] text-muted font-medium">de {formatCurrency(cause.targetAmount)}</p>
                      </>
                    ) : (
                      <p className="text-xs text-primary font-bold">{formatCurrency(cause.totalRaised || 0)} recaudados</p>
                    )}
                  </div>
                  <p className="text-[10px] text-primary font-bold mt-2">Ver más →</p>
                </Link>
              ))}
            </div>
          </section>
        )}

        {/* Restaurants */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-extrabold text-[#2D2D2D]">Restaurantes</h2>
            <Link href="/restaurantes" className="text-sm text-primary font-bold hover:underline">{t('common.seeAll')}</Link>
          </div>
          {restaurants.length === 0 ? (
            <div className="card text-center py-8">
              <p className="text-3xl mb-2">🍽</p>
              <p className="text-muted font-medium text-sm">{t('restaurant.noRestaurants')}</p>
            </div>
          ) : (
            <div className="space-y-3">
              {restaurants.map(restaurant => (
                <div key={restaurant.id} className="card flex items-center gap-4">
                  {restaurant.logo ? (
                    <img src={restaurant.logo} alt={restaurant.name} className="w-14 h-14 rounded-2xl object-cover flex-shrink-0" />
                  ) : (
                    <div className="w-14 h-14 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-2xl">🍽</div>
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-extrabold text-[#2D2D2D] text-sm">{restaurant.name}</p>
                    {restaurant.description && (
                      <p className="text-xs text-muted line-clamp-1 mt-0.5">{restaurant.description}</p>
                    )}
                    <p className="text-xs text-primary font-bold mt-1">
                      ❤️ {restaurant.donationPercentage}% {t('restaurant.donatesTo')}
                    </p>
                  </div>
                  <Link
                    href={`/r/${restaurant.slug}${selectedCause ? `?cause=${selectedCause.slug}` : ''}`}
                    className="btn btn-primary btn-sm flex-shrink-0 text-xs px-4"
                  >
                    {t('restaurant.order')}
                  </Link>
                </div>
              ))}
            </div>
          )}
        </section>
      </main>

    </div>
  )
}
