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

// Hook para manejo de WebRTC streaming a OME
function useWebRTCToOME() {
  const [isStreaming, setIsStreaming] = useState(false)
  const [streamStatus, setStreamStatus] = useState<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected')
  const [error, setError] = useState<string | null>(null)
  
  const mediaStreamRef = useRef<MediaStream | null>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const pcRef = useRef<RTCPeerConnection | null>(null)
  
  // Configuración desde variables de entorno
  const omeServerIP = import.meta.env.VITE_OME_SERVER_IP || 'tvlive.gpw.cloud'
  const omeSignallingPort = import.meta.env.VITE_OME_SIGNALLING_PORT || '3334'
  const omeAppName = import.meta.env.VITE_OME_APP_NAME || 'app'
  const omeStreamName = import.meta.env.VITE_OME_STREAM_NAME || 'live'

  const startStreaming = async () => {
    try {
      setStreamStatus('connecting')
      setError(null)
      
      console.log('🎥 Iniciando captura de pantalla...')
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
      
      mediaStreamRef.current = stream
      await connectToOME(stream)
      
      stream.getVideoTracks()[0].addEventListener('ended', () => {
        console.log('🛑 Captura de pantalla detenida por el usuario')
        stopStreaming()
      })
      
    } catch (error) {
      console.error('❌ Error al iniciar streaming:', error)
      setError(error instanceof Error ? error.message : 'Error desconocido')
      setStreamStatus('error')
    }
  }

  const connectToOME = async (stream: MediaStream) => {
    return new Promise<void>((resolve, reject) => {
      try {
        const wsUrl = `wss://${omeServerIP}:${omeSignallingPort}/${omeAppName}/${omeStreamName}?direction=send&transport=tcp`
        console.log('🔗 Conectando a OME:', wsUrl)
        
        const ws = new WebSocket(wsUrl)
        wsRef.current = ws
        
        const pc = new RTCPeerConnection({
          iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' },
            {
              urls: 'turn:173.224.125.72:3478?transport=tcp',
              username: 'ome',
              credential: 'airen'
            }
          ]
        })
        pcRef.current = pc
        
        stream.getTracks().forEach(track => {
          console.log(`➕ Agregando ${track.kind} track`)
          pc.addTrack(track, stream)
        })
        
        let sessionId: number | null = null
        
        pc.oniceconnectionstatechange = () => {
          console.log('🧊 ICE Connection State:', pc.iceConnectionState)
          if (pc.iceConnectionState === 'connected') {
            console.log('🎉 ICE CONECTADO!')
          }
        }
        
        pc.onconnectionstatechange = () => {
          console.log('🔄 Connection State:', pc.connectionState)
          if (pc.connectionState === 'connected') {
            setStreamStatus('connected')
            setIsStreaming(true)
            resolve()
          } else if (pc.connectionState === 'failed') {
            setStreamStatus('error')
            setError('Conexión WebRTC falló')
            reject(new Error('Conexión WebRTC falló'))
          }
        }
        
        pc.onicecandidate = (event) => {
          if (event.candidate && ws.readyState === WebSocket.OPEN && sessionId) {
            console.log('📤 Enviando ICE candidate')
            ws.send(JSON.stringify({
              id: sessionId,
              command: 'candidate',
              candidates: [event.candidate]
            }))
          }
        }
        
        ws.onopen = () => {
          console.log('✅ WebSocket conectado a OME')
          ws.send(JSON.stringify({ command: 'request_offer' }))
        }
        
        ws.onmessage = async (event) => {
          try {
            const message = JSON.parse(event.data)
            console.log('📨 Mensaje de OME:', message.command)
            
            if (message.command === 'offer') {
              sessionId = message.id
              console.log('📥 Offer recibido, session ID:', sessionId)
              
              await pc.setRemoteDescription(new RTCSessionDescription(message.sdp))
              console.log('✅ Remote description configurada')
              
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
              if (message.candidates && Array.isArray(message.candidates)) {
                for (const candidate of message.candidates) {
                  await pc.addIceCandidate(new RTCIceCandidate(candidate))
                }
              }
            }
            
          } catch (error) {
            console.error('❌ Error procesando mensaje:', error)
            reject(error)
          }
        }
        
        ws.onclose = () => {
          console.log('🔌 WebSocket cerrado')
          setStreamStatus('disconnected')
          setIsStreaming(false)
        }
        
        ws.onerror = (error) => {
          console.error('❌ Error WebSocket:', error)
          setStreamStatus('error')
          setError('Error de conexión WebSocket')
          reject(error)
        }
        
      } catch (error) {
        console.error('❌ Error configurando conexión:', error)
        reject(error)
      }
    })
  }

  const stopStreaming = () => {
    console.log('🛑 Deteniendo streaming...')
    
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach(track => track.stop())
      mediaStreamRef.current = null
    }
    
    if (wsRef.current) {
      wsRef.current.close()
      wsRef.current = null
    }
    
    if (pcRef.current) {
      pcRef.current.close()
      pcRef.current = null
    }
    
    setIsStreaming(false)
    setStreamStatus('disconnected')
    setError(null)
  }

  useEffect(() => {
    return () => stopStreaming()
  }, [])

  return {
    isStreaming,
    streamStatus,
    error,
    startStreaming,
    stopStreaming
  }
}

// Hook para reproducción LLHLS
function useLLHLSPlayer() {
  const [isPlaying, setIsPlaying] = useState(false)
  const [playerError, setPlayerError] = useState<string | null>(null)
  const playerRef = useRef<HTMLVideoElement | null>(null)
  const hlsRef = useRef<any>(null)
  
  const omeServerIP = import.meta.env.VITE_OME_SERVER_IP || 'tvlive.gpw.cloud'
  const omeSignallingPort = import.meta.env.VITE_OME_SIGNALLING_PORT || '3334'
  const omeAppName = import.meta.env.VITE_OME_APP_NAME || 'app'
  const omeStreamName = import.meta.env.VITE_OME_STREAM_NAME || 'live'
  
  const llhlsUrl = `https://${omeServerIP}:${omeSignallingPort}/${omeAppName}/${omeStreamName}/llhls.m3u8`

  const startPlaying = async () => {
    if (!playerRef.current) return
    
    try {
      setPlayerError(null)
      
      // Verificar si el navegador soporta HLS nativo (Safari)
      if (playerRef.current.canPlayType('application/vnd.apple.mpegurl')) {
        console.log('📺 Usando HLS nativo (Safari)')
        playerRef.current.src = llhlsUrl
        await playerRef.current.play()
        setIsPlaying(true)
      } else {
        // Usar HLS.js para otros navegadores
        console.log('📺 Cargando HLS.js...')
        const { default: Hls } = await import('hls.js')
        
        if (Hls.isSupported()) {
          console.log('📺 Usando HLS.js')
          
          if (hlsRef.current) {
            hlsRef.current.destroy()
          }
          
          const hls = new Hls({
            lowLatencyMode: true,
            liveSyncDurationCount: 1,
            liveMaxLatencyDurationCount: 3,
            debug: false
          })
          
          hlsRef.current = hls
          
          hls.on(Hls.Events.MEDIA_ATTACHED, () => {
            console.log('📺 HLS media attached')
          })
          
          hls.on(Hls.Events.MANIFEST_PARSED, () => {
            console.log('📺 HLS manifest parsed')
            playerRef.current?.play()
            setIsPlaying(true)
          })
          
          hls.on(Hls.Events.ERROR, (event, data) => {
            console.error('❌ HLS Error:', data)
            setPlayerError(`Error HLS: ${data.details}`)
          })
          
          hls.loadSource(llhlsUrl)
          hls.attachMedia(playerRef.current)
          
        } else {
          setPlayerError('HLS no es soportado en este navegador')
        }
      }
      
    } catch (error) {
      console.error('❌ Error iniciando reproducción:', error)
      setPlayerError(error instanceof Error ? error.message : 'Error desconocido')
    }
  }

  const stopPlaying = () => {
    if (hlsRef.current) {
      hlsRef.current.destroy()
      hlsRef.current = null
    }
    
    if (playerRef.current) {
      playerRef.current.pause()
      playerRef.current.src = ''
    }
    
    setIsPlaying(false)
    setPlayerError(null)
  }

  useEffect(() => {
    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy()
      }
    }
  }, [])

  return {
    isPlaying,
    playerError,
    playerRef,
    llhlsUrl,
    startPlaying,
    stopPlaying
  }
}

// Componente para cada tipo de notificación
function DonationNotification({ transaction, onComplete }: NotificationProps) {
  const [playAplausos] = useSound(aplausosSound, { volume: 0.8 })
  const [isVisible, setIsVisible] = useState(true)
  const [stage, setStage] = useState<'animation'|'text'>(('animation'))
  const animationRef = useRef<any>(getRandomAnimation())
  
  const donorName = transaction.nombre_pagador || 'Donante Anónimo'
  const greeting = useRef(getRandomGreeting(donorName, transaction.monto))

  useEffect(() => {
    let animationTimer: number;
    let hideTimer: number;
    let completeTimer: number;
    
    try {
      playAplausos();
    } catch (error) {
      console.error("Error al reproducir sonido:", error);
    }

    animationTimer = window.setTimeout(() => {
      setStage('text')
    }, 5000)

    hideTimer = window.setTimeout(() => {
      setIsVisible(false)
      completeTimer = window.setTimeout(onComplete, 500)
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
            <motion.div className="p-4">
              {stage === 'animation' ? (
                <div className="flex items-center justify-center">
                  <div className="w-full h-screen fixed inset-0 bg-gradient-to-b from-black/80 to-purple-900/70 backdrop-blur-md"></div>
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
                  <div className="w-full h-screen fixed inset-0 bg-gradient-to-b from-black/80 to-purple-900/70 backdrop-blur-md"></div>
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

// Componente principal
export default function StreamWithLLHLS() {
  const [notifications, setNotifications] = useState<Transaction[]>([])
  const [token, setToken] = useState<string | null>(null)
  const [userInteracted, setUserInteracted] = useState(false)
  const [useLocalVideo, setUseLocalVideo] = useState<boolean>(false)
  const [showPlayer, setShowPlayer] = useState(false)
  
  const wsRef = useRef<WebSocket | null>(null)
  
  // Hooks para streaming y reproducción
  const { 
    isStreaming, 
    streamStatus, 
    error: streamingError, 
    startStreaming, 
    stopStreaming 
  } = useWebRTCToOME()

  const {
    isPlaying,
    playerError,
    playerRef,
    llhlsUrl,
    startPlaying,
    stopPlaying
  } = useLLHLSPlayer()

  // Extraer token de la URL y verificar configuración de video local
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    const urlToken = urlParams.get('token')
    if (urlToken) {
      setToken(urlToken)
    }
    
    const localVideo = import.meta.env.VITE_LOCAL_VIDEO === '1'
    setUseLocalVideo(localVideo)
  }, [])

  // Conectar al WebSocket para notificaciones
  useEffect(() => {
    if (!token) return

    let isComponentMounted = true;
    let reconnectTimeout: number | null = null;
    
    const wsUrl = import.meta.env.VITE_WS_URL || 'ws://localhost:8000';

    const connectWebSocket = () => {
      try {
        if (wsRef.current && wsRef.current.readyState !== WebSocket.CLOSED) {
          wsRef.current.close();
        }

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
          
          if (isComponentMounted) {
            if (reconnectTimeout) window.clearTimeout(reconnectTimeout);
            reconnectTimeout = window.setTimeout(connectWebSocket, 3000);
          }
        }

        wsRef.current.onerror = (error) => {
          console.error('❌ Error WebSocket:', error)
          
          if (wsRef.current) {
            wsRef.current.close();
          }
        }
      } catch (error) {
        console.error('Error conectando WebSocket:', error)
        
        if (isComponentMounted) {
          if (reconnectTimeout) window.clearTimeout(reconnectTimeout);
          reconnectTimeout = window.setTimeout(connectWebSocket, 3000);
        }
      }
    }

    connectWebSocket()

    return () => {
      isComponentMounted = false;
      
      if (reconnectTimeout) {
        window.clearTimeout(reconnectTimeout);
      }
      
      if (wsRef.current) {
        wsRef.current.onopen = null;
        wsRef.current.onmessage = null;
        wsRef.current.onclose = null;
        wsRef.current.onerror = null;
        wsRef.current.close();
        wsRef.current = null;
      }
    }
  }, [token])

  // Marcar notificación como leída y removerla
  const handleNotificationComplete = async (notification: Transaction) => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
      
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
      setNotifications(prev => prev.filter(n => n.id !== notification.id));
    }
  }

  const handleUserInteraction = () => {
    setUserInteracted(true);
  };

  const handleStreamingToggle = async () => {
    if (isStreaming) {
      stopStreaming()
    } else {
      await startStreaming()
    }
  }

  const handlePlayerToggle = () => {
    if (isPlaying) {
      stopPlaying()
      setShowPlayer(false)
    } else {
      setShowPlayer(true)
      startPlaying()
    }
  }

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
  
  if (!userInteracted) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
        <div className="bg-white rounded-lg p-6 text-center max-w-md">
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            Activar Streaming LLHLS
          </h2>
          <p className="text-gray-600 mb-4">
            Haz clic para activar sonidos y habilitar el streaming con LLHLS
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
      
      {/* Video de fondo o reproductor LLHLS */}
      {showPlayer && isPlaying ? (
        <video
          ref={playerRef}
          className="absolute inset-0 w-full h-full object-cover"
          autoPlay
          muted
          playsInline
        />
      ) : useLocalVideo ? (
        <BackgroundVideo videoSrc="/uploads/video.mp4" />
      ) : (
        <div className="absolute inset-0 bg-transparent" />
      )}
      
      {/* Panel de Control */}
      <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-50">
        <motion.div 
          className="bg-gradient-to-br from-black/80 to-purple-900/80 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex items-center gap-4 flex-wrap">
            {/* Control de Streaming */}
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
            
            {/* Control de Reproductor */}
            <button
              onClick={handlePlayerToggle}
              className={`px-6 py-2 rounded-lg font-bold text-white transition-all ${
                isPlaying 
                  ? 'bg-orange-600 hover:bg-orange-700' 
                  : 'bg-blue-600 hover:bg-blue-700'
              }`}
            >
              {isPlaying ? '📺 Ocultar Player' : '📺 Ver Stream LLHLS'}
            </button>
            
            {/* Estados */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <div className={`w-3 h-3 rounded-full ${
                  streamStatus === 'connected' ? 'bg-green-400 animate-pulse' :
                  streamStatus === 'connecting' ? 'bg-yellow-400 animate-pulse' :
                  streamStatus === 'error' ? 'bg-red-400' : 'bg-gray-400'
                }`} />
                <span className="text-white text-sm font-medium">
                  Stream: {streamStatus === 'connected' ? 'En vivo' :
                   streamStatus === 'connecting' ? 'Conectando' :
                   streamStatus === 'error' ? 'Error' : 'Desconectado'}
                </span>
              </div>
              
              {showPlayer && (
                <div className="flex items-center gap-2">
                  <div className={`w-3 h-3 rounded-full ${
                    isPlaying ? 'bg-blue-400 animate-pulse' : 'bg-gray-400'
                  }`} />
                  <span className="text-white text-sm font-medium">
                    Player: {isPlaying ? 'Reproduciendo' : 'Detenido'}
                  </span>
                </div>
              )}
            </div>
          </div>
          
          {/* Errores */}
          {streamingError && (
            <div className="mt-2 text-red-300 text-xs">
              Stream Error: {streamingError}
            </div>
          )}
          
          {playerError && (
            <div className="mt-2 text-orange-300 text-xs">
              Player Error: {playerError}
            </div>
          )}
          
          {/* URL LLHLS */}
          <div className="mt-2 text-gray-300 text-xs">
            LLHLS URL: {llhlsUrl}
          </div>
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

      {/* Componentes de overlay */}
      <YapeQROverlay token={token} />
      <DonorsCarousel token={token} />
      
      {/* Indicadores de conexión */}
      <div className="fixed bottom-4 left-4 z-40">
        <div className="bg-black/50 rounded-full px-3 py-1 flex items-center space-x-2">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
          <span className="text-white text-xs">WebSocket OK</span>
          {isStreaming && (
            <>
              <div className="w-1 h-4 bg-white/30" />
              <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
              <span className="text-white text-xs">🔴 STREAMING</span>
            </>
          )}
          {isPlaying && (
            <>
              <div className="w-1 h-4 bg-white/30" />
              <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse" />
              <span className="text-white text-xs">📺 LLHLS</span>
            </>
          )}
        </div>
      </div>
      
      {/* Info de LLHLS */}
      {showPlayer && (
        <div className="fixed bottom-4 right-4 z-40">
          <div className="bg-black/50 rounded-lg px-3 py-2">
            <div className="text-white text-xs">
              <div>📺 LLHLS Player Activo</div>
              <div>🔗 Latencia: ~2-5 segundos</div>
              <div>🌐 Protocolo: HTTPS/TCP</div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}