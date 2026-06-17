# Evidencias sugeridas para demo — App Fuerza de Ventas Banco Alfin

Guía para capturas de pantalla o grabación de video al presentar el proyecto.

---

## 1. Login oficial

**Qué mostrar:** Logo Alfin, gradiente institucional, campos código/contraseña, texto “Modo demostración”.  
**Qué explicar:** Punto de entrada seguro del oficial; en producción se conectará Supabase Auth.

---

## 2. Home oficial

**Qué mostrar:** Saludo “Hola, Oficial Alfin”, fecha, resumen (visitas, pendientes, evaluación, mora), grid de 4 accesos, actividad reciente.  
**Qué explicar:** Panel de control del día; hub central tras el login.

---

## 3. Cartera diaria

**Qué mostrar:** Lista de 5 clientes, contadores visitas/pendientes, chips Renovación/Nuevo/Cobranza.  
**Qué explicar:** Agenda de trabajo en campo; acceso a ficha y acciones rápidas (ruta, mora, inicio).

---

## 4. Ruta optimizada

**Qué mostrar:** Resumen km/minutos, mapa simulado con chips numerados, lista reordenada tras “Optimizar ruta”, Carmen Flores prioritaria.  
**Qué explicar:** Planificación operativa; en fase siguiente Google Maps + GPS.

---

## 5. Ficha del cliente

**Qué mostrar:** Rosa Quispe o cliente con oferta, semáforo SBS, posición del cliente, historial crediticio.  
**Qué explicar:** Vista 360° antes de vender o cobrar; base para buró y solicitud.

---

## 6. Consulta de buró con resultado

**Qué mostrar:** Consentimiento marcado, firma registrada, resultado **APTO** o **REVISAR** con semáforo y recomendación.  
**Qué explicar:** Cumplimiento y riesgo previo a desembolso; caso Ana Torres = BLOQUEADO (opcional segunda captura).

---

## 7. Solicitud — Paso 1 (Solicitante)

**Qué mostrar:** Indicador de pasos, datos precargados desde ficha, DNI y teléfono.  
**Qué explicar:** Captura estructurada del solicitante.

---

## 8. Solicitud — Paso 3 (Simulador)

**Qué mostrar:** Slider de monto, plazo, tarjeta con cuota estimada, TEA y costo financiero.  
**Qué explicar:** Simulación crediticia en tiempo real (fórmula TEA 36% demo).

---

## 9. Documentos — Obligatorios completos

**Qué mostrar:** Progreso 4/4, chip “Completo”, documentos en estado Listo.  
**Qué explicar:** Checklist documental antes de transmisión; captura simulada sin cámara real.

---

## 10. Transmisión completada

**Qué mostrar:** Todos los pasos en verde, expediente `EXP-ALF-2026-*`, botón “Ver estado de solicitud”.  
**Qué explicar:** Envío simulado al comité; trazabilidad del proceso.

---

## 11. Estado de solicitudes

**Qué mostrar:** Resumen monto aprobado, chips por estado, tarjeta resaltada si viene de transmisión.  
**Qué explicar:** Tablero de seguimiento post-envío.

---

## 12. Detalle con timeline

**Qué mostrar:** Expediente, monto, timeline con etapas completadas/pendientes, chip “En evaluación”.  
**Qué explicar:** Trazabilidad para el oficial y el comité.

---

## 13. Cartera vencida

**Qué mostrar:** Filtro **Urgente** o resumen preventivos/prioritarios/urgentes, montos vencidos.  
**Qué explicar:** Recuperación de cartera según días de mora.

---

## 14. Formulario de cobranza

**Qué mostrar:** Cliente seleccionado, tipo visita, resultado compromiso de pago, coordenadas simuladas.  
**Qué explicar:** Registro de gestión en campo; estado actualizado al volver al listado.

---

## Orden sugerido de presentación (10–12 min)

1. Login → Home  
2. Cartera → Ficha → Buró (APTO) → Solicitud (paso 1 y 3)  
3. Documentos → Transmisión → Estado (listado + detalle)  
4. Ruta optimizada  
5. Cartera vencida → Registrar gestión  

## Tips

- Usar emulador con resolución 1080×2400 o dispositivo físico.  
- Ocultar banner de debug (ya desactivado en `MaterialApp`).  
- Preparar DNI `71234567` para demo de buró bloqueado si el evaluador pregunta por riesgo.
