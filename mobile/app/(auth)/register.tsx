import { useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { saveSession } from '../../lib/auth'
import { useAuth } from '../../lib/context'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'

type Role = 'RESTAURANT' | 'CAUSE'

export default function RegisterScreen() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { setUser } = useAuth()
  const [role, setRole] = useState<Role>('RESTAURANT')
  const [form, setForm] = useState({
    email: '', password: '', name: '',
    profileName: '', description: '', donationPercentage: '5', targetAmount: '0',
  })
  const [loading, setLoading] = useState(false)

  function set(key: string, val: string) {
    setForm(f => ({ ...f, [key]: val }))
  }

  async function handleRegister() {
    if (!form.email || !form.password || !form.name) {
      Alert.alert('Campos requeridos', 'Completá todos los campos obligatorios.')
      return
    }
    setLoading(true)
    try {
      const profile = role === 'RESTAURANT'
        ? { name: form.profileName || form.name, description: form.description, donationPercentage: parseFloat(form.donationPercentage) }
        : { name: form.profileName || form.name, description: form.description, targetAmount: parseFloat(form.targetAmount) }

      const res = await api.auth.register({ email: form.email, password: form.password, name: form.name, role, profile })
      await saveSession(res.data.accessToken, res.data.refreshToken, res.data.user)
      setUser(res.data.user)
      if (role === 'RESTAURANT') router.replace('/(restaurant)/dashboard')
      else router.replace('/(cause)/dashboard')
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Error al registrarse')
    } finally {
      setLoading(false)
    }
  }

  return (
    <ScrollView
      contentContainerStyle={[styles.container, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 }]}
      keyboardShouldPersistTaps="handled"
    >
      <TouchableOpacity onPress={() => router.back()} style={{ marginBottom: 20 }}>
        <Text style={{ color: '#6B7280', fontSize: 15 }}>← Volver</Text>
      </TouchableOpacity>

      <Text style={styles.title}>Crear cuenta</Text>

      {/* Role selector */}
      <View style={styles.roleRow}>
        {(['RESTAURANT', 'CAUSE'] as Role[]).map(r => (
          <TouchableOpacity
            key={r}
            onPress={() => setRole(r)}
            style={[styles.roleBtn, role === r && styles.roleBtnActive]}
          >
            <Text style={[styles.roleBtnText, role === r && styles.roleBtnTextActive]}>
              {r === 'RESTAURANT' ? '🍽 Restaurante' : '💚 Causa social'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <View style={styles.form}>
        <Input label="Tu nombre completo *" value={form.name} onChangeText={v => set('name', v)} placeholder="Ej: María García" />
        <Input label="Email *" value={form.email} onChangeText={v => set('email', v)} keyboardType="email-address" autoCapitalize="none" placeholder="tu@email.com" />
        <Input label="Contraseña *" value={form.password} onChangeText={v => set('password', v)} secureTextEntry placeholder="Mínimo 8 caracteres" />

        <View style={styles.separator} />

        <Input
          label={role === 'RESTAURANT' ? 'Nombre del restaurante' : 'Nombre de la organización'}
          value={form.profileName}
          onChangeText={v => set('profileName', v)}
          placeholder="Ej: La Familiar"
        />
        <Input label="Descripción breve" value={form.description} onChangeText={v => set('description', v)} placeholder="¿Qué hacen?" multiline />

        {role === 'RESTAURANT' && (
          <Input
            label="% de donación por pedido"
            value={form.donationPercentage}
            onChangeText={v => set('donationPercentage', v)}
            keyboardType="decimal-pad"
            placeholder="5"
          />
        )}
        {role === 'CAUSE' && (
          <Input
            label="Objetivo de recaudación (opcional)"
            value={form.targetAmount}
            onChangeText={v => set('targetAmount', v)}
            keyboardType="decimal-pad"
            placeholder="0"
          />
        )}

        <Button label="Crear cuenta" onPress={handleRegister} loading={loading} style={{ marginTop: 8 }} />
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>¿Ya tenés cuenta?</Text>
        <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
          <Text style={styles.footerLink}> Iniciá sesión</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: { flexGrow: 1, backgroundColor: '#F0F7F4', paddingHorizontal: 24 },
  title: { fontSize: 26, fontWeight: '800', color: '#111827', marginBottom: 20 },
  roleRow: { flexDirection: 'row', gap: 8, marginBottom: 20 },
  roleBtn: {
    flex: 1, height: 44, borderRadius: 10, borderWidth: 1.5,
    borderColor: '#D1D5DB', backgroundColor: '#fff',
    alignItems: 'center', justifyContent: 'center',
  },
  roleBtnActive: { borderColor: '#2D6A4F', backgroundColor: '#2D6A4F' },
  roleBtnText: { fontSize: 13, fontWeight: '600', color: '#6B7280' },
  roleBtnTextActive: { color: '#fff' },
  form: {
    backgroundColor: '#ffffff', borderRadius: 20, padding: 20,
    shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 8, elevation: 3,
    marginBottom: 20,
  },
  separator: { height: 1, backgroundColor: '#F3F4F6', marginVertical: 12 },
  footer: { flexDirection: 'row', justifyContent: 'center' },
  footerText: { color: '#6B7280', fontSize: 14 },
  footerLink: { color: '#2D6A4F', fontSize: 14, fontWeight: '600' },
})
