'use client'
import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import es from '@/lib/i18n/es.json'
import en from '@/lib/i18n/en.json'

const messages = { es, en }
export const LOCALES = [
  { code: 'es', label: 'Español', flag: '🇲🇽' },
  { code: 'en', label: 'English', flag: '🇺🇸' },
]

function detectLocale() {
  if (typeof window === 'undefined') return 'es'
  const saved = localStorage.getItem('unitia_locale')
  if (saved && messages[saved]) return saved
  // Check full preference list (e.g. ['en-US', 'en', 'es-MX'])
  const langs = navigator.languages?.length
    ? navigator.languages
    : [navigator.language || navigator.userLanguage || 'es']
  for (const l of langs) {
    const code = l.toLowerCase()
    if (code.startsWith('en')) return 'en'
    if (code.startsWith('es') || code.startsWith('pt')) return 'es'
  }
  return 'es'
}

const LocaleContext = createContext(null)

export function LocaleProvider({ children }) {
  const [locale, setLocale] = useState('es')

  useEffect(() => {
    const detected = detectLocale()
    setLocale(detected)
    document.documentElement.lang = detected === 'en' ? 'en' : 'es-MX'
  }, [])

  // Interpolate {{key}} placeholders
  const t = useCallback((key, vars = {}) => {
    const keys = key.split('.')
    let val = messages[locale]
    for (const k of keys) {
      if (val == null) break
      val = val[k]
    }
    if (val == null) return key
    if (typeof val === 'string' && Object.keys(vars).length) {
      return val.replace(/\{\{(\w+)\}\}/g, (_, k) => vars[k] ?? `{{${k}}}`)
    }
    return val
  }, [locale])

  function changeLocale(code) {
    if (!messages[code]) return
    setLocale(code)
    localStorage.setItem('unitia_locale', code)
    document.documentElement.lang = code === 'en' ? 'en' : 'es-MX'
  }

  return (
    <LocaleContext.Provider value={{ locale, t, changeLocale, locales: LOCALES }}>
      {children}
    </LocaleContext.Provider>
  )
}

export function useLocale() {
  const ctx = useContext(LocaleContext)
  if (!ctx) throw new Error('useLocale must be used within LocaleProvider')
  return ctx
}
