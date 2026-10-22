/**
 * WhatsApp notification service — Meta WhatsApp Business Cloud API
 * Usa plantillas aprobadas para mensajes business-initiated.
 *
 * Variables de entorno requeridas en .env:
 *   WHATSAPP_PHONE_NUMBER_ID   → ID del número de Unitia en Meta
 *   WHATSAPP_ACCESS_TOKEN      → Token permanente de la app de Meta
 *   WHATSAPP_TEMPLATE_NAME     → Nombre de la plantilla aprobada (ej: nuevo_pedido_unitia)
 */

const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID
const ACCESS_TOKEN    = process.env.WHATSAPP_ACCESS_TOKEN
const TEMPLATE_NAME   = process.env.WHATSAPP_TEMPLATE_NAME || 'nuevo_pedido_unitia'

/**
 * Envía notificación de nuevo pedido al dueño del restaurante.
 * No bloquea la respuesta al cliente si falla.
 *
 * La plantilla debe tener 4 variables en el body:
 *   {{1}} → nombre del restaurante
 *   {{2}} → nombre del cliente
 *   {{3}} → total del pedido (ej: "180.00")
 *   {{4}} → monto de la donación (ej: "9.00")
 */
async function sendOrderNotification({ to, restaurantName, customerName, subtotal, donationAmount }) {
  if (!PHONE_NUMBER_ID || !ACCESS_TOKEN || !to) return

  const phone = to.replace(/\s+/g, '').replace(/^whatsapp:/, '')
  if (!phone.startsWith('+')) {
    console.warn('[WhatsApp] Número sin formato E.164:', phone)
    return
  }

  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/${PHONE_NUMBER_ID}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to: phone,
          type: 'template',
          template: {
            name: TEMPLATE_NAME,
            language: { code: 'es_MX' },
            components: [
              {
                type: 'body',
                parameters: [
                  { type: 'text', text: restaurantName },
                  { type: 'text', text: customerName },
                  { type: 'text', text: subtotal.toFixed(2) },
                  { type: 'text', text: donationAmount.toFixed(2) },
                ],
              },
            ],
          },
        }),
      }
    )

    if (!response.ok) {
      const err = await response.json().catch(() => ({}))
      console.error('[WhatsApp] Error API:', JSON.stringify(err))
    }
  } catch (err) {
    console.error('[WhatsApp] Fallo al enviar:', err.message)
  }
}

module.exports = { sendOrderNotification }
