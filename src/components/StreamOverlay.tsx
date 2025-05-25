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
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 50 }}
          className="fixed bottom-0 left-0 right-0 z-50 flex justify-center"
        >
          <div className="relative w-full max-w-5xl">
            {/* Contenedor principal sin bordes ni fondo */}
            <motion.div className="p-4">
              {stage === 'animation' ? (
                <div className="flex items-center justify-center">
                  {/* Animación Lottie a pantalla completa sin texto */}
                  <div className="w-full h-screen fixed inset-0 flex items-center justify-center">
                    <Lottie
                      animationData={animationRef.current}
                      loop={true}
                      autoplay={true}
                      style={{ width: '100%', height: '100%' }}
                      rendererSettings={{
                        preserveAspectRatio: 'xMidYMid meet'
                      }}
                    />
                  </div>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center relative h-screen fixed inset-0">
                  {/* Animación de serpentinas a pantalla completa */}
                  <div className="absolute inset-0 z-0">
                    <Lottie
                      animationData={serpentinas}
                      loop={true}
                      autoplay={true}
                      style={{ width: '100%', height: '100%' }}
                      rendererSettings={{
                        preserveAspectRatio: 'xMidYMid slice'
                      }}
                    />
                  </div>
                  
                  {/* Texto de agradecimiento con mejor contraste */}
                  <div className="z-10 text-center">
                    <h2 className="font-['Montserrat'] text-5xl font-extrabold text-white mb-4 text-shadow drop-shadow-lg">
                      ¡GRACIAS POR TU DONACIÓN!
                    </h2>
                    <p className="font-['Poppins'] text-3xl text-white mb-6 drop-shadow-lg">
                      {donorName}
                    </p>
                    <div className="backdrop-blur-md rounded-full px-6 py-3 inline-block">
                      <span className="text-white font-bold text-4xl drop-shadow-lg">
                        S/. {transaction.monto}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Barra de progreso para el tiempo más sutil */}
              {stage === 'text' && (
                <motion.div
                  className="h-1 bg-white/10 rounded-full overflow-hidden mt-6 max-w-md mx-auto fixed bottom-8 left-0 right-0"
                  initial={{ width: "100%" }}
                >
                  <motion.div
                    className="h-full bg-white/40 rounded-full"
                    initial={{ width: "100%" }}
                    animate={{ width: "0%" }}
                    transition={{ duration: 5, ease: "linear" }}
                  />
                </motion.div>
              )}
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
    text-shadow: 0 2px 8px rgba(0,0,0,0.5);
  }
  
  .drop-shadow-lg {
    filter: drop-shadow(0 4px 6px rgba(0, 0, 0, 0.5));
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
