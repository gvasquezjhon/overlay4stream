import { useEffect, useRef } from 'react';

interface BackgroundVideoProps {
  videoSrc: string;
}

export default function BackgroundVideo({ videoSrc }: BackgroundVideoProps) {
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    // Configurar el video para que se reproduzca automáticamente en bucle
    if (videoRef.current) {
      videoRef.current.play().catch(error => {
        console.error("Error al reproducir el video:", error);
      });
    }
  }, [videoSrc]);

  return (
    <div className="fixed inset-0 z-0 overflow-hidden">
      <video
        ref={videoRef}
        className="absolute min-w-full min-h-full object-cover"
        src={videoSrc}
        autoPlay
        loop
        muted
        playsInline
      />
    </div>
  );
}
