import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { QRCodeSVG } from 'qrcode.react'

interface YapeQROverlayProps {
  token: string | null;
}

interface YapeAccount {
  id: number;
  telefono: string;
  nombre: string;
  qr: string;
}

export default function YapeQROverlay({ token }: YapeQROverlayProps) {
  const [yapeAccount, setYapeAccount] = useState<YapeAccount | null>(null);
  const [isVisible, setIsVisible] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
  const yapePhone = import.meta.env.VITE_YAPE_PHONE || '924893117';

  useEffect(() => {
    if (!token) return;

    const fetchYapeAccount = async () => {
      try {
        const response = await fetch(
          `${apiUrl}/api/v1/accounts/${yapePhone}`,
          {
            method: 'GET',
            headers: {
              'accept': 'application/json',
              'Authorization': `Bearer ${token}`
            }
          }
        );

        if (!response.ok) {
          throw new Error(`Error al obtener datos de Yape: ${response.status}`);
        }

        const data = await response.json();
        
        // Asegurarse de que el QR tenga un formato válido
        if (!data.qr || data.qr === 'undefined' || data.qr === 'null') {
          // Crear un QR válido con el formato de Yape
          data.qr = `yape://transaction?type=p2p&phoneNumber=${data.telefono}&name=${encodeURIComponent(data.nombre)}`;
        }
        
        setYapeAccount(data);
      } catch (error) {
        console.error('Error al obtener cuenta Yape:', error);
        setError(error instanceof Error ? error.message : 'Error desconocido');
      }
    };

    fetchYapeAccount();
  }, [token, apiUrl, yapePhone]);

  // Alternar visibilidad cada 5 minutos
  useEffect(() => {
    const toggleInterval = setInterval(() => {
      setIsVisible(prev => !prev);
    }, 5 * 60 * 1000); // 5 minutos

    return () => clearInterval(toggleInterval);
  }, []);

  if (!isVisible) return null;

  return (
    <motion.div 
      className="fixed top-4 right-4 z-40 max-w-xs"
      initial={{ opacity: 0, scale: 0.9, x: 20 }}
      animate={{ opacity: 1, scale: 1, x: 0 }}
      exit={{ opacity: 0, scale: 0.9, x: 20 }}
      transition={{ duration: 0.5 }}
    >
      <div className="bg-white/90 backdrop-blur-sm rounded-xl p-4 shadow-lg border border-purple-300">
        <div className="flex flex-col items-center">
          <h3 className="text-purple-800 font-bold text-lg mb-2 text-center">
            Manda tu moradito
          </h3>
          
          {error ? (
            <div className="text-red-500 text-sm p-2 text-center">
              {error}
            </div>
          ) : !yapeAccount ? (
            <div className="animate-pulse bg-gray-200 w-40 h-40 rounded-lg"></div>
          ) : (
            <>
              <div className="bg-white p-2 rounded-lg mb-2">
                <QRCodeSVG 
                  value={yapeAccount.qr || `yape://transaction?type=p2p&phoneNumber=${yapeAccount.telefono}&name=${encodeURIComponent(yapeAccount.nombre)}`} 
                  size={150}
                  level="H"
                  includeMargin={true}
                />
              </div>
              <p className="text-purple-700 font-semibold text-sm">
                {yapeAccount.nombre}
              </p>
              <p className="text-purple-700 font-semibold text-sm mb-2">
                {yapeAccount.telefono}
              </p>
            </>
          )}
          
          <p className="text-purple-900 text-xs text-center mt-1">
            Recibe tu saludo en la transmisión
          </p>
        </div>
      </div>
    </motion.div>
  );
}
