# 🤖 AGENTS.md — Protocolo de Navegación y Trabajo para Agentes en ErBolamm Studio

> **Para cualquier agente IA o desarrollador que entre a este repositorio:**
> Este archivo define las fuentes de verdad, la jerarquía documental y las reglas estrictas de desarrollo.

---

## 📌 1. Fuente Única de Verdad: `ESTADO.md`

- **TODA la situación viva del proyecto está en [ESTADO.md](file:///Users/apliarte/trabajo/erbolamm-studio/ESTADO.md).**
- Antes de planificar, refactorizar o afirmar qué funciona y qué falta, **leé obligatoriamente `ESTADO.md`**.
- Al terminar cualquier cambio de valor, **actualizá `ESTADO.md`** con el progreso real y la fecha.

---

## 🧭 2. Mapa y Jerarquía Documental

1. **[ESTADO.md](file:///Users/apliarte/trabajo/erbolamm-studio/ESTADO.md)**: Estado funcional real de cada feature, tareas pendientes ordenadas por prioridad y métricas de tests.
2. **[INBOX.md](file:///Users/apliarte/trabajo/erbolamm-studio/INBOX.md)**: Protocolo maestro para procesar proyectos que ingresan a `INBOX/` (análisis, auditoría de requisitos, decisiones del Paso 2, carpetas `promo/`, firmas y registro en `universe.json`).
3. **[universe.json](file:///Users/apliarte/trabajo/erbolamm-studio/universe.json)**: Catálogo canónico del ecosistema ErBolamm consumido por `erbolamm-universo` y hubs públicos.
4. **`openspec/`**: Especificaciones formales SDD (propuestas, diseños y tareas de cambios).

---

## 🛠️ 3. Reglas Técnicas y Arquitectura

- **Framework**: Flutter Desktop (macOS/Linux/Windows) + Dart puro para CLI (`bin/studio.dart`).
- **Estado**: Flutter BLoC / Provider.
- **Logging**: `AppLogger.i` (NUNCA usar `print()`).
- **Sandbox Guard**: Prohibido modificar el código de los repositorios analizados en `INBOX/` sin confirmación explícita (solo lectura para análisis y generación de assets en sus carpetas `promo/`).
- **Calidad**: Mantener siempre `flutter analyze` en 0 warnings y la suite de tests (`flutter test`) 100% pasando.

---

## 🧹 4. Higiene y Limpieza

- Los archivos de scratch, estudios obsoletos o notas temporales no deben contaminar la raíz.
- Si un archivo pierde vigencia frente al diseño canónico, debe proponerse su archivado o eliminación.
