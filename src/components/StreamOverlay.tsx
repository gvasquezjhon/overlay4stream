import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Heart, Star, Sparkles, Gift, Crown, Zap } from 'lucide-react'

interface Transaction {
  id: number
  type: string
  title: string
  message: string
  timestamp: string
  read: boolean
  transaction_id: number
  monto: number
}

interface NotificationProps {
  transaction: Transaction
  onComplete: () => void
}

// Hook personalizado para texto a voz usando Web Speech API
function useSpeech() {
  const speak = (text: string) => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(text)
      utterance.rate = 0.9
      utterance.pitch = 1.1
      utterance.volume = 0.8
      
      // Buscar una voz en español si está disponible
      const voices = speechSynthesis.getVoices()
      const spanishVoice = voices.find(voice => voice.lang.includes('es'))
      if (spanishVoice) {
        utterance.voice = spanishVoice
      }
      
      speechSynthesis.speak(utterance)
    }
  }

  return { speak }
}

// Componente para cada tipo de notificación
function DonationNotification({ transaction, onComplete }: NotificationProps) {
  const { speak } = useSpeech()
  const [isVisible, setIsVisible] = useState(true)
  
  // Determinar el tipo de diseño basado en el monto
  const getDesignType = (amount: number) => {
    if (amount >= 3.1) return 'pro'
    if (amount >= 1.1) return 'standard'
    return 'basic'
  }

  const designType = getDesignType(transaction.monto)

  // Configuración de diseños
  const designs = {
    basic: {
      bgGradient: 'from-blue-400 to-purple-500',
      icon: Heart,
      iconColor: 'text-white',
      duration: 4000,
      sparkles: 5,
      shadow: 'shadow-lg',
      scale: 'scale-100'
    },
    standard: {
      bgGradient: 'from-yellow-400 via-orange-500 to-red-500',
      icon: Star,
      iconColor: 'text-yellow-100',
      duration: 6000,
      sparkles: 10,
      shadow: 'shadow-xl',
      scale: 'scale-105'
    },
    pro: {
      bgGradient: 'from-purple-600 via-pink-600 to-red-600',
      icon: Crown,
      iconColor: 'text-yellow-300',
      duration: 8000,
      sparkles: 20,
      shadow: 'shadow-2xl',
      scale: 'scale-110'
    }
  }

  const design = designs[designType]
  const IconComponent = design.icon

  // Extraer nombre del donante del mensaje
  const extractDonorName = (message: string) => {
    const match = message.match(/de (.+)$/)
    return match ? match[1] : 'Donante Anónimo'
  }

  const donorName = extractDonorName(transaction.message)

  // Texto a voz
  useEffect(() => {
    const speechText = `¡Gracias ${donorName} por tu donación de ${transaction.monto} soles! ¡Eres increíble!`
    
    setTimeout(() => {
      speak(speechText)
    }, 500)

    // Auto-ocultar después del tiempo especificado
    const timer = setTimeout(() => {
      setIsVisible(false)
      setTimeout(onComplete, 500) // Tiempo para la animación de salida
    }, design.duration)

    return () => clearTimeout(timer)
  }, [transaction, speak, onComplete, design.duration, donorName])

  // Componente de partículas/sparkles
  const SparklesComponent = ({ count }: { count: number }) => (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <motion.div
          key={i}
          className="absolute"
          initial={{ 
            opacity: 0, 
            scale: 0,
            x: Math.random() * 400 - 200,
            y: Math.random() * 300 - 150
          }}
          animate={{ 
            opacity: [0, 1, 0], 
            scale: [0, 1, 0],
            rotate: 360,
            x: Math.random() * 600 - 300,
            y: Math.random() * 400 - 200
          }}
          transition={{ 
            duration: 3, 
            delay: Math.random() * 2,
            repeat: Infinity,
            repeatDelay: Math.random() * 3
          }}
        >
          <Sparkles className="w-4 h-4 text-yellow-300" />
        </motion.div>
      ))}
    </>
  )

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 0, y: -100, scale: 0.8 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -50, scale: 0.9 }}
          className="fixed top-8 right-8 z-50"
        >
          <div className="relative">
            {/* Partículas de fondo */}
            <SparklesComponent count={design.sparkles} />
            
            {/* Notificación principal */}
            <motion.div
              animate={{ 
                scale: [1, 1.02, 1],
                rotate: designType === 'pro' ? [0, 1, -1, 0] : 0
              }}
              transition={{ 
                duration: 2, 
                repeat: Infinity,
                ease: "easeInOut"
              }}
              className={`
                bg-gradient-to-r ${design.bgGradient} 
                rounded-2xl p-6 ${design.shadow} 
                border-2 border-white/20 backdrop-blur-sm
                max-w-sm transform ${design.scale}
                ${designType === 'pro' ? 'animate-pulse' : ''}
              `}
            >
              {/* Header con icono */}
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <motion.div
                    animate={{ rotate: 360 }}
                    transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                    className={`p-2 rounded-full bg-white/20 ${design.iconColor}`}
                  >
                    <IconComponent className="w-6 h-6" />
                  </motion.div>
                  <div>
                    <h3 className="text-white font-bold text-lg">
                      {designType === 'pro' ? '¡SÚPER DONACIÓN!' : 
                       designType === 'standard' ? '¡Gran Donación!' : '¡Nueva Donación!'}
                    </h3>
                    <p className="text-white/80 text-sm">¡Gracias por tu apoyo!</p>
                  </div>
                </div>
                
                {/* Monto destacado */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: [0, 1.2, 1] }}
                  transition={{ delay: 0.3, duration: 0.5 }}
                  className="bg-white/20 rounded-xl px-3 py-2"
                >
                  <span className="text-white font-bold text-xl">
                    S/. {transaction.monto}
                  </span>
                </motion.div>
              </div>

              {/* Información del donante */}
              <div className="bg-white/10 rounded-xl p-4 mb-4">
                <p className="text-white font-semibold text-center">
                  {donorName}
                </p>
                <p className="text-white/70 text-sm text-center mt-1">
                  ¡Eres increíble! 🎉
                </p>
              </div>

              {/* Barra de progreso para el tiempo */}
              <motion.div
                className="h-1 bg-white/20 rounded-full overflow-hidden"
                initial={{ width: "100%" }}
              >
                <motion.div
                  className="h-full bg-white/60 rounded-full"
                  initial={{ width: "100%" }}
                  animate={{ width: "0%" }}
                  transition={{ duration: design.duration / 1000, ease: "linear" }}
                />
              </motion.div>

              {/* Efectos especiales para Pro */}
              {designType === 'pro' && (
                <motion.div
                  className="absolute -inset-1 bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 rounded-2xl opacity-30 blur-sm"
                  animate={{ rotate: 360 }}
                  transition={{ duration: 4, repeat: Infinity, ease: "linear" }}
                />
              )}
            </motion.div>

            {/* Efectos adicionales para Standard y Pro */}
            {(designType === 'standard' || designType === 'pro') && (
              <motion.div
                className="absolute inset-0 pointer-events-none"
                initial={{ opacity: 0 }}
                animate={{ opacity: [0, 1, 0] }}
                transition={{ duration: 1, repeat: Infinity, repeatDelay: 1 }}
              >
                <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-2">
                  <Zap className="w-8 h-8 text-yellow-300" />
                </div>
              </motion.div>
            )}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Componente principal del Overlay
export default function StreamOverlay() {
  const [notifications, setNotifications] = useState<Transaction[]>([])
  const [token, setToken] = useState<string | null>(null)
  const wsRef = useRef<WebSocket | null>(null)

  // Extraer token de la URL
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    const urlToken = urlParams.get('token')
    if (urlToken) {
      setToken(urlToken)
    }
  }, [])

  // Conectar al WebSocket
  useEffect(() => {
    if (!token) return

    const connectWebSocket = () => {
      try {
        // Ajusta esta URL a tu servidor WebSocket
        wsRef.current = new WebSocket(`ws://localhost:8000/api/v1/ws?token=${token}`)
        
        wsRef.current.onopen = () => {
          console.log('🔗 Conexión WebSocket abierta')
        }

        wsRef.current.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            console.log('📨 Mensaje recibido:', data)
            
            if (data.type === 'transaction') {
              setNotifications(prev => [...prev, data])
            }
          } catch (error) {
            console.error('Error parsing message:', error)
          }
        }

        wsRef.current.onclose = () => {
          console.log('🔌 Conexión WebSocket cerrada. Reintentando...')
          setTimeout(connectWebSocket, 3000)
        }

        wsRef.current.onerror = (error) => {
          console.error('❌ Error WebSocket:', error)
        }
      } catch (error) {
        console.error('Error conectando WebSocket:', error)
        setTimeout(connectWebSocket, 3000)
      }
    }

    connectWebSocket()

    return () => {
      if (wsRef.current) {
        wsRef.current.close()
      }
    }
  }, [token])

  // Remover notificación completada
  const handleNotificationComplete = (transactionId: number) => {
    setNotifications(prev => prev.filter(n => n.id !== transactionId))
  }

  // Si no hay token, mostrar mensaje
  if (!token) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
        <div className="bg-white rounded-lg p-6 text-center">
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            Token requerido
          </h2>
          <p className="text-gray-600">
            Agrega ?token=tu_token a la URL
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="relative w-screen h-screen overflow-hidden">
      {/* Fondo transparente para OBS */}
      <div className="absolute inset-0 bg-transparent" />
      
      {/* Notificaciones */}
      <AnimatePresence>
        {notifications.map((notification, index) => (
          <motion.div
            key={notification.id}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{ zIndex: 1000 + index }}
          >
            <DonationNotification
              transaction={notification}
              onComplete={() => handleNotificationComplete(notification.id)}
            />
          </motion.div>
        ))}
      </AnimatePresence>

      {/* Indicador de conexión */}
      <div className="fixed bottom-4 left-4 z-40">
        <div className="bg-black/50 rounded-full px-3 py-1 flex items-center space-x-2">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
          <span className="text-white text-xs">Conectado</span>
        </div>
      </div>
    </div>
  )
}