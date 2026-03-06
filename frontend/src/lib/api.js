const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'

function getToken() {
  if (typeof window === 'undefined') return null
  return sessionStorage.getItem('unitia_token')
}

async function request(path, options = {}) {
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
  },

  // Donations
  donations: {
    list: (params = {}) => {
      const q = new URLSearchParams(params).toString()
      return api.get(`/donations${q ? '?' + q : ''}`)
    },
    markPaid: (id, notes) => api.patch(`/donations/${id}/pay`, { notes }),
    confirm: (id) => api.patch(`/donations/${id}/confirm`, {}),
  },

  // Public
  public: {
    getCause: (slug) => api.get(`/public/causes/${slug}`),
    getRestaurant: (slug) => api.get(`/public/restaurants/${slug}`),
    getFeaturedCauses: () => api.get('/public/causes'),
  },
}
