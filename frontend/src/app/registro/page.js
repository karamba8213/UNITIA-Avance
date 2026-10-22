'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { saveTokens, saveUser } from '@/lib/auth'

export default function RegistroPage() {
  const router = useRouter()
  const [form, setForm] = useState({ name: '', email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const result = await api.auth.register({
        name: form.name,
        email: form.email,
        password: form.password,
        role: 'CUSTOMER',
        profile: {},
      })
      saveTokens(result.data.accessToken, result.data.refreshToken)
      saveUser(result.data.user)
      router.push('/inicio')
    } catch (err) {
      setError(err.message || 'Error al registrarse')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ background: 'linear-gradient(145deg, #F27F0D 0%, #D96A00 100%)' }}>
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-32 -mt-32 pointer-events-none" />

      {/* Hero */}
      <div className="relative flex-1 flex flex-col items-center justify-end pb-10 pt-16 px-6 text-center">
        <div className="w-20 h-20 bg-white rounded-2xl shadow-2xl flex items-center justify-center mb-6">
          <svg viewBox="0 0 24 24" fill="none" stroke="#F27F0D" strokeWidth={2} className="w-10 h-10">
            <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </div>
        <h1 className="text-4xl font-extrabold text-white tracking-tight drop-shadow-md">Unitia</h1>
        <p className="mt-2 text-base font-medium text-white/85 drop-shadow-sm">Únete y haz el bien comiendo</p>
      </div>

      {/* White card from bottom */}
      <div className="relative w-full bg-white rounded-t-[40px] px-6 pt-10 pb-12 shadow-[0_-8px_40px_rgba(0,0,0,0.12)]">
        <div className="mx-auto max-w-sm">
          <h2 className="text-xl font-bold text-[#2D2D2D] text-center mb-1">Crear cuenta gratis</h2>
          <p className="text-muted text-sm text-center mb-6">Como cliente de restaurantes Unitia</p>

          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm font-medium">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Nombre completo</label>
              <input
                type="text"
                className="input"
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                required
                autoFocus
                minLength={2}
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Email</label>
              <input
                type="email"
                className="input"
                value={form.email}
                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                required
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-[#2D2D2D] mb-1.5">Contraseña</label>
              <input
                type="password"
                className="input"
                value={form.password}
                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                required
                minLength={8}
              />
              <p className="text-xs text-muted mt-1">Mínimo 8 caracteres</p>
            </div>
            <button type="submit" className="btn btn-primary w-full mt-2" disabled={loading}>
              {loading ? 'Creando cuenta...' : 'Crear cuenta'}
            </button>
          </form>

          <p className="text-center text-sm text-muted mt-5 font-medium">
            ¿Ya tienes cuenta?{' '}
            <Link href="/login" className="text-primary font-bold hover:underline">Iniciar sesión</Link>
          </p>

          <p className="text-center text-xs text-muted mt-4">
            ¿Sos restaurante o causa?{' '}
            <Link href="/register" className="text-primary font-semibold hover:underline">Regístrate aquí</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
