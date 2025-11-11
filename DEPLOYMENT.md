# Guía de Despliegue en GitHub Pages

## Pasos para desplegar en GitHub Pages

### 1. Configurar Secrets en GitHub

Ve a tu repositorio en GitHub:
https://github.com/ariancamejo/lucio_sales

1. Ve a **Settings** → **Secrets and variables** → **Actions**
2. Haz clic en **New repository secret**
3. Crea los siguientes secrets:

   - **SUPABASE_URL**
     - Valor: `https://rznlsalmbvbaapczduso.supabase.co`

   - **SUPABASE_ANON_KEY**
     - Valor: Tu anon key de Supabase (cópiala del archivo `.env`)

### 2. Habilitar GitHub Pages

1. Ve a **Settings** → **Pages**
2. En **Source**, selecciona: `Deploy from a branch`
3. En **Branch**, selecciona: `gh-pages` y `/root`
4. Haz clic en **Save**

### 3. Configurar URLs de Callback en Supabase

Ve a tu proyecto de Supabase:
https://supabase.com/dashboard/project/rznlsalmbvbaapczduso

1. Ve a **Authentication** → **URL Configuration**
2. En **Site URL**, añade:
   ```
   https://ariancamejo.github.io/lucio_sales/
   ```

3. En **Redirect URLs**, añade las siguientes URLs:
   ```
   http://localhost:8080
   http://localhost:8080/
   http://localhost:8080/auth/callback
   http://localhost:8080/login-callback
   https://ariancamejo.github.io/lucio_sales/
   https://ariancamejo.github.io/lucio_sales/auth/callback
   https://ariancamejo.github.io/lucio_sales/login-callback
   ```

### 4. Hacer Push para Desplegar

```bash
git add .
git commit -m "Configure GitHub Pages deployment"
git push origin main
```

El workflow de GitHub Actions se ejecutará automáticamente y desplegará tu app.

### 5. Acceder a tu App

Una vez desplegada, tu app estará disponible en:
https://ariancamejo.github.io/lucio_sales/

## Despliegue Automático

Cada vez que hagas `git push` a la rama `main`, GitHub Actions:
1. Descargará el código
2. Instalará Flutter y las dependencias
3. Creará el archivo `.env` con los secrets
4. Compilará la app para web
5. Desplegará automáticamente a GitHub Pages

## URLs Importantes

- **App en producción**: https://ariancamejo.github.io/lucio_sales/
- **Repositorio**: https://github.com/ariancamejo/lucio_sales
- **Supabase Dashboard**: https://supabase.com/dashboard/project/rznlsalmbvbaapczduso
- **GitHub Actions**: https://github.com/ariancamejo/lucio_sales/actions

## Solución de Problemas

### Error de autenticación OAuth
- Verifica que las URLs de callback estén configuradas en Supabase
- Verifica que coincidan exactamente (con o sin barra final)

### Build falla en GitHub Actions
- Verifica que los secrets estén configurados correctamente
- Revisa los logs en la pestaña Actions

### App no carga
- Verifica que GitHub Pages esté habilitado
- Espera unos minutos después del primer despliegue
- Limpia la caché del navegador

### RLS (Row Level Security)
- Asegúrate de haber configurado las políticas RLS en Supabase
- Ejecuta el script SQL proporcionado anteriormente
