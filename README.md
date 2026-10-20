# Nexo Store

Aplicación Flutter multiplataforma para consultar y administrar un catálogo de productos usando [Fake Store API](https://fakestoreapi.com/products/).

## Ejecutar

1. Instala Flutter y una plataforma de ejecución (Android, iOS o navegador).
2. Desde la raíz del proyecto ejecuta `flutter pub get`.
3. Inicia la app con `flutter run`.
4. Para el acceso de demostración usa **admin** como usuario y **123456** como contraseña.

También puedes crear una cuenta desde la pantalla de acceso. Las cuentas creadas se mantienen solo en memoria y desaparecen al cerrar o reiniciar la app. Esta autenticación es de demostración: no sustituye un backend de identidad ni debe usarse para proteger datos reales.

## Funcionalidades

- Inicio de sesión con validación de usuario y contraseña no vacíos, y registro en memoria.
- Consulta del catálogo desde Fake Store API, búsqueda por texto y filtro por categoría.
- Vista de detalle y formularios validados para agregar y editar productos.
- Eliminación con confirmación, indicador de carga, opción de reintento y mensajes claros cuando falla la conexión.
- Diseño adaptable con cards, imágenes y estados vacíos/de error.
- Renderizado de imágenes externas compatible con Flutter Web y enlaces que no permiten CORS para lectura desde JavaScript.

### Nota sobre Fake Store API y conexión

Fake Store API simula las operaciones de escritura: responde a `POST`, `PUT` y `DELETE`, pero no persiste esos cambios en su catálogo. Para que la interfaz no se bloquee esperando a la red, las altas, ediciones y eliminaciones se reflejan inmediatamente en el catálogo de la sesión y se envían a la API en segundo plano. Si falla el envío, la app conserva el cambio local y muestra una advertencia; los cambios locales se pierden al volver a cargar o reiniciar. Si no hay conexión al cargar el catálogo, se muestra el error y se puede reintentar; no existe una caché offline.

Las imágenes de la web se muestran mediante un elemento HTML `<img>` para evitar el bloqueo CORS de algunas fuentes, como ciertos enlaces directos de Pinterest. En Android e iOS se usa el cargador de imágenes de Flutter. El servidor de imágenes todavía debe permitir acceso directo a la imagen; si la URL caduca o el servidor la bloquea, se muestra un aviso en su lugar.

## Estructura de `lib/`

- `main.dart`: tema y punto de entrada.
- `models/`: modelo `Product` y conversión JSON.
- `screens/`: acceso, catálogo, detalle y formulario.
- `services/`: cliente HTTP y operaciones de la API.

## Preguntas de comprensión

1. **¿Proporciona el código generado para el Future?**  
   El catálogo usa `Future<List<Product>>` para cargar los productos. La implementación se encuentra en `lib/screens/product_catalog_screen.dart`:

   ```dart
   Future<void> _loadProducts() async {
     setState(() {
       _isLoading = true;
       _loadError = null;
     });
     try {
       final products = await _api.fetchProducts();
       if (!mounted) return;
       setState(() {
         _products = products;
         _isLoading = false;
       });
     } on ApiException catch (error) {
       if (!mounted) return;
       setState(() {
         _loadError = error.message;
         _isLoading = false;
       });
     }
   }
   ```

   `fetchProducts()` en `lib/services/product_api.dart` devuelve `Future<List<Product>>`: hace el GET, valida la respuesta y transforma cada objeto JSON en `Product`.

2. **¿Para qué sirve `async` y qué hace `await`?**  
   `async` permite que una función ejecute trabajo asíncrono y devuelva un `Future`. `await` espera el resultado de un `Future` sin bloquear la interfaz; al terminar, continúa la función. Por eso la pantalla puede mostrar un indicador mientras espera la API.

3. **¿Nombre del modelo(s) creados para el proyecto?**  
   `Product`, definido en `lib/models/product.dart`. Incluye ID, título, precio, descripción, categoría e imagen.

4. **¿Qué sucede si no hay conexión a Internet?**  
   La solicitud termina con un mensaje de error; el catálogo presenta un estado de conexión fallida y un botón para reintentar. Los cambios de productos no se aplican localmente si la operación remota falla. No hay modo offline ni caché; los registros de usuario, además, solo viven durante la sesión.

5. **¿Lista las carpetas generadas dentro de `lib`?**  
   `models`, `screens` y `services`, además del archivo `main.dart` en la raíz de `lib`.

## Validar

```sh
flutter analyze
flutter test
```
