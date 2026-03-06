import * as SecureStore from 'expo-secure-store'

export async function saveSession(accessToken: string, refreshToken: string, user: any) {
  await SecureStore.setItemAsync('unitia_token', accessToken)
  await SecureStore.setItemAsync('unitia_refresh', refreshToken)
  await SecureStore.setItemAsync('unitia_user', JSON.stringify(user))
}

export async function clearSession() {
  await SecureStore.deleteItemAsync('unitia_token')
  await SecureStore.deleteItemAsync('unitia_refresh')
  await SecureStore.deleteItemAsync('unitia_user')
}

export async function getStoredUser(): Promise<any | null> {
  const raw = await SecureStore.getItemAsync('unitia_user')
  if (!raw) return null
  try { return JSON.parse(raw) } catch { return null }
}

export async function getToken(): Promise<string | null> {
  return SecureStore.getItemAsync('unitia_token')
}

export async function isLoggedIn(): Promise<boolean> {
  const token = await getToken()
  return !!token
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' }).format(amount)
}

export function formatDate(date: string | Date): string {
  return new Intl.DateTimeFormat('es-AR', { day: '2-digit', month: 'short' }).format(new Date(date))
}
