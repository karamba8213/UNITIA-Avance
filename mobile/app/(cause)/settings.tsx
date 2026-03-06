import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, ScrollView, Alert, TouchableOpacity } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import Header from '../../components/layout/Header'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'

export default function CauseSettings() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { logout } = useAuth()
  const [form, setForm] = useState({ name: '', description: '', story: '', logo: '', targetAmount: '0', images: [] as string[] })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [newImage, setNewImage] = useState('')

  function set(key: string, val: any) { setForm(f => ({ ...f, [key]: val })) }

  useEffect(() => {
    api.cause.getProfile()
      .then(res => {
        const p = res.data
        setForm({ name: p.name || '', description: p.description || '', story: p.story || '', logo: p.logo || '', targetAmount: String(p.targetAmount || 0), images: p.images || [] })
      })
      .catch(err => { if (err.status === 401) { logout(); router.replace('/(auth)/login') } })
      .finally(() => setLoading(false))
  }, [])

  async function save() {
    setSaving(true)
    try {
      await api.cause.updateProfile({ ...form, targetAmount: parseFloat(form.targetAmount) || 0, logo: form.logo || undefined })
      Alert.alert('Guardado', 'Los cambios fueron guardados.')
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}><Text style={{ color: '#9CA3AF' }}>Cargando...</Text></View>

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <Header title="Ajustes" showBack />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 32 }} keyboardShouldPersistTaps="handled">

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Identidad</Text>
          <Input label="Nombre de la organización" value={form.name} onChangeText={v => set('name', v)} />
          <Input label="Descripción breve" value={form.description} onChangeText={v => set('description', v)} multiline />
          <Input label="Logo (URL)" value={form.logo} onChangeText={v => set('logo', v)} keyboardType="url" autoCapitalize="none" />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Historia</Text>
          <Input label="Contá quiénes son y qué hacen" value={form.story} onChangeText={v => set('story', v)} multiline style={{ height: 120, textAlignVertical: 'top', paddingTop: 10 } as any} />
          <Input label="Objetivo de recaudación ($)" value={form.targetAmount} onChangeText={v => set('targetAmount', v)} keyboardType="decimal-pad" />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Fotos</Text>
          {form.images.map((img, idx) => (
            <View key={idx} style={styles.imageRow}>
              <Text style={styles.imageUrl} numberOfLines={1}>{img}</Text>
              <TouchableOpacity onPress={() => set('images', form.images.filter((_: any, i: number) => i !== idx))}>
                <Text style={{ color: '#EF4444', fontWeight: '700', fontSize: 16 }}>×</Text>
              </TouchableOpacity>
            </View>
          ))}
          <View style={{ flexDirection: 'row', gap: 8, marginTop: 4 }}>
            <Input
              value={newImage}
              onChangeText={setNewImage}
              placeholder="https://..."
              style={{ flex: 1 } as any}
              keyboardType="url"
              autoCapitalize="none"
            />
            <TouchableOpacity
              style={styles.addImgBtn}
              onPress={() => {
                if (newImage.trim()) { set('images', [...form.images, newImage.trim()]); setNewImage('') }
              }}
            >
              <Text style={{ color: '#2D6A4F', fontWeight: '700' }}>+</Text>
            </TouchableOpacity>
          </View>
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
  imageRow: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    backgroundColor: '#F9FAFB', borderRadius: 8, padding: 8, marginBottom: 6,
  },
  imageUrl: { flex: 1, fontSize: 12, color: '#6B7280' },
  addImgBtn: {
    width: 44, height: 44, borderRadius: 10,
    backgroundColor: '#F0F7F4', borderWidth: 1.5, borderColor: '#2D6A4F',
    alignItems: 'center', justifyContent: 'center',
  },
})
