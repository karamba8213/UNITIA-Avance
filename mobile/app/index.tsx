import { useEffect } from 'react'
import { View, ActivityIndicator } from 'react-native'
import { useRouter } from 'expo-router'
import { useAuth } from '../lib/context'

export default function Index() {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (loading) return
    if (!user) {
      router.replace('/(auth)/login')
    } else if (user.role === 'RESTAURANT') {
      router.replace('/(restaurant)/dashboard')
    } else if (user.role === 'CAUSE') {
      router.replace('/(cause)/dashboard')
    }
  }, [user, loading])

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#F0F7F4' }}>
      <ActivityIndicator size="large" color="#2D6A4F" />
    </View>
  )
}
