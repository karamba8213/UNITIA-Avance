export function saveTokens(accessToken, refreshToken) {
  sessionStorage.setItem('unitia_token', accessToken)
  sessionStorage.setItem('unitia_refresh', refreshToken)
}

export function getToken() {
  return sessionStorage.getItem('unitia_token')
}

export function getRefreshToken() {
  return sessionStorage.getItem('unitia_refresh')
}

export function clearTokens() {
  sessionStorage.removeItem('unitia_token')
  sessionStorage.removeItem('unitia_refresh')
  sessionStorage.removeItem('unitia_user')
}

export function saveUser(user) {
  sessionStorage.setItem('unitia_user', JSON.stringify(user))
}

export function getUser() {
  try {
    const raw = sessionStorage.getItem('unitia_user')
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export function isAuthenticated() {
  return !!getToken()
}

export function getUserRole() {
  return getUser()?.role || null
}

export function formatCurrency(amount) {
  return new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' }).format(amount)
}

export function formatDate(date) {
  return new Intl.DateTimeFormat('es-AR', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(date))
}
