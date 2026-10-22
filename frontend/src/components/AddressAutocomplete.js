'use client'
import { useState, useRef, useEffect, useCallback } from 'react'

const GOOGLE_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_KEY

// ── Debounce ────────────────────────────────────────────────────────────────
function debounce(fn, ms) {
  let t
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms) }
}

// ── Google Places via script tag ─────────────────────────────────────────────
let googleLoaded = false
let googleLoading = false
let googleCallbacks = []

function loadGoogleScript(key) {
  if (googleLoaded) return Promise.resolve()
  if (googleLoading) return new Promise(r => googleCallbacks.push(r))
  googleLoading = true
  return new Promise((resolve) => {
    googleCallbacks.push(resolve)
    const s = document.createElement('script')
    s.src = `https://maps.googleapis.com/maps/api/js?key=${key}&libraries=places&language=es`
    s.async = true
    s.onload = () => {
      googleLoaded = true
      googleLoading = false
      googleCallbacks.forEach(cb => cb())
      googleCallbacks = []
    }
    document.head.appendChild(s)
  })
}

async function googleSuggest(query) {
  if (!GOOGLE_KEY || query.length < 3) return []
  await loadGoogleScript(GOOGLE_KEY)
  return new Promise((resolve) => {
    const svc = new window.google.maps.places.AutocompleteService()
    svc.getPlacePredictions(
      {
        input: query,
        componentRestrictions: { country: 'mx' },
        types: ['address'],
      },
      (predictions, status) => {
        if (status !== 'OK' || !predictions) return resolve([])
        resolve(predictions.map(p => ({
          id: p.place_id,
          main: p.structured_formatting.main_text,
          secondary: p.structured_formatting.secondary_text,
          placeId: p.place_id,
        })))
      }
    )
  })
}

async function googleGetDetail(placeId) {
  return new Promise((resolve) => {
    const map = new window.google.maps.Map(document.createElement('div'))
    const svc = new window.google.maps.places.PlacesService(map)
    svc.getDetails(
      { placeId, fields: ['address_components', 'formatted_address'] },
      (place, status) => {
        if (status !== 'OK' || !place) return resolve(null)
        const get = (type) => place.address_components?.find(c => c.types.includes(type))?.long_name || ''
        const num    = get('street_number')
        const road   = get('route')
        const colony = get('sublocality_level_1') || get('neighborhood') || get('sublocality')
        const city   = get('locality') || get('administrative_area_level_2')
        const cp     = get('postal_code')
        const parts  = [road && num ? `${road} ${num}` : road || get('premise'), colony, city, cp ? `C.P. ${cp}` : ''].filter(Boolean)
        resolve(parts.join(', '))
      }
    )
  })
}

// ── Nominatim fallback ────────────────────────────────────────────────────────
async function nominatimSuggest(query) {
  if (query.length < 4) return []
  try {
    const url = `https://nominatim.openstreetmap.org/search` +
      `?q=${encodeURIComponent(query)}&format=json&limit=5&countrycodes=mx` +
      `&addressdetails=1&accept-language=es` +
      `&bounded=1&viewbox=-118.4,14.5,-86.7,32.7`
    const res = await fetch(url, { headers: { 'Accept-Language': 'es-MX' } })
    const data = await res.json()
    return (data || []).map(item => {
      const a = item.address || {}
      const road = a.road || item.display_name.split(',')[0].trim()
      const num  = a.house_number || ''
      const main = num ? `${road} ${num}` : road
      const sub  = [
        a.suburb || a.neighbourhood || a.quarter || a.residential || a.city_district || a.village,
        a.city || a.town || a.municipality,
        a.postcode,
      ].filter(Boolean).join(', ')
      return { id: item.place_id, main, secondary: sub, _raw: item }
    })
  } catch { return [] }
}

function nominatimFormat(item) {
  const a = item._raw?.address || {}
  const road   = a.road || item.main
  const num    = a.house_number || ''
  const street = road && num ? `${road} ${num}` : road
  const colony = a.suburb || a.neighbourhood || a.quarter || a.residential || a.city_district || a.village || ''
  const city   = a.city || a.town || a.municipality || ''
  const cp     = a.postcode ? `C.P. ${a.postcode}` : ''
  return [street, colony, city, cp].filter(Boolean).join(', ')
}

// ── Component ─────────────────────────────────────────────────────────────────
export default function AddressAutocomplete({ value, onChange, placeholder, className }) {
  const [query, setQuery]           = useState(value || '')
  const [suggestions, setSuggestions] = useState([])
  const [open, setOpen]             = useState(false)
  const [loading, setLoading]       = useState(false)
  const containerRef                = useRef(null)
  const inputRef                    = useRef(null)

  useEffect(() => {
    setQuery(value || '')
    setSuggestions([])
    setOpen(false)
  }, [value])

  useEffect(() => {
    const close = (e) => { if (containerRef.current && !containerRef.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', close)
    return () => document.removeEventListener('mousedown', close)
  }, [])

  const search = useCallback(debounce(async (q) => {
    if (q.length < 3) { setSuggestions([]); setOpen(false); return }
    setLoading(true)
    try {
      const results = GOOGLE_KEY ? await googleSuggest(q) : await nominatimSuggest(q)
      setSuggestions(results)
      setOpen(results.length > 0)
    } finally {
      setLoading(false)
    }
  }, 350), [])

  function handleInput(e) {
    const val = e.target.value
    setQuery(val)
    onChange(val)   // always pass typed value — no blocking
    search(val)
  }

  async function handleSelect(item) {
    setOpen(false)
    setSuggestions([])
    let formatted = ''
    if (GOOGLE_KEY) {
      setLoading(true)
      formatted = await googleGetDetail(item.placeId) || `${item.main}, ${item.secondary}`
      setLoading(false)
    } else {
      formatted = nominatimFormat(item)
    }
    setQuery(formatted)
    onChange(formatted)
    inputRef.current?.focus()
  }

  function handleClear() {
    setQuery('')
    onChange('')
    setSuggestions([])
    setOpen(false)
    inputRef.current?.focus()
  }

  return (
    <div ref={containerRef} className="relative">
      <div className="relative">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}
          className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted pointer-events-none flex-shrink-0">
          <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 0 1-2.827 0l-4.244-4.243a8 8 0 1 1 11.314 0z" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 1 1-6 0 3 3 0 0 1 6 0z" />
        </svg>
        <input
          ref={inputRef}
          type="text"
          className={`${className || 'input'} pl-9 pr-9`}
          placeholder={placeholder || 'Calle, número, colonia...'}
          value={query}
          onChange={handleInput}
          onFocus={() => suggestions.length > 0 && setOpen(true)}
          autoComplete="off"
          autoCorrect="off"
          spellCheck={false}
        />
        {loading && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">
            <div className="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin" />
          </div>
        )}
        {!loading && query && (
          <button type="button" onClick={handleClear}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted hover:text-[#2D2D2D] transition-colors">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        )}
      </div>

      {open && suggestions.length > 0 && (
        <ul className="absolute z-50 w-full mt-1 bg-white border border-border rounded-2xl shadow-xl overflow-hidden">
          {suggestions.map((item, i) => (
            <li key={item.id || i}>
              <button
                type="button"
                onMouseDown={e => { e.preventDefault(); handleSelect(item) }} // preventDefault keeps focus
                className="w-full flex items-start gap-3 px-4 py-3 hover:bg-background transition-colors text-left border-b border-border last:border-0 active:bg-primary-bg"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}
                  className="w-4 h-4 text-primary flex-shrink-0 mt-0.5">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 0 1-2.827 0l-4.244-4.243a8 8 0 1 1 11.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 1 1-6 0 3 3 0 0 1 6 0z" />
                </svg>
                <div className="min-w-0">
                  <p className="text-sm font-bold text-[#2D2D2D] leading-snug">{item.main}</p>
                  {item.secondary && <p className="text-xs text-muted mt-0.5 truncate">{item.secondary}</p>}
                </div>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
