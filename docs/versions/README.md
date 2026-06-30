# Versiones

## Proposito
Esta carpeta organiza el trabajo por version.

Cada version debe tener su propia carpeta y dentro de ella se separan los
cambios por subcarpetas, para no mezclar entregas distintas.

## Reglas
- La fuente principal para preparar un release es la carpeta de la version
  activa.
- La version activa debe tener subcarpetas para organizar cambios, release y
  validacion.
- Cuando una version se publique, su carpeta queda como referencia historica.
- Cuando empiece la siguiente version, se crea una nueva carpeta desde el
  principio.
- Si se va a hacer cualquier cambio de codigo, primero se debe registrar el
  cambio en la carpeta de la version activa antes de implementar.
- El release de cada version vive en `release/README.md`. No debe manejarse
  como borrador: es un documento vivo que se actualiza conforme avanza la
  version.
- El release esta escrito para el usuario final. Debe explicar los cambios de
  forma especifica, sencilla y entendible, enfocandose en que puede hacer ahora
  el usuario y que mejora vera en la app. Los detalles tecnicos van en
  `cambios/`, `validacion/` o documentos tecnicos.

## Estado actual
- Ultima version cerrada:
  `0.0.1+1`
- Version activa:
  `0.0.2+2`

## Estructura esperada por version

Cada version define sus propias areas segun los cambios que contenga.
La estructura base es:

```text
<version>/
  README.md
  cambios/
    README.md
    <area1>/
      README.md
    <area2>/
      README.md
  release/
    README.md
  validacion/
    README.md
    CHECKLIST.md
```

Solo se crean carpetas para las areas que realmente tienen cambios en esa
version. No se pre-crean areas por adelantado.

## Flujo obligatorio para cambios de codigo
1. Leer este archivo.
2. Identificar la version activa.
3. Entrar al `README.md` de esa version.
4. Elegir el area del cambio.
5. Registrar el cambio nuevo en `cambios/` antes de implementar.
6. Implementar el cambio.
7. Si el usuario vera un cambio en la app, actualizar `release/README.md` con
   una explicacion clara para usuario final.
8. Si aplica, actualizar `validacion/`.

## Orden de lectura
1. Leer este archivo.
2. Identificar la version activa.
3. Entrar al `README.md` de esa version.
4. Leer la subcarpeta relacionada con la tarea actual.

## Procedimiento de despliegue de una nueva version

Cuando se termine el desarrollo de una version y sea momento de publicarla,
seguir estos pasos en orden.

### 1. Verificar que el codigo compila y pasa pruebas

```bash
flutter analyze
flutter test
```

Si hubo cambios en `functions/`:

```bash
cd functions
npm test
cd ..
```

Si algo falla, corregir antes de continuar o documentar el bloqueo en
`validacion/`.

### 2. Generar el APK de release

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

Copiarlo con el nombre de la version para adjuntar al release:

```powershell
Copy-Item build/app/outputs/flutter-apk/app-release.apk `
  build/app/outputs/flutter-apk/0.0.X+Y.apk
```

### 3. Desplegar Cloud Functions si hubo cambios

```bash
cd functions
npm run deploy
cd ..
```

### 4. Confirmar que la version en pubspec.yaml coincide

```bash
git diff pubspec.yaml
```

Debe decir `version: 0.0.X+Y` con el numero correcto.

### 5. Actualizar el release para usuario final

El release vive en `docs/versions/0.0.X+Y/release/README.md`. Debe estar
redactado en espanol, explicando que puede hacer ahora el usuario y que mejoras
vera en la app. No debe incluir detalles tecnicos.

### 6. Actualizar la checklist de validacion

Marcar los items de `docs/versions/0.0.X+Y/validacion/CHECKLIST.md` que ya se
hayan completado.

### 7. Hacer commit y push

```bash
git add -A
git commit -m "release: 0.0.X+Y - resumen corto"
git push origin main
```

### 8. Crear el release en GitHub con el APK adjunto

```bash
gh release create v0.0.X --title "0.0.X+Y - titulo descriptivo" --notes-file docs/versions/0.0.X+Y/release/README.md
gh release upload v0.0.X build/app/outputs/flutter-apk/0.0.X+Y.apk
```

No ejecutar este paso hasta que el usuario confirme la publicacion.

### 9. Cerrar la version y preparar la siguiente

En `docs/versions/README.md`, mover la version actual a "Ultima version
cerrada" y apuntar "Version activa" a la siguiente.

En `docs/versions/0.0.X+Y/README.md`, cambiar el estado a "Version cerrada.
Queda como referencia historica."
