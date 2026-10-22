const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'

function getToken() {
  if (typeof window === 'undefined') return null
  return sessionStorage.getItem('unitia_token')
}

function getRefreshToken() {
  if (typeof window === 'undefined') return null
  return sessionStorage.getItem('unitia_refresh')
}

let refreshing = null

async function tryRefresh() {
  if (refreshing) return refreshing
  refreshing = (async () => {
    const rt = getRefreshToken()
    if (!rt) return false
    try {
      const res = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: rt }),
      })
      const data = await res.json()
      if (!res.ok || !data.data?.accessToken) return false
      sessionStorage.setItem('unitia_token', data.data.accessToken)
      if (data.data.refreshToken) sessionStorage.setItem('unitia_refresh', data.data.refreshToken)
      return true
    } catch {
      return false
    } finally {
      refreshing = null
    }
  })()
  return refreshing
}

async function request(path, options = {}, retry = true) {
  const token = getToken()
  const headers = {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
    ...options.headers,
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  })

  // Only attempt refresh if we had a token (i.e. it expired) and not an auth route
  if (res.status === 401 && retry && token && !path.startsWith('/auth/')) {
    const ok = await tryRefresh()
    if (ok) return request(path, options, false)
    // Refresh failed — clear session and redirect to login
    sessionStorage.removeItem('unitia_token')
    sessionStorage.removeItem('unitia_refresh')
    sessionStorage.removeItem('unitia_user')
    if (typeof window !== 'undefined') window.location.href = '/login'
    throw new Error('Session expired')
  }

  const data = await res.json()

  if (!res.ok) {
    const error = new Error(data.error || 'Request failed')
    error.status = res.status
    error.details = data.details
    throw error
  }

  return data
}

export const api = {
  get: (path) => request(path),
  post: (path, body) => request(path, { method: 'POST', body: JSON.stringify(body) }),
  patch: (path, body) => request(path, { method: 'PATCH', body: JSON.stringify(body) }),
  delete: (path) => request(path, { method: 'DELETE' }),

  // Auth
  auth: {
    register: (data) => api.post('/auth/register', data),
    login: (data) => api.post('/auth/login', data),
    refresh: (refreshToken) => api.post('/auth/refresh', { refreshToken }),
  },

  // Restaurant
  restaurant: {
    getProfile: () => api.get('/restaurants/me'),
    updateProfile: (data) => api.patch('/restaurants/me', data),
    getDashboard: () => api.get('/restaurants/me/dashboard'),
    getMenu: () => api.get('/restaurants/me/menu'),
    createMenuItem: (data) => api.post('/restaurants/me/menu', data),
    updateMenuItem: (id, data) => api.patch(`/restaurants/me/menu/${id}`, data),
    deleteMenuItem: (id) => api.delete(`/restaurants/me/menu/${id}`),
  },

  // Cause
  cause: {
    getProfile: () => api.get('/causes/me'),
    updateProfile: (data) => api.patch('/causes/me', data),
    getDashboard: () => api.get('/causes/me/dashboard'),
    list: () => api.get('/causes/list'),
  },

  // Orders
  orders: {
    create: (data) => api.post('/orders', data),
    list: (params = {}) => {
      const q = new URLSearchParams(params).toString()
      return api.get(`/orders${q ? '?' + q : ''}`)
    },
    get: (id) => api.get(`/orders/${id}`),
    updateStatus: (id, status, extra = {}) => api.patch(`/orders/${id}/status`, { status, ...extra }),
    getMessages: (id) => api.get(`/orders/${id}/messages`),
    sendMessage: (id, data) => api.post(`/orders/${id}/messages`, data),
  },

  // Donations
  donations: {
    list: (params = {}) => {
      const q = new URLSearchParams(params).toString()
      return api.get(`/donations${q ? '?' + q : ''}`)
    },
    markPaid: (id, { notes, paymentMethod, proofUrl } = {}) => api.patch(`/donations/${id}/pay`, { notes, paymentMethod, proofUrl }),
    confirm: (id) => api.patch(`/donations/${id}/confirm`, {}),
    dispute: (id, reason) => api.patch(`/donations/${id}/dispute`, { reason }),
  },

  // Customer
  customer: {
    getProfile: () => api.get('/customers/me'),
    updateProfile: (data) => api.patch('/customers/me', data),
    selectCause: (causeId) => api.patch('/customers/me', { selectedCauseId: causeId }),
    clearCause: () => api.patch('/customers/me', { selectedCauseId: null }),
    getOrders: () => api.get('/customers/me/orders'),
  },

  // Public
  public: {
    getCause: (slug) => api.get(`/public/causes/${slug}`),
    getRestaurant: (slug) => api.get(`/public/restaurants/${slug}`),
    getCauses: () => api.get('/public/causes'),
    getRestaurants: () => api.get('/public/restaurants'),
    getFeaturedCauses: () => api.get('/public/causes'),
  },
}
