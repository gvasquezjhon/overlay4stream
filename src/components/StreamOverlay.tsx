import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import Lottie from 'lottie-react'
import useSound from 'use-sound'
import aplausosSound from '../assets/sounds/aplausos.mp3'
import YapeQROverlay from './YapeQROverlay'
import DonorsCarousel from './DonorsCarousel'
import BackgroundVideo from './BackgroundVideo'

interface Transaction {
 id: number
 type: string
 title: string
 message: string
 timestamp: string
 read: boolean
 transaction_id: number
 monto: number
 nombre_pagador: string
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

// Función para obtener un saludo aleatorio
function getRandomGreeting(name: string, amount: number) {
 const greetings = [
   `✨ ¡Gracias, ${name}! ✨\n\n💜 Por ese moradito de S/${amount} 💜\n\n¡Se siente el cariño en cada yape! 🙌`,
   `🎉 ¡Oe, qué buena onda ${name}! 🎉\n\n💜 Ese moradito de S/${amount} nos alegra el live 💜\n\n¡Eres grande! 🔥`,
   `💫 ¡Un moradito lleno de buena vibra! 💫\n\n💜 Llegó de parte de ${name} con S/${amount} 💜\n\n¡Gracias de corazón! ❤️`,
   `🚨 ¡Atención, atención! 🚨\n\n💜 ¡${name} se acaba de lucir con un moradito de S/${amount}! 💜\n\n¡Muchas gracias, crack! 👑`,
   `🌟 ¡Gracias, ${name}! 🌟\n\n💜 Por el moradito de S/${amount} 💜\n\n¡Se aprecia un montón! 🙏`
 ];
 
 const randomIndex = Math.floor(Math.random() * greetings.length);
 return greetings[randomIndex];
}

// Hook para manejo de WebRTC streaming - VERSIÓN CORREGIDA COMPLETA
function useWebRTCStreaming() {
  const [isStreaming, setIsStreaming] = useState(false)
  const [streamStatus, setStreamStatus] = useState<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected')
  const [error, setError] = useState<string | null>(null)
  
  const mediaStreamRef = useRef<MediaStream | null>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const pcRef = useRef<RTCPeerConnection | null>(null)
  
  // Configuración desde variables de entorno
  const omeServerIP = import.meta.env.VITE_OME_SERVER_IP || 'localhost'
  const omeSignallingPort = import.meta.env.VITE_OME_SIGNALLING_PORT || '3334'
  const omeAppName = import.meta.env.VITE_OME_APP_NAME || 'app'
  const omeStreamName = import.meta.env.VITE_OME_STREAM_NAME || 'live'

  const startStreaming = async (): Promise<void> => {
    try {
      console.log('🎥 Solicitando captura de pantalla...')
      setStreamStatus('connecting')
      setError(null)
      
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: {
          width: { ideal: 1920 },
          height: { ideal: 1080 },
          frameRate: { ideal: 30 }
        },
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 48000
        }
      })
      
      console.log('✅ Stream obtenido:', stream)
      console.log('📹 Video tracks:', stream.getVideoTracks().length)
      console.log('🔊 Audio tracks:', stream.getAudioTracks().length)
      
      // Verificar configuración de tracks
      stream.getVideoTracks().forEach((track, index) => {
        console.log(`📹 Video track ${index}:`, {
          enabled: track.enabled,
          readyState: track.readyState,
          settings: track.getSettings()
        })
      })
      
      stream.getAudioTracks().forEach((track, index) => {
        console.log(`🔊 Audio track ${index}:`, {
          enabled: track.enabled,
          readyState: track.readyState,
          settings: track.getSettings()
        })
      })
      
      mediaStreamRef.current = stream
      await connectToOME(stream)
      
    } catch (err) {
      const error = err as Error
      console.error('❌ Error:', error)
      setStreamStatus('error')
      setError(`Error de captura: ${error.message}`)
    }
  }

  const connectToOME = async (stream: MediaStream): Promise<void> => {
    return new Promise<void>((resolve, reject) => {
      try {
        const wsUrl = `wss://${omeServerIP}:${omeSignallingPort}/${omeAppName}/${omeStreamName}?direction=send`
        console.log('🔗 Conectando a OME WebSocket:', wsUrl)
        
        const ws = new WebSocket(wsUrl)
        wsRef.current = ws
        
        const pc = new RTCPeerConnection({
          iceServers: [
            // Agregar STUN público como fallback
            { urls: 'stun:stun.l.google.com:19302' }
          ],
          iceTransportPolicy: 'all',
          bundlePolicy: 'balanced',
          rtcpMuxPolicy: 'require'
        })
        pcRef.current = pc
        
        let sessionId: number | null = null
        let connectionTimeout: number | null = null
        
        connectionTimeout = window.setTimeout(() => {
          console.error('⏰ Timeout de conexión WebSocket')
          setStreamStatus('error')
          setError('Timeout de conexión')
          reject(new Error('Timeout'))
        }, 30000)
        
        // MEJORADO: Agregar audio silencioso si no hay audio
        if (stream.getAudioTracks().length === 0) {
          console.log('🔇 No hay audio, agregando audio silencioso...')
          try {
            const audioContext = new AudioContext()
            const oscillator = audioContext.createOscillator()
            const gainNode = audioContext.createGain()
            const destination = audioContext.createMediaStreamDestination()
            
            oscillator.connect(gainNode)
            gainNode.connect(destination)
            gainNode.gain.value = 0 // Silencioso
            oscillator.frequency.value = 440
            oscillator.start()
            
            const audioTrack = destination.stream.getAudioTracks()[0]
            stream.addTrack(audioTrack)
            console.log('✅ Audio silencioso agregado')
          } catch (audioError) {
            console.warn('⚠️ No se pudo agregar audio silencioso:', audioError)
          }
        }
        
        // Agregar tracks al PeerConnection
        stream.getTracks().forEach(track => {
          console.log(`➕ Agregando track: ${track.kind}`)
          const sender = pc.addTrack(track, stream)
          
          if (track.kind === 'video') {
            const params = sender.getParameters()
            if (params.encodings.length === 0) {
              params.encodings.push({})
            }
            params.encodings[0] = {
              maxBitrate: 2500000,
              maxFramerate: 30
            }
            sender.setParameters(params).catch(err => 
              console.warn('⚠️ Error configurando video encoding:', err)
            )
          }
        })
        
        // ICE candidate handling
        pc.onicecandidate = (event) => {
          if (event.candidate && ws.readyState === WebSocket.OPEN && sessionId !== null) {
            console.log('📤 Enviando ICE candidate')
            ws.send(JSON.stringify({
              id: sessionId,
              command: 'candidate',
              candidates: [{
                candidate: event.candidate.candidate,
                sdpMLineIndex: event.candidate.sdpMLineIndex,
                sdpMid: event.candidate.sdpMid
              }]
            }))
          }
        }
        
        // Estados de conexión
        pc.onconnectionstatechange = () => {
          console.log('🔄 Estado WebRTC:', pc.connectionState)
          if (pc.connectionState === 'connected') {
            if (connectionTimeout) window.clearTimeout(connectionTimeout)
            setStreamStatus('connected')
            setIsStreaming(true)
            console.log('🎉 ¡Conectado exitosamente!')
            resolve()
          } else if (pc.connectionState === 'failed' || pc.connectionState === 'disconnected') {
            if (connectionTimeout) window.clearTimeout(connectionTimeout)
            setStreamStatus('error')
            setError('Conexión WebRTC falló')
            reject(new Error('Conexión WebRTC falló'))
          }
        }
        
        pc.oniceconnectionstatechange = () => {
          console.log('🧊 ICE State:', pc.iceConnectionState)
        }
        
        // Protocolo OME
        ws.onopen = () => {
          console.log('✅ WebSocket conectado')
          ws.send(JSON.stringify({
            command: 'request_offer'
          }))
        }
        
        ws.onmessage = async (event) => {
          try {
            const message = JSON.parse(event.data)
            console.log('📨 Mensaje completo de OME:', message)
            
            if (message.command === 'offer') {
              sessionId = message.id
              console.log('📥 Offer recibido, Session ID:', sessionId)
              
              // PASO 1: PRIMERO configurar remote description
              await pc.setRemoteDescription(new RTCSessionDescription(message.sdp))
              console.log('✅ Remote description configurada')
              
              // PASO 2: DESPUÉS configurar ICE servers (si vienen en el offer)
              let iceServers: RTCIceServer[] = [
                { urls: 'stun:stun.l.google.com:19302' }
              ]
              
              const rawIceServers = message.iceServers || message.ice_servers || []
              
              rawIceServers.forEach((server: any) => {
                const normalizedServer: RTCIceServer = {
                  urls: server.urls,
                  username: server.username || server.user_name,
                  credential: server.credential
                }
                
                // Filtrar URLs inválidas
                if (Array.isArray(normalizedServer.urls)) {
                  normalizedServer.urls = normalizedServer.urls.filter((url: string) => 
                    !url.includes('0.0.0.0')
                  )
                } else if (typeof normalizedServer.urls === 'string') {
                  if (normalizedServer.urls.includes('0.0.0.0')) {
                    console.warn('⚠️ Saltando ICE server con IP inválida:', normalizedServer.urls)
                    return
                  }
                }
                
                if (normalizedServer.urls && 
                    normalizedServer.urls.length > 0 && 
                    normalizedServer.username && 
                    normalizedServer.credential) {
                  iceServers.push(normalizedServer)
                  console.log('✅ ICE server válido agregado:', normalizedServer)
                }
              })
              
              // Configurar ICE servers
              try {
                const config = pc.getConfiguration()
                config.iceServers = iceServers
                pc.setConfiguration(config)
                console.log('✅ ICE servers configurados exitosamente:', iceServers.length)
              } catch (configError) {
                console.warn('⚠️ Error configurando ICE servers, usando solo STUN:', configError)
                const config = pc.getConfiguration()
                config.iceServers = [{ urls: 'stun:stun.l.google.com:19302' }]
                pc.setConfiguration(config)
              }
              
              // PASO 3: AHORA SÍ agregar ICE candidates (después de setRemoteDescription)
              if (message.candidates && message.candidates.length > 0) {
                console.log('🧊 ICE candidates iniciales:', message.candidates.length)
                for (const candidate of message.candidates) {
                  try {
                    // Filtrar candidates inválidos
                    if (!candidate.candidate.includes('0.0.0.0')) {
                      await pc.addIceCandidate(new RTCIceCandidate(candidate))
                      console.log('✅ ICE candidate agregado:', candidate.candidate)
                    } else {
                      console.warn('⚠️ ICE candidate con IP inválida saltado:', candidate.candidate)
                    }
                  } catch (err) {
                    console.warn('⚠️ Error agregando candidate inicial:', err)
                  }
                }
              }
              
              // PASO 4: Crear answer
              const answer = await pc.createAnswer()
              await pc.setLocalDescription(answer)
              
              console.log('📤 Enviando answer...')
              ws.send(JSON.stringify({
                id: sessionId,
                command: 'answer',
                sdp: {
                  type: answer.type,
                  sdp: answer.sdp
                }
              }))
              
            } else if (message.command === 'candidate') {
              // ICE candidates adicionales también van después de setRemoteDescription
              if (message.candidates && message.candidates.length > 0) {
                console.log('📥 ICE candidates adicionales:', message.candidates.length)
                for (const candidate of message.candidates) {
                  try {
                    if (!candidate.candidate.includes('0.0.0.0')) {
                      await pc.addIceCandidate(new RTCIceCandidate(candidate))
                      console.log('✅ ICE candidate adicional agregado')
                    }
                  } catch (err) {
                    console.warn('⚠️ Error agregando candidate adicional:', err)
                  }
                }
              }
            } else if (message.error || message.code === 400) {
              console.error('❌ Error del servidor OME:', message)
              const errorMsg = message.error || message.message || 'Error desconocido del servidor'
              setStreamStatus('error')
              setError(`Error del servidor: ${errorMsg}`)
              reject(new Error(`Error del servidor: ${errorMsg}`))
            } else {
              console.log('📨 Mensaje no reconocido de OME:', message)
            }
            
          } catch (err) {
            console.error('❌ Error procesando mensaje JSON:', err)
            console.log('📨 Mensaje raw recibido:', event.data)
          }
        }
        
        ws.onclose = (event) => {
          console.log('🔌 WebSocket cerrado:', event.code, event.reason)
          if (connectionTimeout) window.clearTimeout(connectionTimeout)
          setStreamStatus('disconnected')
          setIsStreaming(false)
        }
        
        ws.onerror = (error) => {
          console.error('❌ Error WebSocket:', error)
          if (connectionTimeout) window.clearTimeout(connectionTimeout)
          setStreamStatus('error')
          setError('Error de conexión WebSocket')
          reject(error)
        }
        
      } catch (err) {
        const error = err as Error
        console.error('❌ Error configurando conexión:', error)
        setStreamStatus('error')
        setError(`Error: ${error.message}`)
        reject(error)
      }
    })
  }

  const stopStreaming = (): void => {
    console.log('🛑 Deteniendo streaming...')
    
    // Detener tracks de media
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach(track => {
        console.log(`🛑 Deteniendo track: ${track.kind}`)
        track.stop()
      })
      mediaStreamRef.current = null
    }
    
    // Cerrar WebSocket
    if (wsRef.current) {
      wsRef.current.close(1000, 'Usuario detuvo streaming')
      wsRef.current = null
    }
    
    // Cerrar PeerConnection
    if (pcRef.current) {
      pcRef.current.close()
      pcRef.current = null
    }
    
    setIsStreaming(false)
    setStreamStatus('disconnected')
    setError(null)
  }

  // Limpiar al desmontar
  useEffect(() => {
    return () => {
      stopStreaming()
    }
  }, [])

  return {
    isStreaming,
    streamStatus,
    error,
    startStreaming,
    stopStreaming
  }
}

// Componente para cada tipo de notificación
function DonationNotification({ transaction, onComplete }: NotificationProps) {
 const [playAplausos] = useSound(aplausosSound, { volume: 0.8 })
 const [isVisible, setIsVisible] = useState(true)
 const [stage, setStage] = useState<'animation'|'text'>(('animation'))
 const animationRef = useRef<any>(getRandomAnimation())
 
 // Obtener nombre del donante del campo nombre_pagador
 const donorName = transaction.nombre_pagador || 'Donante Anónimo'
 const greeting = useRef(getRandomGreeting(donorName, transaction.monto))

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
                 {/* Fondo oscuro con opacidad para mejorar contraste */}
                 <div className="w-full h-screen fixed inset-0 bg-gradient-to-b from-black/80 to-purple-900/70 backdrop-blur-md"></div>
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
                 {/* Fondo oscuro con opacidad para mejorar contraste */}
                 <div className="w-full h-screen fixed inset-0 bg-gradient-to-b from-black/80 to-purple-900/70 backdrop-blur-md"></div>
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
                 
                 {/* Texto de agradecimiento con mejor contraste y responsive */}
                 <div className="z-10 text-center max-w-6xl mx-auto px-4 flex items-center justify-center h-full">
                   <motion.h2 
                     initial={{ 
                       opacity: 0, 
                       scale: 0.8,
                       y: 50 
                     }}
                     animate={{ 
                       opacity: 1, 
                       scale: 1,
                       y: 0,
                       transition: {
                         type: "spring",
                         stiffness: 100,
                         damping: 10,
                         duration: 0.5
                       }
                     }}
                     exit={{ 
                       opacity: 0, 
                       scale: 0.8,
                       y: 50,
                       transition: {
                         duration: 0.3
                       }
                     }}
                     className="font-['Montserrat'] 
                       text-[4vw] md:text-[3.5vw] lg:text-[3vw] xl:text-[2.5vw] 
                       font-extrabold text-white
                       text-center text-shadow-strong drop-shadow-xl
                       whitespace-pre-line leading-[1.3] 
                       break-words
                       animate-pulse-soft
                       border-b-4 border-purple-500/50 pb-2 px-4
                       bg-black/30 rounded-xl"
                   >
                     {greeting.current}
                   </motion.h2>
                 </div>
               </div>
             )}

             {/* Barra de progreso para el tiempo más sutil */}
             {stage === 'text' && (
               <motion.div
                 className="h-2 bg-purple-900/50 rounded-full overflow-hidden mt-6 max-w-md mx-auto fixed bottom-8 left-0 right-0 border border-purple-500/40 shadow-lg"
                 initial={{ width: "100%" }}
               >
                 <motion.div
                   className="h-full bg-gradient-to-r from-purple-500 to-indigo-500 rounded-full"
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
 
 .text-shadow-sm {
   text-shadow: 0 1px 3px rgba(0,0,0,0.7);
 }
 
 .text-shadow-strong {
   text-shadow: 
     0 2px 4px rgba(0,0,0,0.8),
     0 4px 8px rgba(0,0,0,0.6),
     0 8px 16px rgba(0,0,0,0.4);
 }
 
 .drop-shadow-lg {
   filter: drop-shadow(0 4px 6px rgba(0, 0, 0, 0.5));
 }
 
 .drop-shadow-xl {
   filter: drop-shadow(0 8px 16px rgba(0, 0, 0, 0.8));
 }
 
 .shadow-glow {
   box-shadow: 0 0 8px rgba(168, 85, 247, 0.5);
 }
`;

// Componente principal del Overlay
export default function StreamOverlay() {
 const [notifications, setNotifications] = useState<Transaction[]>([])
 const [token, setToken] = useState<string | null>(null)
 const wsRef = useRef<WebSocket | null>(null)
 const [useLocalVideo, setUseLocalVideo] = useState<boolean>(false)
 const [userInteracted, setUserInteracted] = useState(false)
 
 // Hook de streaming
 const { 
   isStreaming, 
   streamStatus, 
   error: streamingError, 
   startStreaming, 
   stopStreaming 
 } = useWebRTCStreaming()

 // Extraer token de la URL y verificar configuración de video local
 useEffect(() => {
   const urlParams = new URLSearchParams(window.location.search)
   const urlToken = urlParams.get('token')
   if (urlToken) {
     setToken(urlToken)
   }
   
   // Verificar si se debe usar video local desde variables de entorno
   const localVideo = import.meta.env.VITE_LOCAL_VIDEO === '1'
   setUseLocalVideo(localVideo)
 }, [])

 // Conectar al WebSocket para notificaciones
 useEffect(() => {
   if (!token) return

   let isComponentMounted = true;
   let reconnectTimeout: number | null = null;
   
   // Obtener URL del WebSocket desde variables de entorno
   const wsUrl = import.meta.env.VITE_WS_URL || 'ws://localhost:8000';

   const connectWebSocket = () => {
     try {
       // Limpiar cualquier conexión existente
       if (wsRef.current && wsRef.current.readyState !== WebSocket.CLOSED) {
         wsRef.current.close();
       }

       // Usar la URL del WebSocket desde variables de entorno
       wsRef.current = new WebSocket(`${wsUrl}/api/v1/ws?token=${token}`)
       
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
     // Obtener URL de la API desde variables de entorno
     const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
     
     // Marcar como leída en el servidor
     if (token) {
       const response = await fetch(
         `${apiUrl}/api/v1/notifications/${notification.id}/read`,
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

 // Función para manejar la interacción del usuario
 const handleUserInteraction = () => {
   setUserInteracted(true);
 };

 // Control de streaming
 const handleStreamingToggle = async () => {
   if (isStreaming) {
     stopStreaming()
   } else {
     await startStreaming()
   }
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
 
 // Si el usuario no ha interactuado, mostrar botón
 if (!userInteracted) {
   return (
     <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
       <div className="bg-white rounded-lg p-6 text-center max-w-md">
         <h2 className="text-xl font-bold text-gray-800 mb-2">
           Activar Overlay de Streaming
         </h2>
         <p className="text-gray-600 mb-4">
           Haz clic para activar sonidos y habilitar el control de streaming
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
     
     {/* Video de fondo local o fondo transparente para captura */}
     {useLocalVideo ? (
       <BackgroundVideo videoSrc="/uploads/video.mp4" />
     ) : (
       <div className="absolute inset-0 bg-transparent" />
     )}
     
     {/* Control de Streaming */}
     <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-50">
       <motion.div 
         className="bg-gradient-to-br from-black/80 to-purple-900/80 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30"
         initial={{ opacity: 0, y: -20 }}
         animate={{ opacity: 1, y: 0 }}
       >
         <div className="flex items-center gap-4">
           <button
             onClick={handleStreamingToggle}
             disabled={streamStatus === 'connecting'}
             className={`px-6 py-2 rounded-lg font-bold text-white transition-all ${
               isStreaming 
                 ? 'bg-red-600 hover:bg-red-700' 
                 : 'bg-green-600 hover:bg-green-700'
             } ${streamStatus === 'connecting' ? 'opacity-50 cursor-not-allowed' : ''}`}
           >
             {streamStatus === 'connecting' ? '🔄 Conectando...' : 
              isStreaming ? '🛑 Detener Stream' : '🎥 Iniciar Stream'}
           </button>
           
           <div className="flex items-center gap-2">
             <div className={`w-3 h-3 rounded-full ${
               streamStatus === 'connected' ? 'bg-green-400 animate-pulse' :
               streamStatus === 'connecting' ? 'bg-yellow-400 animate-pulse' :
               streamStatus === 'error' ? 'bg-red-400' : 'bg-gray-400'
             }`} />
             <span className="text-white text-sm font-medium">
               {streamStatus === 'connected' ? 'En vivo' :
                streamStatus === 'connecting' ? 'Conectando' :
                streamStatus === 'error' ? 'Error' : 'Desconectado'}
             </span>
           </div>
         </div>
         
         {streamingError && (
           <div className="mt-2 text-red-300 text-xs">
             Error: {streamingError}
           </div>
         )}
       </motion.div>
     </div>
     
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

     {/* Componente QR de Yape */}
     <YapeQROverlay token={token} />
     
     {/* Componente Carousel de Donadores */}
     <DonorsCarousel token={token} />
     
     {/* Indicador de conexión mejorado */}
     <div className="fixed bottom-4 left-4 z-40">
       <div className="bg-black/50 rounded-full px-3 py-1 flex items-center space-x-2">
         <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
         <span className="text-white text-xs">WebSocket OK</span>
         {isStreaming && (
           <>
             <div className="w-1 h-4 bg-white/30" />
             <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
             <span className="text-white text-xs">🔴 EN VIVO</span>
           </>
         )}
       </div>
     </div>
   </div>
 )
}