# McDonald’s Anime · API
API educativa v3. Node 22.12 o superior de la rama 22, Express 5 y PostgreSQL. En local copie .env.example a .env, configure PostgreSQL y ejecute npm ci, npm run migrate, npm run seed y npm run dev. npm test ejecuta las pruebas de reglas. La semilla contiene el catálogo ficticio. Deje ADMIN_EMAIL y ADMIN_PASSWORD vacías para omitir la cuenta local.
 
## Supabase y Render
Use un proyecto dedicado y un pooler en modo sesión. Ejecute migrate y seed desde un entorno administrativo con MIGRATION_DATABASE_URL. El migrador registra cada versión en mcd.schema_migrations. La migración 002 crea mcd_api sin contraseña. Asígnele una contraseña mediante la orden interactiva de psql «\password mcd_api». Use ese rol en DATABASE_URL de Render con el formato de usuario del pooler (mcd_api seguido de punto y la referencia del proyecto). Guarde la URL únicamente en Render. Para una raíz privada, configure DATABASE_CA_CERT con la CA del proyecto. La API verifica el certificado.
 
En Render elija Node 22, npm ci y npm start. Configure SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY para autenticación por correo y contraseña, y CORS_ORIGIN con los orígenes permitidos separados por comas. El rol mcd_api es exclusivo de este modo de autenticación. El modo local de desarrollo usa una base separada. PORT lo asigna Render. Configure Site URL en Supabase Auth con el dominio de Vercel y autorice también las URLs locales. Active Email y la confirmación de correo. El esquema mcd es privado. El acceso por usuario y por asignación se controla en Express.
 
GET /api/health ejecuta SELECT 1. GET /api/products consulta catálogo y existencias. El cuerpo exitoso contiene data. El error contiene error.message.
