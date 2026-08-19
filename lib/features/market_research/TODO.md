# 📊 features/market_research/ — Análisis de Mercado + Tendencias

Genera estudios de mercado y hooks promocionales conectados con la actualidad.

## Estado actual
✅ MarketResearchScreen — UI con tendencias simuladas + hooks generados
⬜ Búsqueda real de tendencias (RSS / news API / web scraping)
⬜ Generación real de hooks con Paperclip + AI local
⬜ Integración con redes para publicar directo

## Cómo funciona
1. Lee el proyecto de la carpeta INBOX (antes INBOX/)
2. Busca tendencias del día (RSS, Google News, X, Reddit)
3. Paperclip cruza tendencias + features del proyecto
4. Genera hooks promocionales con el tono adecuado para cada red
5. Se pueden copiar, editar y publicar directo

## TODO

### Paperclip integration
- [ ] Instalar Paperclip (Node.js server)
- [ ] Conectar con la app via HTTP/localhost
- [ ] Crear agentes: market_analyst, trend_scout, copy_writer
- [ ] Pipeline automático: proyecto → tendencias → hooks → publish

### Trend sources
- [ ] RSS feeds (El País, El Mundo, TechCrunch)
- [ ] Google Trends API
- [ ] X/Twitter trending topics
- [ ] Reddit r/programming, r/FlutterDev
- [ ] Hacker News

### AI local
- [ ] Conectar con apliarte-ai (VS Code extension)
- [ ] Modelo local para generación de copy
- [ ] Sin depender de APIs externas
