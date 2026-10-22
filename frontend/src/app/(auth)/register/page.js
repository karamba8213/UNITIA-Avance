'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { saveTokens, saveUser } from '@/lib/auth'

function RegisterForm() {
  const router = useRouter()
  const params = useSearchParams()
  const defaultRole = params.get('role') || 'RESTAURANT'

  const [role, setRole] = useState(defaultRole)
  const [form, setForm] = useState({
    email: '', password: '', name: '',
    profile: { name: '', description: '', donationPercentage: 15, story: '', targetAmount: 0 }
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  function setField(field, value) {
    setForm(f => ({ ...f, [field]: value }))
  }
  function setProfile(field, value) {
    setForm(f => ({ ...f, profile: { ...f.profile, [field]: value } }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { data } = await api.auth.register({ ...form, role })
      saveTokens(data.accessToken, data.refreshToken)
      saveUser(data.user)
      if (role === 'RESTAURANT') router.push('/restaurant/dashboard')
      else router.push('/cause/dashboard')
    } catch (err) {
      setError(err.message || 'Error al registrarse')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ background: 'linear-gradient(145deg, #F27F0D 0%, #D96A00 100%)' }}>
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32 pointer-events-none" />

      {/* Hero */}
      <div className="relative flex-1 flex flex-col items-center justify-end pb-8 pt-14 px-6 text-center">
        <div className="w-20 h-20 bg-white rounded-2xl shadow-2xl flex items-center justify-center mb-5">
          {role === 'RESTAURANT' ? (
            <svg viewBox="0 0 24 24" fill="none" stroke="#F27F0D" strokeWidth={2} className="w-10 h-10">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M7 2v20" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3zm0 0v7" />
            </svg>
          ) : (
            <svg viewBox="0 0 24 24" fill="none" stroke="#F27F0D" strokeWidth={2} className="w-10 h-10">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
            </svg>
          )}
        </div>
        <h1 className="text-4xl font-extrabold text-white tracking-tight drop-shadow-md">Unitia</h1>
        <p className="mt-2 text-base font-medium text-white/85 drop-shadow-sm">
          {role === 'RESTAURANT' ? 'Cada pedido apoya una causa' : 'Recibe apoyo de restaurantes locales'}
        </p>
      </div>

      {/* White card from bottom — scrollable */}
      <div className="relative w-full bg-white rounded-t-[40px] px-6 pt-8 pb-12 shadow-[0_-8px_40px_rgba(0,0,0,0.12)] max-h-[75vh] overflow-y-auto">
        <div className="mx-auto max-w-sm">
          <h2 className="text-xl font-bold text-[#2D2D2D] text-center mb-1">Crear cuenta</h2>
          <p className="text-muted text-sm text-center mb-5">¿Cómo quieres participar?</p>

          {/* Role selector */}
          <div className="flex bg-[#F8F6F5] border border-border rounded-2xl p-1 mb-5">
            {['RESTAURANT', 'CAUSE'].map(r => (
              <button
                key={r}
                type="button"
                onClick={() => setRole(r)}
                className={`flex-1 py-2.5 px-2 rounded-xl text-sm font-bold transition-colors ${
                  role === r ? 'bg-primary text-white shadow-sm' : 'text-muted hover:text-[#2D2D2D]'
                }`}
              >
                {r === 'RESTAURANT' ? '🍽 Restaurante' : '❤️ Causa'}
              </button>
            ))}
          </div>

          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm font-medium">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Tu nombre completo</label>
              <input className="input" value={form.name} onChange={e => setField('name', e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Email</label>
              <input type="email" className="input" value={form.email} onChange={e => setField('email', e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Contraseña</label>
              <input type="password" className="input" value={form.password} onChange={e => setField('password', e.target.value)} required minLength={8} />
            </div>

            <div className="border-t border-border pt-4">
              {role === 'RESTAURANT' ? (
                <>
                  <div className="mb-4">
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Nombre del restaurante</label>
                    <input className="input" value={form.profile.name} onChange={e => setProfile('name', e.target.value)} />
                  </div>
                  <div className="mb-4">
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Descripción breve</label>
                    <textarea className="input resize-none" rows={2} value={form.profile.description} onChange={e => setProfile('description', e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">
                      % de donación por pedido <span className="text-muted font-normal">(mínimo 15%)</span>
                    </label>
                    <input type="number" className="input" min={15} max={100} step={0.5} value={form.profile.donationPercentage} onChange={e => setProfile('donationPercentage', parseFloat(e.target.value))} />
                  </div>
                </>
              ) : (
                <>
                  <div className="mb-4">
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Nombre de la organización</label>
                    <input className="input" value={form.profile.name} onChange={e => setProfile('name', e.target.value)} />
                  </div>
                  <div className="mb-4">
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Descripción breve</label>
                    <textarea className="input resize-none" rows={2} value={form.profile.description} onChange={e => setProfile('description', e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Objetivo de recaudación (opcional)</label>
                    <input type="number" className="input" min={0} value={form.profile.targetAmount} onChange={e => setProfile('targetAmount', parseFloat(e.target.value))} />
                  </div>
                </>
              )}
            </div>

            <button type="submit" className="btn btn-primary w-full" disabled={loading}>
              {loading ? 'Creando cuenta...' : 'Crear cuenta'}
            </button>
          </form>

          <p className="text-center text-sm text-muted mt-5 font-medium">
            ¿Ya tienes cuenta?{' '}
            <Link href="/login" className="text-primary font-bold hover:underline">Iniciá sesión</Link>
          </p>
        </div>
      </div>
    </div>
  )
}

export default function RegisterPage() {
  return (
    <Suspense>
      <RegisterForm />
    </Suspense>
  )
}
