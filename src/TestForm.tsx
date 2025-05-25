import { useState } from 'react'

export default function TestForm() {
  const [isDark, setIsDark] = useState(false)

  return (
    <div className={`min-h-screen transition-colors duration-300 flex items-center justify-center p-4 ${
      isDark 
        ? 'bg-gradient-to-br from-gray-900 to-slate-800' 
        : 'bg-gradient-to-br from-blue-50 to-indigo-100'
    }`}>
      <div className={`rounded-2xl shadow-xl p-8 w-full max-w-md transition-colors duration-300 ${
        isDark ? 'bg-gray-800 shadow-2xl' : 'bg-white'
      }`}>
        
        {/* Header con Switch */}
        <div className="flex items-center justify-between mb-6">
          <div className="text-center flex-1">
            <h2 className={`text-3xl font-bold mb-2 ${isDark ? 'text-white' : 'text-gray-800'}`}>
              Crear Cuenta
            </h2>
            <p className={isDark ? 'text-gray-300' : 'text-gray-600'}>
              Únete a nuestra plataforma
            </p>
          </div>
          
          {/* Dark/Light Switch */}
          <button
            onClick={() => setIsDark(!isDark)}
            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 ${
              isDark ? 'bg-blue-600' : 'bg-gray-300'
            }`}
          >
            <span
              className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ${
                isDark ? 'translate-x-6' : 'translate-x-1'
              }`}
            />
            <span className="sr-only">Toggle dark mode</span>
          </button>
        </div>

        <form className="space-y-6">
          {/* Nombre */}
          <div>
            <label className={`block text-sm font-medium mb-2 ${isDark ? 'text-gray-200' : 'text-gray-700'}`}>
              Nombre completo
            </label>
            <input
              type="text"
              className={`w-full px-4 py-3 border rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 ${
                isDark 
                  ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 hover:border-gray-500' 
                  : 'bg-white border-gray-300 text-gray-900 placeholder-gray-500 hover:border-gray-400'
              }`}
              placeholder="Tu nombre completo"
            />
          </div>

          {/* Email */}
          <div>
            <label className={`block text-sm font-medium mb-2 ${isDark ? 'text-gray-200' : 'text-gray-700'}`}>
              Correo electrónico
            </label>
            <input
              type="email"
              className={`w-full px-4 py-3 border rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 ${
                isDark 
                  ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 hover:border-gray-500' 
                  : 'bg-white border-gray-300 text-gray-900 placeholder-gray-500 hover:border-gray-400'
              }`}
              placeholder="tu@email.com"
            />
          </div>

          {/* Password */}
          <div>
            <label className={`block text-sm font-medium mb-2 ${isDark ? 'text-gray-200' : 'text-gray-700'}`}>
              Contraseña
            </label>
            <input
              type="password"
              className={`w-full px-4 py-3 border rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 ${
                isDark 
                  ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 hover:border-gray-500' 
                  : 'bg-white border-gray-300 text-gray-900 placeholder-gray-500 hover:border-gray-400'
              }`}
              placeholder="••••••••"
            />
          </div>

          {/* Checkbox */}
          <div className="flex items-center">
            <input
              type="checkbox"
              className="h-4 w-4 text-blue-600 rounded border-gray-300 focus:ring-2 focus:ring-blue-500"
              id="terms"
            />
            <label htmlFor="terms" className={`ml-3 text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>
              Acepto los{" "}
              <a href="#" className={`underline transition-colors duration-200 ${
                isDark ? 'text-blue-400 hover:text-blue-300' : 'text-blue-600 hover:text-blue-800'
              }`}>
                términos y condiciones
              </a>
            </label>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-semibold py-3 px-6 rounded-xl hover:from-blue-700 hover:to-indigo-700 focus:ring-4 focus:ring-blue-300 transform hover:scale-105 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            Crear Cuenta
          </button>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className={`w-full border-t ${isDark ? 'border-gray-600' : 'border-gray-300'}`}></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className={`px-2 ${isDark ? 'bg-gray-800 text-gray-400' : 'bg-white text-gray-500'}`}>
                O continúa con
              </span>
            </div>
          </div>

          {/* Social Buttons */}
          <div className="grid grid-cols-2 gap-4">
            <button
              type="button"
              className={`flex items-center justify-center px-4 py-3 border rounded-xl transition-colors duration-200 ${
                isDark 
                  ? 'border-gray-600 hover:bg-gray-700 text-gray-200' 
                  : 'border-gray-300 hover:bg-gray-50 text-gray-700'
              }`}
            >
              <span className="text-sm font-medium">Google</span>
            </button>
            <button
              type="button"
              className={`flex items-center justify-center px-4 py-3 border rounded-xl transition-colors duration-200 ${
                isDark 
                  ? 'border-gray-600 hover:bg-gray-700 text-gray-200' 
                  : 'border-gray-300 hover:bg-gray-50 text-gray-700'
              }`}
            >
              <span className="text-sm font-medium">GitHub</span>
            </button>
          </div>
        </form>

        <p className={`text-center text-sm mt-8 ${isDark ? 'text-gray-400' : 'text-gray-600'}`}>
          ¿Ya tienes cuenta?{" "}
          <a href="#" className={`font-medium transition-colors duration-200 ${
            isDark ? 'text-blue-400 hover:text-blue-300' : 'text-blue-600 hover:text-blue-800'
          }`}>
            Inicia sesión
          </a>
        </p>
      </div>
    </div>
  )
}