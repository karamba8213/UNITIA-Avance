import { useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { saveSession } from '../../lib/auth'
import { useAuth } from '../../lib/context'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'

export default function LoginScreen() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { setUser } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin() {
    if (!email || !password) {
      Alert.alert('Campos requeridos', 'Ingresá email y contraseña.')
      return
    }
    setLoading(true)
    try {
      const res = await api.auth.login({ email, password })
      await saveSession(res.data.accessToken, res.data.refreshToken, res.data.user)
      setUser(res.data.user)
      if (res.data.user.role === 'RESTAURANT') router.replace('/(restaurant)/dashboard')
      else if (res.data.user.role === 'CAUSE') router.replace('/(cause)/dashboard')
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Credenciales incorrectas')
    } finally {
      setLoading(false)
    }
  }

  return (
    <ScrollView
      contentContainerStyle={[styles.container, { paddingTop: insets.top + 40, paddingBottom: insets.bottom + 24 }]}
      keyboardShouldPersistTaps="handled"
    >
      {/* Logo */}
      <View style={styles.logoArea}>
        <View style={styles.logoCircle}>
          <Text style={styles.logoText}>U</Text>
        </View>
        <Text style={styles.appName}>Unitia</Text>
        <Text style={styles.tagline}>Cada pedido suma a una causa real</Text>
      </View>

      {/* Form */}
      <View style={styles.form}>
        <Input
          label="Email"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoComplete="email"
          placeholder="tu@email.com"
        />
        <Input
          label="Contraseña"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          placeholder="••••••••"
        />
        <Button label="Iniciar sesión" onPress={handleLogin} loading={loading} style={styles.btn} />
      </View>

      {/* Register */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>¿No tenés cuenta?</Text>
        <TouchableOpacity onPress={() => router.push('/(auth)/register')}>
          <Text style={styles.footerLink}> Registrate</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: { flexGrow: 1, backgroundColor: '#F0F7F4', paddingHorizontal: 24 },
  logoArea: { alignItems: 'center', marginBottom: 40 },
  logoCircle: {
    width: 72, height: 72, borderRadius: 36,
    backgroundColor: '#2D6A4F',
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 12,
    shadowColor: '#2D6A4F', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8, elevation: 6,
  },
  logoText: { fontSize: 36, fontWeight: '800', color: '#fff' },
  appName: { fontSize: 28, fontWeight: '800', color: '#1B1B1B', marginBottom: 4 },
  tagline: { fontSize: 14, color: '#6B7280', textAlign: 'center' },
  form: {
    backgroundColor: '#ffffff',
    borderRadius: 20,
    padding: 20,
    shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 8, elevation: 3,
    marginBottom: 20,
  },
  btn: { marginTop: 8 },
  footer: { flexDirection: 'row', justifyContent: 'center' },
  footerText: { color: '#6B7280', fontSize: 14 },
  footerLink: { color: '#2D6A4F', fontSize: 14, fontWeight: '600' },
})
