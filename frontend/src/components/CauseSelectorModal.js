'use client'
import { useState, useEffect, useRef } from 'react'
import { useCause } from '@/context/CauseContext'
import { useLocale } from '@/context/LocaleContext'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n || 0)
}

export default function CauseSelectorModal() {
  const { allCauses, selectedCause, selectorOpen, closeSelector, selectCause } = useCause()
  const { t } = useLocale()
  const [query, setQuery] = useState('')
  const inputRef = useRef(null)

  useEffect(() => {
    if (selectorOpen) {
      setQuery('')
      setTimeout(() => inputRef.current?.focus(), 100)
    }
  }, [selectorOpen])

  // Close on backdrop click or Escape
  useEffect(() => {
    function onKey(e) { if (e.key === 'Escape') closeSelector() }
    if (selectorOpen) document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [selectorOpen, closeSelector])

  if (!selectorOpen) return null

  const filtered = allCauses.filter(c =>
    c.name.toLowerCase().includes(query.toLowerCase()) ||
    (c.description || '').toLowerCase().includes(query.toLowerCase())
  )

  return (
    <div
      className="fixed inset-0 z-[110] flex items-end sm:items-center justify-center"
      onClick={e => { if (e.target === e.currentTarget) closeSelector() }}
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={closeSelector} />

      {/* Sheet */}
      <div className="relative w-full sm:max-w-md bg-white rounded-t-[32px] sm:rounded-2xl shadow-2xl max-h-[85vh] flex flex-col z-10">
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1 sm:hidden">
          <div className="w-10 h-1 bg-border rounded-full" />
        </div>

        {/* Header */}
        <div className="px-5 pt-4 pb-3 border-b border-border">
          <div className="flex items-center justify-between mb-1">
            <h2 className="text-lg font-extrabold text-[#2D2D2D]">{t('cause.selector.title')}</h2>
            <button
              onClick={closeSelector}
              className="w-8 h-8 rounded-full bg-background flex items-center justify-center text-muted hover:text-[#2D2D2D] transition-colors"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
          <p className="text-sm text-muted">{t('cause.selector.subtitle')}</p>

          {/* Search */}
          <div className="relative mt-3">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}
              className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted pointer-events-none">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder={t('cause.selector.searchPlaceholder')}
              className="w-full pl-9 pr-4 py-3 border-2 border-border rounded-2xl focus:outline-none focus:border-primary transition-all bg-white text-sm placeholder:text-muted"
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-[#2D2D2D]"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                  <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            )}
          </div>
        </div>

        {/* Cause list */}
        <div className="overflow-y-auto flex-1 p-4 space-y-2">
          {filtered.length === 0 ? (
            <div className="text-center py-10">
              <p className="text-3xl mb-2">🔍</p>
              <p className="text-muted text-sm font-medium">{t('cause.selector.noResults')}</p>
            </div>
          ) : (
            filtered.map(cause => {
              const isSelected = selectedCause?.id === cause.id
              const progress = cause.targetAmount > 0
                ? Math.min(100, Math.round((cause.totalRaised || 0) / cause.targetAmount * 100))
                : null

              return (
                <button
                  key={cause.id}
                  onClick={() => selectCause(cause)}
                  className={`w-full flex items-center gap-3 p-4 rounded-2xl border-2 text-left transition-all ${
                    isSelected
                      ? 'border-primary bg-primary-bg'
                      : 'border-transparent bg-background hover:border-primary/30 hover:bg-primary-bg/50'
                  }`}
                >
                  {/* Logo */}
                  {cause.logo ? (
                    <img src={cause.logo} alt={cause.name} className="w-14 h-14 rounded-2xl object-cover flex-shrink-0" />
                  ) : (
                    <div className="w-14 h-14 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-2xl">❤️</div>
                  )}

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-extrabold text-[#2D2D2D] text-sm truncate">{cause.name}</p>
                      {isSelected && (
                        <span className="flex-shrink-0 text-xs font-bold text-primary bg-primary-bg border border-primary/20 px-2 py-0.5 rounded-full">
                          ✓
                        </span>
                      )}
                    </div>
                    {cause.description && (
                      <p className="text-xs text-muted line-clamp-2 mt-0.5 leading-relaxed">{cause.description}</p>
                    )}
                    <div className="mt-2">
                      {progress !== null ? (
                        <>
                          <div className="h-1.5 bg-border rounded-full overflow-hidden">
                            <div className="h-full bg-primary rounded-full" style={{ width: `${progress}%` }} />
                          </div>
                          <div className="flex items-center justify-between mt-1">
                            <p className="text-xs text-primary font-bold">{formatCurrency(cause.totalRaised || 0)} {t('cause.selector.raised')}</p>
                            <p className="text-xs text-muted font-medium">{progress}%</p>
                          </div>
                        </>
                      ) : (
                        <p className="text-xs text-primary font-bold">{formatCurrency(cause.totalRaised || 0)} {t('cause.selector.raised')}</p>
                      )}
                    </div>
                  </div>

                  {/* Arrow */}
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5}
                    className={`w-5 h-5 flex-shrink-0 transition-colors ${isSelected ? 'text-primary' : 'text-muted'}`}>
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
                </button>
              )
            })
          )}
        </div>

        {/* Bottom safe area */}
        <div className="h-safe-bottom pb-2" />
      </div>
    </div>
  )
}
