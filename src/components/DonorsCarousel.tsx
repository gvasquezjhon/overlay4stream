import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

interface Transaction {
  id: number;
  monto: number;
  nombre_pagador: string;
  fecha: string;
  transaction_id: string;
}

interface DonorsCarouselProps {
  token: string | null;
}

export default function DonorsCarousel({ token }: DonorsCarouselProps) {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  
  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
  
  // Obtener la fecha de hace 2 días en formato ISO completo (YYYY-MM-DDT00:00:00)
  const getTwoDaysAgo = () => {
    const date = new Date();
    date.setDate(date.getDate() - 2);
    return date.toISOString().split('T')[0] + 'T00:00:00';
  };
  
  const startDate = getTwoDaysAgo();
  
  // Función para obtener las transacciones
  useEffect(() => {
    if (!token) return;
    
    const fetchTransactions = async () => {
      try {
        setLoading(true);
        console.log('Fetching transactions with date:', startDate);
        const response = await fetch(
          `${apiUrl}/api/v1/transactions/?skip=0&limit=100&start_date=${encodeURIComponent(startDate)}`,
          {
            method: 'GET',
            headers: {
              'accept': 'application/json',
              'Authorization': `Bearer ${token}`
            }
          }
        );

        if (!response.ok) {
          throw new Error(`Error al obtener transacciones: ${response.status}`);
        }

        const data = await response.json();
        // Ordenar por monto descendente
        const sortedData = data.sort((a: Transaction, b: Transaction) => b.monto - a.monto);
        setTransactions(sortedData);
      } catch (error) {
        console.error('Error al obtener transacciones:', error);
        setError(error instanceof Error ? error.message : 'Error desconocido');
      } finally {
        setLoading(false);
      }
    };

    fetchTransactions();
    
    // Actualizar cada 2 minutos para mantener los datos frescos
    const interval = setInterval(fetchTransactions, 2 * 60 * 1000);
    
    return () => clearInterval(interval);
  }, [token, apiUrl, startDate]);
  
  // Rotar entre donadores cada 5 segundos
  useEffect(() => {
    if (transactions.length === 0) return;
    
    const interval = setInterval(() => {
      setCurrentIndex(prevIndex => 
        prevIndex === transactions.length - 1 ? 0 : prevIndex + 1
      );
    }, 5000);
    
    return () => clearInterval(interval);
  }, [transactions.length]);
  
  // Si no hay transacciones, no mostrar nada
  if (loading && transactions.length === 0) {
    return (
      <motion.div 
        className="fixed top-4 left-4 z-40 max-w-xs"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <div className="bg-gradient-to-br from-black/70 to-purple-900/70 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30">
          <div className="flex flex-col items-center">
            <h3 className="text-white font-bold text-sm mb-2">
              Familia que Apoya
            </h3>
            <div className="animate-pulse bg-purple-200 h-6 w-32 rounded-md"></div>
          </div>
        </div>
      </motion.div>
    );
  }
  
  // Mostrar siempre el componente, incluso si no hay transacciones
  if (error) {
    return (
      <motion.div 
        className="fixed top-4 left-4 z-40 max-w-xs"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <motion.div 
          className="bg-gradient-to-br from-black/70 to-purple-900/70 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30 w-80"
          animate={{ boxShadow: ["0px 4px 12px rgba(124, 58, 237, 0.3)", "0px 6px 16px rgba(124, 58, 237, 0.4)", "0px 4px 12px rgba(124, 58, 237, 0.3)"] }}
          transition={{ duration: 2, repeat: Infinity, repeatType: "reverse" }}
        >
          <div className="flex flex-col items-center">
            <h3 className="text-white font-bold text-sm mb-2 text-center">
              Familia que Apoya
            </h3>
            <p className="text-red-300 text-xs text-center">
              Error al cargar datos
            </p>
          </div>
        </motion.div>
      </motion.div>
    );
  }
  
  // Si no hay transacciones, mostrar un mensaje
  if (transactions.length === 0 && !loading) {
    return (
      <motion.div 
        className="fixed top-4 left-4 z-40 max-w-xs"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <motion.div 
          className="bg-gradient-to-br from-black/70 to-purple-900/70 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30 w-80"
          animate={{ boxShadow: ["0px 4px 12px rgba(124, 58, 237, 0.3)", "0px 6px 16px rgba(124, 58, 237, 0.4)", "0px 4px 12px rgba(124, 58, 237, 0.3)"] }}
          transition={{ duration: 2, repeat: Infinity, repeatType: "reverse" }}
        >
          <div className="flex flex-col items-center">
            <h3 className="text-white font-bold text-sm mb-2 text-center flex items-center gap-1">
              <span className="text-sm">👑</span> Familia que Apoya
            </h3>
            <p className="text-white text-xs text-center text-shadow-sm">
              Sé el primero en apoyar hoy ✨
            </p>
          </div>
        </motion.div>
      </motion.div>
    );
  }

  return (
    <motion.div 
      className="fixed top-4 left-4 z-40 max-w-xs"
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ 
        duration: 0.5,
        type: "spring",
        stiffness: 120,
        damping: 15
      }}
    >
      <motion.div 
        className="bg-gradient-to-br from-black/70 to-purple-900/70 backdrop-blur-md rounded-xl p-4 shadow-xl border border-purple-500/30 w-80"
        animate={{ boxShadow: ["0px 4px 12px rgba(124, 58, 237, 0.3)", "0px 6px 16px rgba(124, 58, 237, 0.4)", "0px 4px 12px rgba(124, 58, 237, 0.3)"] }}
        transition={{ 
          duration: 2, 
          repeat: Infinity,
          repeatType: "reverse" 
        }}
      >
        <div className="flex flex-col items-center">
          <motion.div
            initial={{ y: -3 }}
            animate={{ y: 0 }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              repeatType: "reverse",
              ease: "easeInOut"
            }}
          >
            <h3 className="text-white font-bold text-sm mb-2 text-center flex items-center gap-1">
              <span className="text-sm">👑</span> Familia que Apoya
            </h3>
          </motion.div>
          
          <div className="w-full overflow-hidden">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentIndex}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.3 }}
                className="flex justify-between items-center w-full"
              >
                <div className="flex items-center gap-2">
                  <div className="bg-purple-500 text-white w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shadow-glow">
                    {currentIndex + 1}
                  </div>
                  <div className="text-white font-medium text-sm truncate max-w-[160px] text-shadow-sm">
                    {transactions[currentIndex]?.nombre_pagador || "Anónimo"}
                  </div>
                </div>
                <div className="bg-purple-600/80 text-white px-2 py-1 rounded-md text-xs font-bold ml-1 shadow-glow">
                  S/ {transactions[currentIndex]?.monto.toFixed(2)}
                </div>
              </motion.div>
            </AnimatePresence>
          </div>
          
          {/* Indicador de progreso */}
          <div className="w-full mt-2 bg-white/20 rounded-full h-1 overflow-hidden">
            <motion.div 
              className="bg-purple-400 h-full"
              initial={{ width: "0%" }}
              animate={{ width: `${((currentIndex + 1) / transactions.length) * 100}%` }}
              transition={{ duration: 0.3 }}
            />
          </div>
          
          <div className="mt-2 bg-gradient-to-r from-purple-600/80 to-indigo-600/80 rounded-full px-3 py-1 border border-purple-400/30">
            <p className="text-white text-xs font-medium text-center text-shadow-sm">
              {transactions.length} apoyos hoy ✨
            </p>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}
