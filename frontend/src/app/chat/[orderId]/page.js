'use client'
import { useEffect, useState, useRef, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { api } from '@/lib/api'
import { getUser } from '@/lib/auth'

function formatTime(dateStr) {
  const d = new Date(dateStr)
  return d.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false })
}

function ChatContent({ orderId }) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const role = searchParams.get('role') || 'CUSTOMER' // 'RESTAURANT' | 'CUSTOMER'
  const nameParam = searchParams.get('name')

  const [senderName, setSenderName] = useState('')
  const [messages, setMessages] = useState([])
  const [text, setText] = useState('')
  const [sending, setSending] = useState(false)
  const bottomRef = useRef(null)
  const intervalRef = useRef(null)

  useEffect(() => {
    // Resolve senderName
    let resolved = nameParam || ''
    if (!resolved) {
      const u = getUser()
      if (u) resolved = u.name || u.email || 'Usuario'
    }
    if (!resolved) {
      try {
        const raw = sessionStorage.getItem('unitia_last_order')
        if (raw) {
          const stored = JSON.parse(raw)
          resolved = stored.customerName || 'Cliente'
        }
      } catch { /* ignore */ }
    }
    setSenderName(resolved || (role === 'RESTAURANT' ? 'Restaurante' : 'Cliente'))

    loadMessages()
    intervalRef.current = setInterval(loadMessages, 3000)
    return () => clearInterval(intervalRef.current)
  }, [orderId])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  async function loadMessages() {
    try {
      const res = await api.orders.getMessages(orderId)
      setMessages(res.data || [])
    } catch {
      // ignore — might be auth error or network
    }
  }

  async function handleSend() {
    const trimmed = text.trim()
    if (!trimmed || sending) return
    setSending(true)
    try {
      await api.orders.sendMessage(orderId, {
        text: trimmed,
        senderRole: role,
        senderName,
      })
      setText('')
      await loadMessages()
    } catch {
      // ignore
    } finally {
      setSending(false)
    }
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  return (
    <div className="flex flex-col h-screen bg-background">
      {/* Header */}
      <header className="bg-white border-b border-border px-4 py-3 flex items-center gap-3 flex-shrink-0" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <button
          onClick={() => router.back()}
          className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <div className="flex-1 min-w-0">
          <h1 className="font-extrabold text-[#2D2D2D] text-sm">Chat del pedido</h1>
          <p className="text-xs text-muted font-medium truncate">{senderName}</p>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
          </span>
          <span className="text-xs font-bold text-green-600">En vivo</span>
        </div>
      </header>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {messages.length === 0 && (
          <div className="text-center text-muted text-sm font-medium py-12">
            <p className="text-3xl mb-2">💬</p>
            <p>Aún no hay mensajes. ¡Sé el primero en escribir!</p>
          </div>
        )}
        {messages.map(msg => {
          const isOwn = msg.senderRole === role
          return (
            <div key={msg.id} className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[75%] ${isOwn ? 'items-end' : 'items-start'} flex flex-col`}>
                {!isOwn && (
                  <p className="text-[10px] font-bold text-muted mb-1 px-1">{msg.senderName}</p>
                )}
                <div
                  className={`px-4 py-2.5 rounded-2xl text-sm font-medium break-words ${
                    isOwn
                      ? 'bg-primary text-white rounded-tr-sm'
                      : 'bg-white border border-border text-[#2D2D2D] rounded-tl-sm'
                  }`}
                >
                  {msg.text}
                </div>
                <p className={`text-[10px] font-medium mt-1 px-1 ${isOwn ? 'text-right text-muted' : 'text-muted'}`}>
                  {formatTime(msg.createdAt)}
                </p>
              </div>
            </div>
          )
        })}
        <div ref={bottomRef} />
      </div>

      {/* Input area */}
      <div className="flex-shrink-0 bg-white border-t border-border px-4 py-3" style={{ boxShadow: '0 -1px 8px rgba(0,0,0,0.06)' }}>
        <div className="flex gap-2 items-end max-w-xl mx-auto">
          <textarea
            value={text}
            onChange={e => setText(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Escribe un mensaje..."
            rows={1}
            className="flex-1 input resize-none py-2.5 text-sm font-medium leading-relaxed"
            style={{ maxHeight: '120px', overflowY: 'auto' }}
          />
          <button
            onClick={handleSend}
            disabled={sending || !text.trim()}
            className="flex-shrink-0 w-11 h-11 rounded-xl bg-primary text-white flex items-center justify-center hover:bg-primary/90 transition-colors disabled:opacity-40"
          >
            {sending ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : (
              <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
              </svg>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function ChatPage({ params }) {
  const { orderId } = params
  return (
    <Suspense fallback={
      <div className="flex flex-col h-screen items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <ChatContent orderId={orderId} />
    </Suspense>
  )
}
