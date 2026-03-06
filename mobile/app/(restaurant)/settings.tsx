import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import Header from '../../components/layout/Header'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'

export default function RestaurantSettings() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { logout } = useAuth()
  const [form, setForm] = useState({ name: '', description: '', address: '', phone: '', logo: '', donationPercentage: '5', causeId: '' })
  const [causes, setCauses] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  function set(key: string, val: string) { setForm(f => ({ ...f, [key]: val })) }

  useEffect(() => {
    Promise.all([api.restaurant.getProfile(), api.cause.list()])
      .then(([p, c]) => {
        const d = p.data
        setForm({
          name: d.name || '', description: d.description || '',
          address: d.address || '', phone: d.phone || '',
          logo: d.logo || '', donationPercentage: String(d.donationPercentage || 5),
          causeId: d.causeId || '',
        })
        setCauses(c.data || [])
      })
      .catch(err => { if (err.status === 401) { logout(); router.replace('/(auth)/login') } })
      .finally(() => setLoading(false))
  }, [])

  async function save() {
    setSaving(true)
    try {
      await api.restaurant.updateProfile({
        ...form,
        donationPercentage: parseFloat(form.donationPercentage),
        causeId: form.causeId || null,
        logo: form.logo || undefined,
      })
      Alert.alert('Guardado', 'Los cambios fueron guardados.')
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}><Text style={{ color: '#9CA3AF' }}>Cargando...</Text></View>

  const selectedCause = causes.find(c => c.id === form.causeId)

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <Header title="Ajustes" showBack />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 32 }} keyboardShouldPersistTaps="handled">
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Perfil del restaurante</Text>
          <Input label="Nombre" value={form.name} onChangeText={v => set('name', v)} />
          <Input label="Descripción" value={form.description} onChangeText={v => set('description', v)} multiline />
          <Input label="Dirección" value={form.address} onChangeText={v => set('address', v)} />
          <Input label="Teléfono" value={form.phone} onChangeText={v => set('phone', v)} keyboardType="phone-pad" />
          <Input label="Logo (URL)" value={form.logo} onChangeText={v => set('logo', v)} keyboardType="url" autoCapitalize="none" />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Causa que apoyás</Text>
          <Text style={styles.selectedCause}>
            {selectedCause ? `✅ ${selectedCause.name}` : '— Sin seleccionar —'}
          </Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
            <View style={{ flexDirection: 'row', gap: 8, paddingVertical: 4 }}>
              <TouchableOpacity
                style={[styles.causeChip, !form.causeId && styles.causeChipSelected]}
                onPress={() => set('causeId', '')}
              >
                <Text style={[styles.causeChipText, !form.causeId && styles.causeChipTextSelected]}>Ninguna</Text>
              </TouchableOpacity>
              {causes.map(c => (
                <TouchableOpacity
                  key={c.id}
                  style={[styles.causeChip, form.causeId === c.id && styles.causeChipSelected]}
                  onPress={() => set('causeId', c.id)}
                >
                  <Text style={[styles.causeChipText, form.causeId === c.id && styles.causeChipTextSelected]} numberOfLines={1}>
                    {c.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>

          <Input
            label="% de donación por pedido"
            value={form.donationPercentage}
            onChangeText={v => set('donationPercentage', v)}
            keyboardType="decimal-pad"
          />
          <Text style={styles.hint}>
            En un pedido de $1,000 donarías ${(1000 * parseFloat(form.donationPercentage || '0') / 100).toFixed(2)}.
          </Text>
        </View>

        <Button label="Guardar cambios" onPress={save} loading={saving} />
      </ScrollView>
    </View>
  )
}

const styles = StyleSheet.create({
  section: {
    backgroundColor: '#fff', borderRadius: 16, padding: 16, marginBottom: 12,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
  },
  sectionTitle: { fontSize: 14, fontWeight: '700', color: '#111827', marginBottom: 14 },
  selectedCause: { fontSize: 14, color: '#2D6A4F', fontWeight: '600', marginBottom: 10 },
  causeChip: {
    paddingHorizontal: 12, paddingVertical: 7, borderRadius: 20,
    borderWidth: 1.5, borderColor: '#D1D5DB', backgroundColor: '#fff', maxWidth: 160,
  },
  causeChipSelected: { borderColor: '#2D6A4F', backgroundColor: '#2D6A4F' },
  causeChipText: { fontSize: 12, fontWeight: '600', color: '#6B7280' },
  causeChipTextSelected: { color: '#fff' },
  hint: { fontSize: 11, color: '#9CA3AF', marginTop: -4 },
})
