'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { saveTokens, saveUser } from '@/lib/auth'

function redirectForRole(role) {
  if (role === 'CUSTOMER') return '/inicio'
  if (role === 'RESTAURANT') return '/restaurant/dashboard'
  if (role === 'CAUSE') return '/cause/dashboard'
  return '/'
}

function LoginForm() {
  const router = useRouter()
  const params = useSearchParams()
  const callbackUrl = params.get('callbackUrl')

  const [mode, setMode] = useState('customer') // 'customer' | 'business'
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const result = await api.auth.login({ email: form.email, password: form.password })
      saveTokens(result.data.accessToken, result.data.refreshToken)
      saveUser(result.data.user)
      router.push(callbackUrl || redirectForRole(result.data.user.role))
    } catch (err) {
      setError(err.message || 'Email o contraseña incorrectos')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ background: 'linear-gradient(145deg, #F27F0D 0%, #D96A00 100%)' }}>
      <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32 pointer-events-none" />
      <div className="absolute top-1/4 left-0 w-48 h-48 bg-white/5 rounded-full blur-2xl -ml-24 pointer-events-none" />

      {/* Hero */}
      <div className="relative flex-1 flex flex-col items-center justify-end pb-10 pt-16 px-6 text-center">
        <div className="w-20 h-20 bg-white rounded-2xl shadow-2xl flex items-center justify-center mb-6">
          <svg viewBox="0 0 24 24" fill="none" stroke="#F27F0D" strokeWidth={2} className="w-10 h-10">
            <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </div>
        <h1 className="text-4xl font-extrabold text-white tracking-tight drop-shadow-md">Unitia</h1>
        <p className="mt-2 text-base font-medium text-white/85 drop-shadow-sm">Cada pedido suma a una causa real</p>
      </div>

      {/* White sheet */}
      <div className="relative w-full bg-white rounded-t-[40px] px-6 pt-10 pb-12 shadow-[0_-8px_40px_rgba(0,0,0,0.12)]">
        <div className="mx-auto max-w-sm">

          {mode === 'customer' ? (
            <>
              <h2 className="text-xl font-extrabold text-[#2D2D2D] text-center mb-1">Bienvenido</h2>
              <p className="text-muted text-sm text-center mb-6">Inicia sesión para hacer pedidos y apoyar causas</p>

              {error && (
                <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm font-medium">{error}</div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Email</label>
                  <input
                    type="email"
                    className="input"
                    placeholder="tu@email.com"
                    value={form.email}
                    onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    required
                    autoFocus
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Contraseña</label>
                  <input
                    type="password"
                    className="input"
                    placeholder="••••••••"
                    value={form.password}
                    onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                    required
                  />
                </div>
                <button type="submit" className="btn btn-primary w-full mt-2" disabled={loading}>
                  {loading ? 'Ingresando...' : 'Entrar'}
                </button>
              </form>

              <p className="text-center text-sm text-muted mt-5 font-medium">
                ¿No tienes cuenta?{' '}
                <Link href="/registro" className="text-primary font-bold hover:underline">Regístrate gratis</Link>
              </p>

              {/* Business access — secondary */}
              <div className="mt-8 pt-6 border-t border-border">
                <button
                  onClick={() => { setMode('business'); setForm({ email: '', password: '' }); setError('') }}
                  className="w-full flex items-center justify-center gap-2 text-sm text-muted font-semibold hover:text-primary transition-colors"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0H5m14 0h2m-2 0h-2M5 21H3m2 0h2M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 8h6" />
                  </svg>
                  Soy restaurante o causa
                </button>
              </div>
            </>
          ) : (
            <>
              <div className="flex items-center gap-3 mb-6">
                <button
                  onClick={() => { setMode('customer'); setForm({ email: '', password: '' }); setError('') }}
                  className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors flex-shrink-0"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                    <polyline points="15 18 9 12 15 6" />
                  </svg>
                </button>
                <div>
                  <h2 className="text-lg font-extrabold text-[#2D2D2D] leading-tight">Acceso empresarial</h2>
                  <p className="text-xs text-muted">Para restaurantes y causas sociales</p>
                </div>
              </div>

              {/* Role selector */}
              <div className="flex bg-[#F8F6F5] border border-border rounded-2xl p-1 mb-5">
                {[{ key: 'RESTAURANT', label: 'Restaurante' }, { key: 'CAUSE', label: 'Causa' }].map(tab => (
                  <button
                    key={tab.key}
                    onClick={() => setError('')}
                    className={`flex-1 py-2.5 px-2 rounded-xl text-sm font-bold transition-all ${
                      'text-muted'
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>

              {error && (
                <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm font-medium">{error}</div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Email</label>
                  <input
                    type="email"
                    className="input"
                    placeholder="tu@email.com"
                    value={form.email}
                    onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                    required
                    autoFocus
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Contraseña</label>
                  <input
                    type="password"
                    className="input"
                    placeholder="••••••••"
                    value={form.password}
                    onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                    required
                  />
                </div>
                <button type="submit" className="btn btn-primary w-full mt-2" disabled={loading}>
                  {loading ? 'Ingresando...' : 'Entrar'}
                </button>
              </form>

              <p className="text-center text-sm text-muted mt-5 font-medium">
                ¿No tienes cuenta?{' '}
                <Link href="/register" className="text-primary font-bold hover:underline">Regístrate</Link>
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  )
}
