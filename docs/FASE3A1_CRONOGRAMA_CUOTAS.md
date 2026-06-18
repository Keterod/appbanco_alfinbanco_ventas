# Fase 3A.1 — Cronograma de cuotas

## Objetivo

Implementar el desglose mes a mes del cronograma de pagos (tabla de amortización) en la solicitud de crédito, usando el cálculo de cuota fija existente (sistema francés).

## Problema que resuelve

- El simulador actual solo muestra una cuota mensual estimada, total a pagar y costo financiero, pero no el detalle por período.
- El oficial de crédito no podía ver cómo se distribuye capital, interés y saldo mes a mes.
- El cronograma es un requisito funcional de la rúbrica y necesario para la pre-evaluación y la futura App Clientes.

## Archivos creados

| Archivo | Propósito |
|---|---|
| `lib/features/solicitud/domain/cronograma_row.dart` | Modelo inmutable `CronogramaRow` con `numeroCuota`, `fechaPago`, `capital`, `interes`, `cuota`, `saldo`. Métodos `toMap()`/`fromMap()`/`toJson()`. |

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/features/solicitud/presentation/solicitud_credito_viewmodel.dart` | Agregada lista `_cronograma`, getter `cronograma`, `toggleCronograma()`, método `generarCronograma()` con sistema francés, helper `_sumarMeses()`, helper `_r2()`. Llamado automáticamente desde `calculateInstallment()`. |
| `lib/features/solicitud/presentation/solicitud_credito_screen.dart` | Import `cronograma_row.dart`. Dropdown TipoCuota limitado solo a `fija`. Nueva sección `_CronogramaCard` expandible en Step 3 (después de Simulación). Tarjetas compactas por cuota con Cuota/Fecha/Capital/Interés/Cuota/Saldo. Primeras 6 cuotas visibles + botón "Ver más". Totales al final. |
| `lib/features/solicitud/domain/credit_request_model.dart` | (Sin cambios directos; el modelo ya tenía `TipoCuota.fija`) |

## Fórmula usada

Sistema francés (cuota fija):

```
TEM = (1 + TEA)^(1/12) - 1
cuota = Monto * TEM / (1 - (1 + TEM)^(-plazo))
```

Para cada mes `i` (1..n):

```
interés[i]   = saldoAnterior * TEM
capital[i]   = cuota - interés[i]
saldo[i]     = saldoAnterior - capital[i]
```

- Última cuota: se ajusta capital para que saldo final quede en 0.00.
- Valores redondeados a 2 decimales con `(v * 100).roundToDouble() / 100`.

Fechas:

```
fechaPago[i] = fechaInicio + i meses
```

- Helper `_sumarMeses()` usa `DateTime(year, month + meses, day.clamp(1, 28))` para evitar errores en días 29/30/31.

## Campos del cronograma

| Campo | Tipo | Descripción |
|---|---|---|
| `numeroCuota` | `int` | Número de período (1..n) |
| `fechaPago` | `DateTime` | Fecha estimada de pago |
| `capital` | `double` | Amortización de capital en la cuota |
| `interes` | `double` | Interés generado en el período |
| `cuota` | `double` | Cuota total (capital + interés) |
| `saldo` | `double` | Saldo pendiente después del pago |

## UI

- En Step 3, después de la tarjeta "Simulación", se agregó una sección expandible.
- Botón "Ver cronograma de cuotas" / "Ocultar cronograma".
- Muestra tarjetas compactas por cuota (4 campos por fila: Capital/Interés, Cuota/Saldo).
- Primeras 6 cuotas visibles; si hay más, botón "Ver más (N restantes)".
- Al final: Total a pagar y Costo financiero (coherentes con el cronograma).
- Texto informativo: "Cronograma referencial calculado con cuota fija y TEA referencial."
- La tarjeta de simulación original no se modificó.

## Limitaciones

- **Solo cuota fija (sistema francés):** Las opciones `decreciente` y `balloon` no están implementadas. El dropdown solo muestra "Cuota fija".
- **No se persiste en Supabase:** El cronograma se genera en memoria. La persistencia final (columna `cronograma_json` o tabla `cronograma_pagos`) se implementará en Fase 3A.3.
- **No se incluye en sync offline:** El cronograma no se envía en el payload de `sync_outbox`. Se agregará en 3A.3 si es necesario.
- **TEA hardcodeada:** Se usa 36% fijo. No se lee de `creditos_preaprobados`.

## Qué queda para 3A.3 (persistencia)

- Agregar columna `cronograma_json` (JSONB) en `solicitudes_credito`.
- Serializar `List<CronogramaRow>` a JSON y enviarlo en `insertSolicitud()`.
- Incluir cronograma en payload de sync offline (`SyncManager._processSolicitudCredito`).
- Opcional: crear tabla `cronograma_pagos` dedicada.

## Pruebas realizadas

1. App inicia y restaura sesión.
2. Ir a Nueva solicitud → seleccionar cliente.
3. Completar Step 1 (Solicitante) y Step 2 (Negocio).
4. Step 3 (Crédito): ajustar monto/plazo.
5. Abrir "Ver cronograma de cuotas".
6. Confirmar:
   - Cuotas generadas mes a mes.
   - Interés decreciente, capital creciente.
   - Saldo llega a 0.00 en última cuota.
   - Total a pagar = cuota × plazo (aproximadamente).
7. Cambiar monto → cronograma se recalcula automáticamente.
8. Cambiar plazo → cronograma se recalcula automáticamente.
9. Enviar solicitud → funciona sin cambios.
10. `flutter analyze`: 0 issues.
11. `flutter build apk --debug`: exitoso.

## Verificación

```bash
flutter analyze                              # 0 issues
flutter build apk --debug                    # exitoso
```
