import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import Lottie from 'lottie-react'
import useSound from 'use-sound'
import aplausosSound from '../assets/sounds/aplausos.mp3'

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


// Importar animaciones
import conejoLentes from '../assets/lotties/conejo-lentes.json'
import elefante from '../assets/lotties/elefante.json'
import gatito from '../assets/lotties/gatito.json'
import iguana from '../assets/lotties/iguana.json'
import serpentinas from '../assets/lotties/serpentinas.json'

// Función para seleccionar una animación aleatoria
function getRandomAnimation() {
  const animations = [
    conejoLentes,
    elefante,
    gatito,
    iguana
  ]
  
  const randomIndex = Math.floor(Math.random() * animations.length)
  return animations[randomIndex]
}

// Componente para cada tipo de notificación
function DonationNotification({ transaction, onComplete }: NotificationProps) {
  const [playAplausos] = useSound(aplausosSound, { volume: 0.8 })
  const [isVisible, setIsVisible] = useState(true)
  const [stage, setStage] = useState<'animation'|'text'>(('animation'))
  const animationRef = useRef<any>(getRandomAnimation())
  
  // Extraer nombre del donante del mensaje
  const extractDonorName = (message: string) => {
    const match = message.match(/de (.+)$/)
    return match ? match[1] : 'Donante Anónimo'
  }

  const donorName = extractDonorName(transaction.message)

  // Reproducir sonido y gestionar animaciones
  useEffect(() => {
    let animationTimer: number;
    let hideTimer: number;
    let completeTimer: number;
    
    try {
      // Reproducir sonido de aplausos usando la biblioteca use-sound
      playAplausos();
    } catch (error) {
      console.error("Error al reproducir sonido:", error);
    }

    // Mostrar animación por 5 segundos, luego mostrar texto
    animationTimer = window.setTimeout(() => {
      setStage('text')
    }, 5000)

    // Auto-ocultar después de 10 segundos en total
    hideTimer = window.setTimeout(() => {
      setIsVisible(false)
      completeTimer = window.setTimeout(onComplete, 500) // Tiempo para la animación de salida
    }, 10000)

    return () => {
      window.clearTimeout(animationTimer)
      window.clearTimeout(hideTimer)
      window.clearTimeout(completeTimer)
    }
  }, [transaction, playAplausos, onComplete])

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 0, y: -50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -50 }}
          className="fixed top-0 left-0 right-0 z-50 flex justify-center"
        >
          <div className="relative w-full max-w-4xl">
            {/* Contenedor principal */}
            <motion.div
              className="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 
                        rounded-b-2xl p-6 shadow-2xl border-2 border-white/20 backdrop-blur-sm"
            >
              {stage === 'animation' ? (
                <div className="flex flex-col items-center justify-center">
                  {/* Animación Lottie */}
                  <div className="w-64 h-64">
                    <Lottie
                      animationData={animationRef.current}
                      loop={true}
                      autoplay={true}
                    />
                  </div>
                  
                  {/* Monto destacado */}
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: [0, 1.2, 1] }}
                    transition={{ delay: 0.3, duration: 0.5 }}
                    className="bg-white/20 rounded-xl px-5 py-3 mt-4"
                  >
                    <span className="text-white font-bold text-2xl">
                      S/. {transaction.monto}
                    </span>
                  </motion.div>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center relative">
                  {/* Animación de serpentinas */}
                  <div className="absolute inset-0 z-0">
                    <Lottie
                      animationData={serpentinas}
                      loop={true}
                      autoplay={true}
                    />
                  </div>
                  
                  {/* Texto de agradecimiento */}
                  <div className="z-10 text-center p-8">
                    <h2 className="font-['Montserrat'] text-4xl font-extrabold text-white mb-4 text-shadow">
                      ¡GRACIAS POR TU DONACIÓN!
                    </h2>
                    <p className="font-['Poppins'] text-2xl text-white/90 mb-6">
                      {donorName}
                    </p>
                    <div className="bg-white/20 rounded-xl px-5 py-3 inline-block">
                      <span className="text-white font-bold text-3xl">
                        S/. {transaction.monto}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Barra de progreso para el tiempo */}
              <motion.div
                className="h-2 bg-white/20 rounded-full overflow-hidden mt-4"
                initial={{ width: "100%" }}
              >
                <motion.div
                  className="h-full bg-white/60 rounded-full"
                  initial={{ width: "100%" }}
                  animate={{ width: "0%" }}
                  transition={{ duration: stage === 'animation' ? 5 : 5, ease: "linear" }}
                />
              </motion.div>
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Importar fuentes
const fontStyles = `
  @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400;700;800&family=Poppins:wght@400;600&display=swap');

  .text-shadow {
    text-shadow: 0 2px 4px rgba(0,0,0,0.3);
  }
`;

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

    let isComponentMounted = true;
    let reconnectTimeout: number | null = null;

    const connectWebSocket = () => {
      try {
        // Limpiar cualquier conexión existente
        if (wsRef.current && wsRef.current.readyState !== WebSocket.CLOSED) {
          wsRef.current.close();
        }

        // Ajusta esta URL a tu servidor WebSocket
        wsRef.current = new WebSocket(`ws://localhost:8000/api/v1/ws?token=${token}`)
        
        wsRef.current.onopen = () => {
          console.log('🔗 Conexión WebSocket abierta')
        }

        wsRef.current.onmessage = (event) => {
          if (!isComponentMounted) return;
          
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

        wsRef.current.onclose = (event) => {
          console.log('🔌 Conexión WebSocket cerrada. Reintentando...', event.code, event.reason)
          
          // Solo reconectar si el componente sigue montado
          if (isComponentMounted) {
            if (reconnectTimeout) window.clearTimeout(reconnectTimeout);
            reconnectTimeout = window.setTimeout(connectWebSocket, 3000);
          }
        }

        wsRef.current.onerror = (error) => {
          console.error('❌ Error WebSocket:', error)
          
          // Cerrar la conexión con error para que se active onclose y se reconecte
          if (wsRef.current) {
            wsRef.current.close();
          }
        }
      } catch (error) {
        console.error('Error conectando WebSocket:', error)
        
        // Solo reconectar si el componente sigue montado
        if (isComponentMounted) {
          if (reconnectTimeout) window.clearTimeout(reconnectTimeout);
          reconnectTimeout = window.setTimeout(connectWebSocket, 3000);
        }
      }
    }

    connectWebSocket()

    // Limpieza al desmontar el componente
    return () => {
      isComponentMounted = false;
      
      if (reconnectTimeout) {
        window.clearTimeout(reconnectTimeout);
      }
      
      if (wsRef.current) {
        // Desactivar todos los listeners antes de cerrar
        wsRef.current.onopen = null;
        wsRef.current.onmessage = null;
        wsRef.current.onclose = null;
        wsRef.current.onerror = null;
        
        // Cerrar la conexión
        wsRef.current.close();
        wsRef.current = null;
      }
    }
  }, [token])

  // Marcar notificación como leída y removerla
  const handleNotificationComplete = async (notification: Transaction) => {
    try {
      // Marcar como leída en el servidor
      if (token) {
        const response = await fetch(
          `http://localhost:8000/api/v1/notifications/${notification.id}/read`,
          {
            method: 'PUT',
            headers: {
              'accept': 'application/json',
              'Authorization': `Bearer ${token}`
            }
          }
        );
        
        if (response.ok) {
          console.log(`✅ Notificación ${notification.id} marcada como leída`);
        } else {
          console.error(`❌ Error al marcar notificación ${notification.id} como leída:`, 
            await response.text());
        }
      }
    } catch (error) {
      console.error('Error al marcar notificación como leída:', error);
    } finally {
      // Remover de la lista local independientemente del resultado
      setNotifications(prev => prev.filter(n => n.id !== notification.id));
    }
  }

  // Estado para controlar si el usuario ha interactuado
  const [userInteracted, setUserInteracted] = useState(false);
  
  // Función para manejar la interacción del usuario
  const handleUserInteraction = () => {
    setUserInteracted(true);
  };
  
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
  
  // Si el usuario no ha interactuado, mostrar botón
  if (!userInteracted) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
        <div className="bg-white rounded-lg p-6 text-center">
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            Activar sonidos
          </h2>
          <p className="text-gray-600 mb-4">
            Haz clic en el botón para activar los sonidos del overlay
          </p>
          <button 
            onClick={handleUserInteraction}
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded"
          >
            Activar
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="relative w-screen h-screen overflow-hidden">
      {/* Estilos de fuentes */}
      <style dangerouslySetInnerHTML={{ __html: fontStyles }} />
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
              onComplete={() => handleNotificationComplete(notification)}
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
