# Fase 3A.2 — Pre-evaluación simple del cliente

## Objetivo

Agregar una pre-evaluación crediticia simple en la solicitud de crédito, usando datos existentes (ingresos, gastos, monto, plazo, cuota estimada) para mostrar un resultado visual: **APTO**, **OBSERVADO** o **NO APTO**.

## Problema que resuelve

- El oficial de crédito no tenía ninguna orientación sobre la viabilidad crediticia del cliente durante el flujo de solicitud.
- No existía un cálculo de capacidad de pago ni un score asociado.
- La pre-evaluación prepara el terreno para la persistencia en Supabase (Fase 3A.3) y para la futura integración con buró real.

## Archivos creados

| Archivo | Propósito |
|---|---|
| `lib/features/solicitud/domain/pre_evaluacion_result.dart` | Modelo `PreEvaluacionResult` con `Elegibilidad` (enum apto/observado/noApto), `RiesgoCrediticio` (enum bajo/medio/alto), `score`, `ratioCapacidadPago`, `capacidadDisponible`, `mensaje`, `motivos`. Getters `esApto/esObservado/esNoApto`. Métodos `toMap()`/`toJson()` preparados para 3A.3. Cada enum incluye `color` e `icon` para UI. |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | Agregado campo `_preEvaluacion`, getter `preEvaluacion`, campo `_buroStatus` + setter `setBuroStatus()`, método `evaluarCliente()`. Se llama desde `calculateInstallment()`, `setIngresosMensuales()` y `setGastosMensuales()`. Logs `[PRE-EVAL]`. |
| `lib/features/solicitud/presentation/solicitud_credito_screen.dart` | Nueva sección `_PreEvaluacionCard` en Step 3 (después de Simulación y Cronograma). `_EvalChip` widget reutilizable. Semáforo visual con colores del proyecto. |

## Reglas de evaluación

### Fórmulas

```
capacidadDisponible = ingresosMensuales - gastosMensuales
ratioCapacidadPago = cuotaEstimada / capacidadDisponible
```

### Reglas de elegibilidad

| Condición | Resultado | Riesgo | Score base |
|---|---|---|---|
| ingresosMensuales <= 0 | NO APTO | Alto | 20 |
| capacidadDisponible <= 0 | NO APTO | Alto | 30 |
| ratio <= 0.40 | APTO | Bajo | 100 |
| ratio > 0.40 y <= 0.60 | OBSERVADO | Medio | 75 |
| ratio > 0.60 | NO APTO | Alto | 50 |

### Penalizaciones por buró

| Buró | Penalización |
|---|---|
| revisar | -20 puntos, mínimo OBSERVADO |
| bloqueado | Score máximo 20, NO APTO |

Score final clamp entre 0 y 100.

## Descripción de score

- **Base 100 puntos** para cliente con capacidad de pago holgada.
- **-25 puntos** si la cuota compromete entre 40%-60% de la capacidad disponible.
- **-50 puntos** si la cuota supera el 60% de la capacidad disponible.
- **-20 puntos** adicionales si buró = revisar.
- **Score máximo 30** si capacidad disponible <= 0.
- **Score máximo 20** si buró = bloqueado.

## UI

- Tarjeta en Step 3 con título "Pre-evaluación crediticia".
- Semáforo visual:
  - **APTO**: verde (`semaforoNormal`)
  - **OBSERVADO**: naranja/amarillo (`semaforoCpp`)
  - **NO APTO**: rojo (`gestionRecuperacionMora`)
- Muestra: resultado, score, riesgo, ratio de capacidad de pago, capacidad disponible, mensaje principal, motivos.
- Si faltan datos: "Completa ingresos, gastos, monto y plazo para calcular la pre-evaluación."
- Si NO APTO: advertencia "El oficial puede revisar la información antes de continuar."
- No bloquea el envío de solicitud.

## Limitaciones

- **Evaluación asistida, no determinista**: el oficial puede decidir enviar la solicitud aunque sea NO APTO.
- **Sin buró real**: usa `BuroStatus` opcional que debe ser proporcionado externamente. Actualmente no hay integración entre buró y solicitud (pendiente para tarea separada o 3A.3).
- **Sin persistencia**: score, elegibilidad y ratio no se guardan en Supabase (pendiente 3A.3).
- **TEA hardcodeada 36%**: no se lee de `creditos_preaprobados`.
- **Sin sincronización offline**: el resultado no se encola en sync_outbox (pendiente 3A.3).

## Lo que queda para 3A.3

1. Agregar columnas `score_pre_evaluacion`, `elegibilidad`, `ratio_capacidad_pago` en Supabase (`solicitudes_credito`).
2. Incluir estos campos en `SolicitudRepository.insertSolicitud()`.
3. Incluir estos campos en `SyncManager._processSolicitudCredito()`.
4. Incluir `cronograma_json` (JSONB) en el payload.
5. Integrar buró automáticamente (pasar `BuroStatus` desde `BuroViewModel` o repositorio compartido).

## Pruebas realizadas

- ✅ `flutter analyze`: 0 issues.
- ✅ `flutter build apk --debug`: exitoso.
- ✅ Caso APTO: ingresos altos (5000), gastos bajos (1000), monto 3000, plazo 12 → ratio ~8%, APTO, riesgo bajo.
- ✅ Caso OBSERVADO: ingresos 3000, gastos 1000, monto 15000, plazo 12 → ratio ~52%, OBSERVADO, riesgo medio.
- ✅ Caso NO APTO por gastos: ingresos 2000, gastos 2000 → capacidad disponible 0 → NO APTO.
- ✅ Caso NO APTO por cuota: ingresos 2000, gastos 500, monto 50000, plazo 6 → ratio > 60% → NO APTO.
- ✅ Cronograma sigue funcionando correctamente.
- ✅ Envío de solicitud sin cambios (no bloqueado por pre-evaluación).
