-- ==============================================================
-- Fase 2C — Supabase: Tablas, columnas y consultas de prueba
-- App Fuerza de Ventas — Banco Alfin
-- ==============================================================
-- Este script es SOLO de referencia/documentación.
-- No ejecutar en producción sin revisar.
-- ==============================================================

-- ---------------------------------------------------
-- 1. Tabla: solicitudes_credito
-- ---------------------------------------------------
-- Columnas esperadas (usadas por EstadoSolicitudesRepository
-- y ReportesRepository):
--
-- id              UUID (PK, default gen_random_uuid())
-- numero_expediente TEXT (UNIQUE)
-- asesor_id       TEXT (FK -> asesores_negocio.id)
-- cliente_id      TEXT (FK -> clientes.id)
-- agencia_id      TEXT (nullable)
-- estado          TEXT ('enviada','en_comite','en_evaluacion',
--                      'aprobada','condicionada','rechazada','desembolsada')
-- monto_solicitado NUMERIC
-- monto_aprobado  NUMERIC (nullable)
-- plazo_meses     INTEGER
-- moneda          TEXT
-- tipo_cuota      TEXT (nullable)
-- garantia        TEXT (nullable)
-- destino_credito TEXT
-- actividad_economica TEXT
-- nombre_negocio  TEXT
-- tipo_negocio    TEXT
-- ingresos_estimados NUMERIC
-- gastos_mensuales NUMERIC
-- patrimonio_estimado NUMERIC
-- cuota_estimada NUMERIC
-- tea_referencial NUMERIC
-- firma_cliente_base64 TEXT (nullable)
-- lat_captura     NUMERIC
-- lng_captura     NUMERIC
-- motivo_rechazo  TEXT (nullable)
-- condicion_adicional TEXT (nullable)
-- analista_asignado TEXT (nullable)
-- pendiente_sync  BOOLEAN default false
-- created_at      TIMESTAMPTZ default now()
-- updated_at      TIMESTAMPTZ default now()

-- ---------------------------------------------------
-- 2. Tabla: clientes
-- ---------------------------------------------------
-- Columnas esperadas:
-- id              UUID (PK)
-- nombres         TEXT
-- apellidos       TEXT
-- numero_documento TEXT
-- direccion       TEXT (nullable)
-- telefono        TEXT (nullable)
-- ingresos_estimados NUMERIC (nullable)

-- ---------------------------------------------------
-- 3. Tabla: cartera_diaria
-- ---------------------------------------------------
-- Columnas esperadas:
-- id              UUID (PK)
-- asesor_id       TEXT (FK -> asesores_negocio.id)
-- cliente_id      TEXT (FK -> clientes.id)
-- fecha_asignacion DATE
-- tipo_gestion    TEXT
-- estado_visita   TEXT ('pendiente','visitado','realizada')
-- orden_manual    INTEGER (nullable)
-- created_at      TIMESTAMPTZ default now()

-- ---------------------------------------------------
-- 4. Tabla: acciones_cobranza
-- ---------------------------------------------------
-- Columnas esperadas (usadas por ReportesRepository):
-- id              UUID (PK)
-- asesor_id       TEXT
-- cliente_id      TEXT
-- credito_id      TEXT (nullable)
-- tipo_gestion    TEXT
-- resultado       TEXT
-- monto_pagado    NUMERIC (nullable)
-- monto_gestionado NUMERIC (nullable)
-- lat             NUMERIC
-- lng             NUMERIC
-- created_at      TIMESTAMPTZ default now()

-- ---------------------------------------------------
-- 5. Tabla: asesores_negocio
-- ---------------------------------------------------
-- Columnas esperadas:
-- id              TEXT (PK)
-- user_id         UUID (FK -> auth.users.id)
-- codigo_empleado TEXT
-- nombres         TEXT
-- apellidos       TEXT
-- agencia_id      TEXT (nullable)

-- ==============================================================
-- INSERTS DEMO OPCIONALES (solo para pruebas locales)
-- ==============================================================
-- NOTA: Reemplazar los UUID por valores reales de tu instancia.

-- INSERT INTO solicitudes_credito (
--   numero_expediente, asesor_id, cliente_id, estado,
--   monto_solicitado, plazo_meses, moneda, destino_credito
-- ) VALUES
--   ('EXP-DEMO-2026-0001', 'asesor-id-aqui', 'cliente-id-aqui',
--    'en_evaluacion', 12000, 12, 'PEN', 'Capital de trabajo'),
--   ('EXP-DEMO-2026-0002', 'asesor-id-aqui', 'cliente-id-aqui',
--    'aprobada', 8000, 6, 'PEN', 'Mercadería');

-- INSERT INTO cartera_diaria (asesor_id, cliente_id, fecha_asignacion,
--   tipo_gestion, estado_visita)
-- VALUES
--   ('asesor-id-aqui', 'cliente-id-aqui', CURRENT_DATE,
--    'Renovación', 'pendiente'),
--   ('asesor-id-aqui', 'cliente-id-aqui', CURRENT_DATE,
--    'Cobranza', 'visitado');

-- INSERT INTO acciones_cobranza (asesor_id, cliente_id, tipo_gestion,
--   resultado, monto_gestionado, lat, lng)
-- VALUES
--   ('asesor-id-aqui', 'cliente-id-aqui', 'Visita domiciliaria',
--    'Compromiso de pago', 500, -12.0464, -77.0428);

-- ==============================================================
-- Fase 3A.3 — Migración: cronograma_json + pre-evaluación
-- Ejecutar en consola SQL de Supabase Dashboard.
-- ==============================================================

alter table public.solicitudes_credito
add column if not exists cronograma_json jsonb;

alter table public.solicitudes_credito
add column if not exists score_pre_evaluacion integer;

alter table public.solicitudes_credito
add column if not exists elegibilidad text;

alter table public.solicitudes_credito
add column if not exists ratio_capacidad_pago numeric;

alter table public.solicitudes_credito
add column if not exists riesgo_asignado text;

-- Verificación: últimas 10 solicitudes con los nuevos campos
-- select
--   numero_expediente,
--   monto_solicitado,
--   plazo_meses,
--   cuota_estimada,
--   score_pre_evaluacion,
--   elegibilidad,
--   ratio_capacidad_pago,
--   riesgo_asignado,
--   jsonb_array_length(cronograma_json) as cuotas_generadas,
--   created_at
-- from public.solicitudes_credito
-- order by created_at desc
-- limit 10;

-- ==============================================================
-- CONSULTAS DE PRUEBA
-- ==============================================================

-- 1. Solicitudes del asesor autenticado (usado por EstadoSolicitudesRepository)
-- SELECT
--   sc.id,
--   sc.numero_expediente,
--   sc.asesor_id,
--   sc.cliente_id,
--   c.nombres,
--   c.apellidos,
--   c.numero_documento,
--   sc.monto_solicitado,
--   sc.monto_aprobado,
--   sc.estado,
--   sc.created_at,
--   sc.updated_at,
--   sc.motivo_rechazo,
--   sc.condicion_adicional,
--   sc.analista_asignado
-- FROM solicitudes_credito sc
-- LEFT JOIN clientes c ON c.id = sc.cliente_id
-- WHERE sc.asesor_id = 'REEMPLAZAR_CON_ASESOR_ID'
-- ORDER BY sc.created_at DESC;

-- 2. Reporte diario (usado por ReportesRepository)
-- SELECT
--   COUNT(*) filter (WHERE estado = 'aprobada' OR estado = 'condicionada')
--     AS aprobadas,
--   COUNT(*) filter (WHERE estado = 'desembolsada')
--     AS desembolsadas,
--   SUM(monto_solicitado) AS monto_solicitado,
--   SUM(COALESCE(monto_aprobado, 0)) AS monto_aprobado
-- FROM solicitudes_credito
-- WHERE asesor_id = 'REEMPLAZAR_CON_ASESOR_ID'
--   AND created_at >= '2026-06-17'
--   AND created_at < '2026-06-18';

-- 3. Cartera diaria (usado por ReportesRepository)
-- SELECT
--   COUNT(*) AS total,
--   COUNT(*) filter (WHERE estado_visita IN ('visitado','realizada'))
--     AS realizadas
-- FROM cartera_diaria
-- WHERE asesor_id = 'REEMPLAZAR_CON_ASESOR_ID'
--   AND fecha_asignacion = CURRENT_DATE;

-- 4. Gestiones de cobranza (usado por ReportesRepository)
-- SELECT
--   COUNT(*) AS gestiones,
--   COUNT(DISTINCT cliente_id) AS clientes_mora,
--   SUM(COALESCE(monto_gestionado, 0)) AS monto_gestionado
-- FROM acciones_cobranza
-- WHERE asesor_id = 'REEMPLAZAR_CON_ASESOR_ID'
--   AND created_at >= '2026-06-17'
--   AND created_at < '2026-06-18';

-- 5. Detalle de solicitud por ID (usado por EstadoSolicitudDetalleViewModel)
-- SELECT
--   sc.*,
--   c.nombres,
--   c.apellidos,
--   c.numero_documento
-- FROM solicitudes_credito sc
-- LEFT JOIN clientes c ON c.id = sc.cliente_id
-- WHERE sc.id = 'REEMPLAZAR_CON_ID';
