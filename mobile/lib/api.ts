import * as SecureStore from 'expo-secure-store'

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:4000/api/v1'

async function getToken(): Promise<string | null> {
  return SecureStore.getItemAsync('unitia_token')
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = await getToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(options.headers as Record<string, string> || {}),
  }

  const res = await fetch(`${API_URL}${path}`, { ...options, headers })
  const data = await res.json()

  if (!res.ok) {
    const error: any = new Error(data.error || 'Request failed')
    error.status = res.status
    throw error
  }

  return data
}

const get = <T>(path: string) => request<T>(path)
const post = <T>(path: string, body: unknown) =>
  request<T>(path, { method: 'POST', body: JSON.stringify(body) })
const patch = <T>(path: string, body: unknown) =>
  request<T>(path, { method: 'PATCH', body: JSON.stringify(body) })
const del = <T>(path: string) => request<T>(path, { method: 'DELETE' })

export const api = {
  auth: {
    login: (data: { email: string; password: string }) => post<any>('/auth/login', data),
    register: (data: any) => post<any>('/auth/register', data),
  },
  restaurant: {
    getProfile: () => get<any>('/restaurants/me'),
    updateProfile: (data: any) => patch<any>('/restaurants/me', data),
    getDashboard: () => get<any>('/restaurants/me/dashboard'),
    getMenu: () => get<any>('/restaurants/me/menu'),
    createMenuItem: (data: any) => post<any>('/restaurants/me/menu', data),
    updateMenuItem: (id: string, data: any) => patch<any>(`/restaurants/me/menu/${id}`, data),
    deleteMenuItem: (id: string) => del<any>(`/restaurants/me/menu/${id}`),
  },
  cause: {
    getProfile: () => get<any>('/causes/me'),
    updateProfile: (data: any) => patch<any>('/causes/me', data),
    getDashboard: () => get<any>('/causes/me/dashboard'),
    list: () => get<any>('/causes/list'),
  },
  orders: {
    create: (data: any) => post<any>('/orders', data),
    list: (params: Record<string, any> = {}) => {
      const q = new URLSearchParams(params).toString()
      return get<any>(`/orders${q ? '?' + q : ''}`)
    },
  },
  donations: {
    list: (params: Record<string, any> = {}) => {
      const q = new URLSearchParams(params).toString()
      return get<any>(`/donations${q ? '?' + q : ''}`)
    },
    markPaid: (id: string, notes?: string) => patch<any>(`/donations/${id}/pay`, { notes }),
    confirm: (id: string) => patch<any>(`/donations/${id}/confirm`, {}),
  },
  public: {
    getCause: (slug: string) => get<any>(`/public/causes/${slug}`),
    getRestaurant: (slug: string) => get<any>(`/public/restaurants/${slug}`),
    getFeaturedCauses: () => get<any>('/public/causes'),
    getImpact: (email: string) => get<any>(`/public/impact?email=${encodeURIComponent(email)}`),
  },
}
