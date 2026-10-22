'use client'
import { useEffect, useState, Suspense } from 'react'
import { useSearchParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser } from '@/lib/auth'
import { useCause } from '@/context/CauseContext'
import { useLocale } from '@/context/LocaleContext'
import CauseSelectorModal from '@/components/CauseSelectorModal'
import AddressAutocomplete from '@/components/AddressAutocomplete'

function groupByCategory(items) {
  const map = {}
  for (const item of items) {
    const cat = item.category || 'Sin categoría'
    if (!map[cat]) map[cat] = []
    map[cat].push(item)
  }
  return map
}

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function RestaurantOrderPageInner({ slug }) {
  const searchParams = useSearchParams()
  const causeSlugParam = searchParams.get('cause')
  const router = useRouter()
  const { t } = useLocale()

  // Global cause context
  const { selectedCause: globalCause, openSelector, selectCause: setGlobalCause, allCauses } = useCause()
  const [localCause, setLocalCause] = useState(null) // cause for this order specifically

  const [restaurant, setRestaurant] = useState(null)
  const [loading, setLoading] = useState(true)
  const [cart, setCart] = useState({})
  const [step, setStep] = useState('menu') // 'menu' | 'checkout'
  const [orderType, setOrderType] = useState('DELIVERY') // 'DELIVERY' | 'PICKUP'
  const [form, setForm] = useState({ customerName: '', customerEmail: '', customerPhone: '', notes: '', deliveryAddress: '', paymentMethod: 'cash', proofUrl: '' })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [loggedCustomer, setLoggedCustomer] = useState(null)
  const [savedAddresses, setSavedAddresses] = useState([])
  const [deliveryFee, setDeliveryFee] = useState(0)
  const [calcingFee, setCalcingFee] = useState(false)
  const [proofFile, setProofFile] = useState(null)
  const [uploadingProof, setUploadingProof] = useState(false)

  // The cause for this order = localCause override || globalCause
  const selectedCause = localCause || globalCause

  useEffect(() => {
    const u = getUser()
    if (u?.role === 'CUSTOMER') {
      api.customer.getProfile()
        .then(res => {
          setLoggedCustomer(res.data)
          const addrs = res.data.savedAddresses || []
          setSavedAddresses(addrs)
          setForm(f => ({
            ...f,
            customerName: res.data.name || u.name || '',
            customerEmail: res.data.email || u.email || '',
            customerPhone: res.data.phone || '',
            deliveryAddress: addrs[0]?.address || '',
          }))
        })
        .catch(() => {})
    }

    api.public.getRestaurant(slug)
      .then(res => {
        setRestaurant(res.data)
        // Preselect cause from URL param
        if (causeSlugParam && allCauses.length > 0) {
          const found = allCauses.find(c => c.slug === causeSlugParam)
          if (found) setLocalCause(found)
        }
      })
      .catch(() => setRestaurant(null))
      .finally(() => setLoading(false))
  }, [slug, causeSlugParam, allCauses])

  // Calculate delivery fee using browser geolocation
  async function calcDeliveryFee() {
    if (!restaurant?.latitude || !restaurant?.longitude || !restaurant?.deliveryTiers?.length) return
    setCalcingFee(true)
    try {
      const pos = await new Promise((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 8000 })
      )
      const distKm = haversineKm(pos.coords.latitude, pos.coords.longitude, restaurant.latitude, restaurant.longitude)
      let fee = 0
      for (const tier of restaurant.deliveryTiers) {
        if (distKm <= tier.maxKm) { fee = tier.price; break }
      }
      setDeliveryFee(fee)
    } catch {
      setDeliveryFee(0)
    } finally {
      setCalcingFee(false)
    }
  }

  useEffect(() => {
    if (restaurant) calcDeliveryFee()
  }, [restaurant])

  function addItem(id) { setCart(c => ({ ...c, [id]: (c[id] || 0) + 1 })) }
  function removeItem(id) {
    setCart(c => {
      const next = { ...c }
      if (next[id] <= 1) delete next[id]
      else next[id]--
      return next
    })
  }

  const cartItems = restaurant?.menuItems?.filter(i => cart[i.id]) || []
  const subtotal = cartItems.reduce((s, i) => s + i.price * cart[i.id], 0)
  const donationAmount = parseFloat((subtotal * (restaurant?.donationPercentage / 100 || 0)).toFixed(2))
  const cartCount = Object.values(cart).reduce((s, n) => s + n, 0)
  const total = subtotal + deliveryFee

  async function handleUploadProof(file) {
    if (!file) return
    setUploadingProof(true)
    try {
      // Convert to base64 and upload
      const reader = new FileReader()
      reader.onload = async (e) => {
        const base64 = e.target.result
        // Store as data URL for now (in prod, upload to Cloudinary/S3)
        setForm(f => ({ ...f, proofUrl: base64 }))
        setProofFile(file)
        setUploadingProof(false)
      }
      reader.readAsDataURL(file)
    } catch {
      setUploadingProof(false)
    }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!selectedCause) {
      openSelector()
      return
    }
    setSubmitting(true)
    setError('')
    try {
      const orderPayload = {
        restaurantId: restaurant.id,
        causeId: selectedCause.id,
        orderType,
        customerName: form.customerName,
        customerEmail: form.customerEmail,
        customerPhone: form.customerPhone,
        notes: form.notes,
        deliveryAddress: orderType === 'DELIVERY' ? form.deliveryAddress : undefined,
        deliveryFee: orderType === 'DELIVERY' ? deliveryFee : 0,
        paymentMethod: form.paymentMethod,
        proofUrl: form.paymentMethod === 'transfer' ? form.proofUrl : undefined,
        items: Object.entries(cart).map(([menuItemId, quantity]) => ({ menuItemId, quantity })),
      }
      if (loggedCustomer?.id) orderPayload.customerId = loggedCustomer.id

      const result = await api.orders.create(orderPayload)
      sessionStorage.setItem('unitia_last_order', JSON.stringify(result.data))
      router.push(`/pedido/${result.data.id}/impacto`)
    } catch (err) {
      setError(err.message || 'Error al enviar el pedido')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (!restaurant) return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="text-center">
        <p className="text-5xl mb-4">🍽</p>
        <p className="text-2xl font-extrabold text-[#2D2D2D] mb-2">Restaurante no encontrado</p>
        <Link href="/" className="text-primary font-bold hover:underline text-sm">Volver al inicio</Link>
      </div>
    </div>
  )

  const grouped = groupByCategory(restaurant.menuItems || [])

  return (
    <div className="min-h-screen bg-background pb-32">
      {/* Header */}
      <div className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 py-4 flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors flex-shrink-0"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 12H5m7-7-7 7 7 7" />
            </svg>
          </button>
          {restaurant.logo ? (
            <img src={restaurant.logo} alt={restaurant.name} className="w-11 h-11 rounded-2xl object-cover flex-shrink-0" />
          ) : (
            <div className="w-11 h-11 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-xl">🍽</div>
          )}
          <div className="flex-1 min-w-0">
            <h1 className="font-extrabold text-[#2D2D2D] truncate">{restaurant.name}</h1>
            {selectedCause && (
              <p className="text-xs text-primary font-bold truncate">
                ❤️ {restaurant.donationPercentage}% → {selectedCause.name}
              </p>
            )}
          </div>
          <button
            onClick={openSelector}
            className="text-xs text-muted font-bold hover:text-primary transition-colors flex-shrink-0 flex items-center gap-1"
          >
            {selectedCause ? (
              <><span className="text-[10px]">❤️</span> {t('common.changeCause')}</>
            ) : (
              <span className="text-primary font-bold">{t('common.selectCause')}</span>
            )}
          </button>
        </div>
      </div>

      {step === 'menu' && (
        <div className="max-w-xl mx-auto px-4 py-5">
          {/* Selected cause banner */}
          {selectedCause ? (
            <button
              onClick={openSelector}
              className="w-full flex items-center gap-3 card mb-5 hover:shadow-md transition-all text-left"
            >
              {selectedCause.logo ? (
                <img src={selectedCause.logo} alt="" className="w-12 h-12 rounded-2xl object-cover flex-shrink-0" />
              ) : (
                <div className="w-12 h-12 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-xl">❤️</div>
              )}
              <div className="flex-1 min-w-0">
                <p className="text-xs text-muted font-semibold">{t('restaurant.supporting')}</p>
                <p className="font-extrabold text-primary text-sm">{selectedCause.name}</p>
                <p className="text-xs text-muted">{restaurant.donationPercentage}% de tu pedido irá a esta causa</p>
              </div>
              <span className="text-xs text-muted font-bold flex-shrink-0">{t('restaurant.changeCause')} →</span>
            </button>
          ) : (
            <button
              onClick={openSelector}
              className="w-full card mb-5 border-2 border-dashed border-primary/40 hover:border-primary transition-all text-center py-4"
            >
              <p className="font-bold text-primary text-sm">❤️ {t('restaurant.chooseCause')}</p>
              <p className="text-xs text-muted mt-0.5">{t('restaurant.chooseCauseSubtitle', { percent: restaurant.donationPercentage })}</p>
            </button>
          )}

          {/* Price guarantee */}
          <div className="flex items-center gap-2 mb-5 px-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 text-green-600 flex-shrink-0">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <p className="text-xs font-bold text-green-700">Precios idénticos al restaurante</p>
          </div>

          {Object.entries(grouped).map(([cat, items]) => (
            <div key={cat} className="mb-5">
              <h2 className="font-extrabold text-muted text-xs uppercase tracking-widest mb-3 px-1">{cat}</h2>
              <div className="space-y-2">
                {items.map(item => (
                  <div key={item.id} className="card flex items-center gap-3 p-4">
                    {item.imageUrl ? (
                      <img src={item.imageUrl} alt={item.name} className="w-16 h-16 rounded-2xl object-cover flex-shrink-0" />
                    ) : (
                      <div className="w-16 h-16 rounded-2xl bg-background flex items-center justify-center flex-shrink-0 text-2xl">🍽</div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-[#2D2D2D] text-sm">{item.name}</p>
                      {item.description && <p className="text-xs text-muted line-clamp-2 mt-0.5 leading-relaxed">{item.description}</p>}
                      <p className="font-extrabold text-primary mt-1">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      {cart[item.id] ? (
                        <>
                          <button onClick={() => removeItem(item.id)} className="w-8 h-8 rounded-full border-2 border-border flex items-center justify-center text-[#2D2D2D] hover:border-primary hover:text-primary font-extrabold text-lg leading-none transition-colors">−</button>
                          <span className="w-6 text-center font-extrabold text-sm text-[#2D2D2D]">{cart[item.id]}</span>
                        </>
                      ) : null}
                      <button onClick={() => addItem(item.id)} className="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center hover:bg-primary-dark font-extrabold text-lg leading-none transition-colors shadow-sm shadow-primary/30">+</button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {step === 'checkout' && (
        <div className="max-w-xl mx-auto px-4 py-5">
          <button onClick={() => setStep('menu')} className="text-sm text-muted font-bold hover:text-primary mb-5 flex items-center gap-1 transition-colors">
            {t('order.backToMenu')}
          </button>
          <h2 className="text-xl font-extrabold text-[#2D2D2D] mb-4">{t('order.title')}</h2>

          {/* Order summary */}
          <div className="card mb-4">
            {cartItems.map(item => (
              <div key={item.id} className="flex justify-between py-2.5 text-sm border-b border-border last:border-0">
                <span className="text-muted font-medium">{item.name} × {cart[item.id]}</span>
                <span className="font-bold text-[#2D2D2D]">{formatCurrency(item.price * cart[item.id])}</span>
              </div>
            ))}
            <div className="flex justify-between pt-3 text-sm">
              <span className="text-muted font-medium">{t('order.subtotal')}</span>
              <span className="font-extrabold text-[#2D2D2D]">{formatCurrency(subtotal)}</span>
            </div>
            {/* Delivery fee */}
            {restaurant.deliveryTiers?.length > 0 && (
              <div className="flex justify-between pt-2 text-sm">
                <span className="text-muted font-medium">{t('order.delivery')}</span>
                <span className="font-bold text-[#2D2D2D]">
                  {calcingFee ? t('order.deliveryCalculating') : deliveryFee > 0 ? formatCurrency(deliveryFee) : t('order.deliveryFree')}
                </span>
              </div>
            )}
            {selectedCause && (
              <div className="flex justify-between pt-2 text-sm">
                <span className="text-primary font-bold">❤️ {selectedCause.name}</span>
                <span className="text-primary font-extrabold">{formatCurrency(donationAmount)}</span>
              </div>
            )}
            <div className="flex justify-between pt-3 border-t border-border mt-2">
              <span className="font-extrabold text-[#2D2D2D]">{t('order.total')}</span>
              <span className="font-extrabold text-[#2D2D2D] text-lg">{formatCurrency(total)}</span>
            </div>
          </div>

          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Order type selector */}
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setOrderType('DELIVERY')}
                className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                  orderType === 'DELIVERY' ? 'border-primary bg-primary-bg' : 'border-border bg-white hover:border-primary/40'
                }`}
              >
                <span className="text-2xl">🛵</span>
                <span className={`font-extrabold text-sm ${orderType === 'DELIVERY' ? 'text-primary' : 'text-[#2D2D2D]'}`}>A domicilio</span>
                <span className="text-xs text-muted font-medium">Te lo llevamos</span>
              </button>
              <button
                type="button"
                onClick={() => setOrderType('PICKUP')}
                className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${
                  orderType === 'PICKUP' ? 'border-primary bg-primary-bg' : 'border-border bg-white hover:border-primary/40'
                }`}
              >
                <span className="text-2xl">🏪</span>
                <span className={`font-extrabold text-sm ${orderType === 'PICKUP' ? 'text-primary' : 'text-[#2D2D2D]'}`}>Para recoger</span>
                <span className="text-xs text-muted font-medium">Lo recoges tú</span>
              </button>
            </div>

            {/* Customer data */}
            <div className="card space-y-4">
              <h3 className="font-extrabold text-[#2D2D2D]">{t('order.yourData')}</h3>

              {loggedCustomer && (
                <div className="flex items-center gap-2 p-3 bg-primary-bg rounded-2xl border border-primary/20">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 text-primary flex-shrink-0">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                  </svg>
                  <p className="text-xs text-primary font-bold">{t('order.linkedToAccount')}</p>
                </div>
              )}

              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.name')} *</label>
                <input className="input" value={form.customerName} onChange={e => setForm(f => ({ ...f, customerName: e.target.value }))} required />
              </div>
              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.emailImpact')}</label>
                <input type="email" className="input" value={form.customerEmail} onChange={e => setForm(f => ({ ...f, customerEmail: e.target.value }))} />
              </div>
              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.phone')}</label>
                <input type="tel" className="input" value={form.customerPhone} onChange={e => setForm(f => ({ ...f, customerPhone: e.target.value }))} />
              </div>
              {orderType === 'DELIVERY' && (
                <div>
                  <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.address')}</label>
                  {savedAddresses.length > 0 && (
                    <div className="flex gap-2 mb-2 flex-wrap">
                      {savedAddresses.map((addr, i) => (
                        <button
                          key={i}
                          type="button"
                          onClick={() => setForm(f => ({ ...f, deliveryAddress: addr.address }))}
                          className={`text-xs font-bold px-3 py-1.5 rounded-xl border-2 transition-all ${
                            form.deliveryAddress === addr.address
                              ? 'bg-primary text-white border-primary'
                              : 'bg-white text-muted border-border hover:border-primary hover:text-primary'
                          }`}
                        >
                          {addr.label === 'Casa' ? '🏠' : addr.label === 'Trabajo' ? '💼' : '📍'} {addr.label}
                        </button>
                      ))}
                    </div>
                  )}
                  <AddressAutocomplete
                    value={form.deliveryAddress}
                    onChange={val => setForm(f => ({ ...f, deliveryAddress: val }))}
                    placeholder={t('order.addressPlaceholder')}
                  />
                </div>
              )}
              {orderType === 'PICKUP' && (
                <div className="p-3 bg-primary-bg rounded-2xl border border-primary/20 flex items-center gap-2">
                  <span className="text-lg">🏪</span>
                  <p className="text-xs text-primary font-bold">Pasarás a recoger tu pedido en el restaurante</p>
                </div>
              )}
              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.notes')}</label>
                <textarea className="input resize-none" rows={2} value={form.notes} onChange={e => setForm(f => ({ ...f, notes: e.target.value }))} />
              </div>
            </div>

            {/* Payment method */}
            <div className="card space-y-4">
              <h3 className="font-extrabold text-[#2D2D2D]">{t('order.payment.title')}</h3>

              <div className="flex gap-2">
                {['cash', 'transfer'].map(method => (
                  <button
                    key={method}
                    type="button"
                    onClick={() => setForm(f => ({ ...f, paymentMethod: method }))}
                    className={`flex-1 py-3 px-3 rounded-xl border-2 text-sm font-bold transition-all ${
                      form.paymentMethod === method
                        ? 'border-primary bg-primary-bg text-primary'
                        : 'border-border text-muted hover:border-primary/40'
                    }`}
                  >
                    {method === 'cash' ? `💵 ${t('order.payment.cash')}` : `🏦 ${t('order.payment.transfer')}`}
                  </button>
                ))}
              </div>

              {form.paymentMethod === 'cash' && (
                <p className="text-sm text-muted bg-background rounded-xl px-3 py-2 font-medium">
                  💵 {t('order.payment.cashNote')}
                </p>
              )}

              {form.paymentMethod === 'transfer' && (
                <div className="space-y-3">
                  <p className="text-sm text-muted bg-background rounded-xl px-3 py-2 font-medium">
                    🏦 {t('order.payment.transferNote')}
                  </p>
                  <div>
                    <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">{t('order.payment.transferProof')} *</label>
                    {form.proofUrl ? (
                      <div className="flex items-center gap-3">
                        <img src={form.proofUrl} alt="comprobante" className="w-16 h-16 rounded-xl object-cover border border-border" />
                        <div className="flex-1">
                          <p className="text-sm font-bold text-green-600">{t('order.payment.proofUploaded')}</p>
                          <button
                            type="button"
                            onClick={() => { setForm(f => ({ ...f, proofUrl: '' })); setProofFile(null) }}
                            className="text-xs text-red-500 hover:underline mt-1"
                          >
                            Cambiar imagen
                          </button>
                        </div>
                      </div>
                    ) : (
                      <label className="flex flex-col items-center justify-center w-full h-28 border-2 border-dashed border-border rounded-2xl cursor-pointer hover:border-primary transition-colors bg-background">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-8 h-8 text-muted mb-2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 0 1 2.828 0L16 16" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M14 14l1.586-1.586a2 2 0 0 1 2.828 0L20 14" />
                          <rect x="2" y="2" width="20" height="20" rx="4" />
                          <circle cx="8.5" cy="8.5" r="1.5" />
                        </svg>
                        <span className="text-sm text-muted font-medium">
                          {uploadingProof ? 'Subiendo...' : t('order.payment.uploadProof')}
                        </span>
                        <input
                          type="file"
                          accept="image/*"
                          className="hidden"
                          onChange={e => handleUploadProof(e.target.files[0])}
                          disabled={uploadingProof}
                        />
                      </label>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Cause selection if missing */}
            {!selectedCause && (
              <div className="p-4 bg-amber-50 border-2 border-amber-200 rounded-2xl text-center">
                <p className="text-amber-800 font-bold text-sm mb-2">Falta elegir una causa ❤️</p>
                <button type="button" onClick={openSelector} className="btn btn-primary btn-sm">
                  {t('common.selectCause')}
                </button>
              </div>
            )}

            <button
              type="submit"
              className="btn btn-primary w-full"
              disabled={submitting || (form.paymentMethod === 'transfer' && !form.proofUrl)}
            >
              {submitting ? t('order.sending') : t('order.sendOrder', { total: formatCurrency(total) })}
            </button>
          </form>
        </div>
      )}

      {/* Floating cart bar */}
      {step === 'menu' && cartCount > 0 && (
        <div className="fixed bottom-[120px] left-0 right-0 px-4 z-50">
          <div className="max-w-xl mx-auto">
            <button onClick={() => setStep('checkout')} className="btn btn-primary w-full flex items-center justify-between">
              <span className="bg-white/20 rounded-full w-7 h-7 flex items-center justify-center text-sm font-extrabold">{cartCount}</span>
              <span>{t('order.viewOrder')}</span>
              <span>{formatCurrency(subtotal)}</span>
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function RestaurantOrderPage({ params }) {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <RestaurantOrderPageInner slug={params.slug} />
    </Suspense>
  )
}
