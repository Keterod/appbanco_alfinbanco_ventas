# Fase 3A.3 — Persistencia Supabase + Sincronización

## Objetivo

Persistir en Supabase el cronograma de cuotas (JSONB) y la pre-evaluación (score, elegibilidad, ratio, riesgo) generados durante el flujo de solicitud, tanto online como offline (vía sync_outbox).

## Problema que resuelve

- El cronograma de cuotas y la pre-evaluación solo existían en memoria y se perdían al persistir la solicitud en Supabase.
- No se podía consultar desde Core Mobile ni desde App Clientes.
- El sync offline no incluía estos campos, por lo que las solicitudes generadas sin internet llegaban incompletas.

## SQL requerido

Ejecutar en la consola SQL del Supabase Dashboard:

```sql
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
```

Verificar con:

```sql
select
  numero_expediente,
  monto_solicitado,
  plazo_meses,
  cuota_estimada,
  score_pre_evaluacion,
  elegibilidad,
  ratio_capacidad_pago,
  riesgo_asignado,
  jsonb_array_length(cronograma_json) as cuotas_generadas,
  created_at
from public.solicitudes_credito
order by created_at desc
limit 10;
```

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/features/solicitud/data/solicitud_repository.dart` | `insertSolicitud()` acepta 5 nuevos parámetros opcionales: `cronogramaJson`, `scorePreEvaluacion`, `elegibilidad`, `ratioCapacidadPago`, `riesgoAsignado`. Se incluyen en el payload Supabase con sintaxis `if (x != null)`. |
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | `submitRequest()` serializa `_cronograma` → JSON list via `toJson()`. Extrae `_preEvaluacion` → score/elegibilidad/ratio/riesgo. Los pasa al repositorio online y al payload del sync offline. |
| `lib/core/sync/sync_manager.dart` | `_processSolicitudCredito()` sanitiza los 5 campos nuevos (`cronograma_json`, `score_pre_evaluacion`, `elegibilidad`, `ratio_capacidad_pago`, `riesgo_asignado`) y los incluye en el insert a Supabase. Agrega logs `[SYNC]` detallados. |
| `docs/sql/FASE2C_SUPABASE_DATOS_REALES.sql` | Nueva sección "Fase 3A.3" con ALTER TABLE + consulta de verificación. |
| `analysis_options.yaml` | Se agregó `use_null_aware_elements: false` para mantener 0 issues. |

## Columnas nuevas

| Columna | Tipo | Origen | Nullable |
|---|---|---|---|
| `cronograma_json` | JSONB | `CronogramaRow.toJson()` de cada cuota | Sí |
| `score_pre_evaluacion` | INTEGER | `PreEvaluacionResult.score` | Sí |
| `elegibilidad` | TEXT | `PreEvaluacionResult.elegibilidad.name` (apto/observado/noApto) | Sí |
| `ratio_capacidad_pago` | NUMERIC | `PreEvaluacionResult.ratioCapacidadPago` | Sí |
| `riesgo_asignado` | TEXT | `PreEvaluacionResult.riesgo.name` (bajo/medio/alto) | Sí |

## Comportamiento online

1. Usuario completa solicitud con internet.
2. `SolicitudCreditoViewModel.submitRequest()` serializa cronograma y pre-evaluación.
3. `SolicitudRepository.insertSolicitud()` envía payload con las 5 columnas nuevas a Supabase.
4. En Supabase queda la solicitud completa con cronograma y pre-evaluación.

## Comportamiento offline

1. Usuario completa solicitud sin internet (o Supabase falla).
2. `submitRequest()` atrapa el error y encola en `sync_outbox` con payload que incluye los 5 campos nuevos.
3. Al recuperar conexión, `SyncManager.processPending()` ejecuta `_processSolicitudCredito()`.
4. El método sanitiza cada campo (preservando `cronograma_json` como lista) y hace insert en Supabase.
5. Logs `[SYNC]` confirman qué se incluyó.

## Cómo probar en Supabase

```sql
SELECT
  numero_expediente,
  cronograma_json IS NOT NULL AS tiene_cronograma,
  jsonb_array_length(cronograma_json) AS cuotas,
  score_pre_evaluacion,
  elegibilidad,
  ratio_capacidad_pago,
  riesgo_asignado
FROM solicitudes_credito
ORDER BY created_at DESC
LIMIT 5;
```

## Limitación

- Se usa `cronograma_json` (JSONB) en lugar de una tabla `cronograma_pagos` normalizada. Decisión técnica para este MVP para evitar crear una nueva tabla Supabase y su correspondiente CRUD offline.
- La pre-evaluación sigue siendo asistida (no bloquea envío) y sin buró real.

## Conclusión

Con Fase 3A.3 la **App Fuerza de Ventas queda cerrada funcionalmente**:

- Solicitud de crédito completa: cliente, negocio, simulación, cronograma, pre-evaluación.
- Persistencia online y offline con sincronización.
- Dashboard, reportes, estado solicitudes, cartera diaria, cobranza, ruta, buró mock, ficha cliente.
- Sesión persistente, GPS real, SQLite offline.
- Sin PDF, cámara real, firma real, roles, App Clientes ni Core Mobile (pendientes para fases posteriores).
