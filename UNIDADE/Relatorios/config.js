/* ═══════════════════════════════════════════════════════════════════════════════ */
/* ESTUFA SMART - CONFIGURAÇÃO */
/* ═══════════════════════════════════════════════════════════════════════════════ */

const EstufaConfig = {
  // API
  api: {
    timeout: 10000, // ms
    intervaloAtualizar: 15000, // 15 segundos
    endpoint: '/api',
    hosts: [
      'localhost:7002',
      '127.0.0.1:7002',
      'estufa-api.local:7002',
      '143.106.241.4:7002'
    ]
  },

  // Limites ideais para sensores
  limites: {
    temperatura: {
      min: 20,
      ideal_min: 22,
      ideal_max: 26,
      max: 30
    },
    umidade: {
      min: 40,
      ideal_min: 55,
      ideal_max: 75,
      max: 90
    },
    solo: {
      min: 30,
      ideal_min: 50,
      ideal_max: 70,
      max: 85
    }
  },

  // Cores por status
  cores: {
    ideal: '#66bb6a',
    aviso: '#fdd835',
    critico: '#ef5350',
    normal: '#2196f3'
  },

  // Gamificação
  gamificacao: {
    pontosPorMeta: 100,
    pontosPorBadge: 250,
    pontosPorSemanaPerfeita: 500,
    matasContinuarAtivas: true
  },

  // Cache local
  cache: {
    ativar: true,
    duracao: 300000, // 5 minutos
    chaves: {
      alertas: 'estufa_alertas',
      comparativa: 'estufa_comparativa',
      previsoes: 'estufa_previsoes'
    }
  },

  // Logging
  logging: {
    ativo: false,
    nivel: 'info', // 'debug', 'info', 'warn', 'error'
    arquivo: '/logs/estufa.log'
  },

  // Notificações
  notificacoes: {
    som: true,
    desktop: true,
    email: true,
    whatsapp: false
  },

  // Features
  features: {
    dashboardRealtime: true,
    mapaVisual: true,
    comparativa: true,
    calendario: true,
    relatorios: true,
    gamificacao: true,
    previsoes: true,
    mobileSync: true,
    ia: false // Ativar quando backend tiver IA
  }
};

// Exportar para uso global
window.EstufaConfig = EstufaConfig;
