# Configuración local y credenciales

En esta PC, el respaldo de las credenciales se encuentra en `C:\unitia-credenciales-locales`.
Esta ruta es local a esta computadora; los secretos no están en GitHub.

Al preparar una copia local del proyecto en Windows, antes de iniciar los servicios,
ejecutar desde la raíz del repositorio:

```powershell
.\scripts\restore-local-credentials.ps1
```

El script copia las credenciales a las rutas que ya espera el proyecto y conserva
los archivos de configuración que existan. Si el respaldo está en otra ubicación,
usar `-CredentialsRoot 'RUTA_DEL_RESPALDO'`. Si falta el respaldo, solicitar su
ubicación al usuario; no inventar credenciales.

No mostrar valores secretos en mensajes o registros ni agregarlos a Git.
Mantener los archivos restaurados excluidos por `.gitignore`.
