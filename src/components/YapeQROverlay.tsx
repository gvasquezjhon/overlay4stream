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
  qr_code: string;
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
        
        // No necesitamos modificar el QR, viene correcto del backend
        
        setYapeAccount(data);
      } catch (error) {
        console.error('Error al obtener cuenta Yape:', error);
        setError(error instanceof Error ? error.message : 'Error desconocido');
      }
    };

    fetchYapeAccount();
  }, [token, apiUrl, yapePhone]);

  // El QR siempre estará visible
  if (!token) return null;

  return (
    <motion.div 
      className="fixed top-4 right-4 z-40 max-w-xs"
      initial={{ opacity: 0, scale: 0.9, x: 20 }}
      animate={{ opacity: 1, scale: 1, x: 0 }}
      exit={{ opacity: 0, scale: 0.9, x: 20 }}
      transition={{ 
        duration: 0.5,
        type: "spring",
        stiffness: 120,
        damping: 15
      }}
      whileHover={{ 
        scale: 1.03,
        transition: { duration: 0.2 }
      }}
    >
      <motion.div 
        className="bg-gradient-to-br from-purple-100 to-indigo-50 backdrop-blur-md rounded-xl p-5 shadow-xl border border-purple-300"
        animate={{ boxShadow: ["0px 4px 12px rgba(124, 58, 237, 0.2)", "0px 6px 16px rgba(124, 58, 237, 0.3)", "0px 4px 12px rgba(124, 58, 237, 0.2)"] }}
        transition={{ 
          duration: 2, 
          repeat: Infinity,
          repeatType: "reverse" 
        }}
      >
        <div className="flex flex-col items-center">
          <motion.div
            initial={{ y: -5 }}
            animate={{ y: 0 }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              repeatType: "reverse",
              ease: "easeInOut"
            }}
          >
            <h3 className="text-purple-800 font-bold text-lg mb-3 text-center flex items-center gap-2">
              <span className="text-xl">💜</span> Apoya el Stream
            </h3>
          </motion.div>
          
          {error ? (
            <div className="text-red-500 text-sm p-2 text-center bg-red-50 rounded-lg">
              {error}
            </div>
          ) : !yapeAccount ? (
            <div className="animate-pulse bg-gray-200 w-40 h-40 rounded-lg"></div>
          ) : (
            <>
              <motion.div 
                className="bg-white p-3 rounded-lg mb-3 shadow-md"
                whileHover={{ scale: 1.02 }}
                transition={{ type: "spring", stiffness: 400, damping: 10 }}
              >
                <motion.div
                  initial={{ opacity: 0.9 }}
                  animate={{ opacity: 1 }}
                  transition={{
                    duration: 1.5,
                    repeat: Infinity,
                    repeatType: "reverse"
                  }}
                >
                  <QRCodeSVG 
                    value={yapeAccount.qr_code} 
                    size={150}
                    level="H"
                    includeMargin={true}
                    bgColor={"#ffffff"}
                    fgColor={"#5b21b6"}
                  />
                </motion.div>
              </motion.div>
              <motion.div
                className="bg-purple-100 px-3 py-1 rounded-full mb-2"
                initial={{ scale: 0.95 }}
                animate={{ scale: 1 }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  repeatType: "reverse"
                }}
              >
                <p className="text-purple-800 font-medium text-sm">
                  Moradito: {yapeAccount.telefono}
                </p>
              </motion.div>
            </>
          )}
          
          <div className="mt-2 bg-gradient-to-r from-purple-500 to-indigo-500 rounded-full px-4 py-1.5">
            <p className="text-white text-xs font-medium text-center">
              Tu apoyo motiva el contenido ✨
            </p>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}
