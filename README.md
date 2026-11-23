# Proyección (nombre provisional)

Sistema de proyección para la iglesia: cantos, Biblia Reina-Valera 1909, avisos y cuenta regresiva.
Se controla desde la PC o el celular en tiempo real (Supabase de ADULAM).

## Vistas
- `index.html` → control (entra con usuario de ADULAM: admin, pastor, líder o servidor)
- `index.html#pantalla?sala=CÓDIGO` → pantalla del proyector o Smart TV
- `index.html#escenario?sala=CÓDIGO` → monitor de músicos y púlpito

## Archivos
- `biblia-rv1909.json` → Reina-Valera 1909 (dominio público), funciona sin internet
- `sw.js` → guarda la app y la Biblia para usarlas sin internet
- `sql/proyeccion_migracion.sql` → tablas `proy_` en Supabase (ya aplicado)
