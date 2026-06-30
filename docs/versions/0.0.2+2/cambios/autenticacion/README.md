# Autenticacion

## Cambios incluidos

- Se elimino la obligacion de verificar correo electronico antes de iniciar
  sesion.
- Se actualizo FlutterFire para corregir el error de registro relacionado con
  `PigeonUserDetails`.
- La restauracion de sesion ahora consulta Firestore para respetar cambios de
  rol hechos directamente en la base de datos.
- El registro muestra/oculta la contrasena y la confirmacion.
- El registro exige minimo 8 caracteres en contrasena y confirmacion.
- El login muestra un mensaje especifico cuando Firebase responde
  `invalid-credential`.
- Se corrigio el procesamiento backend de reclamaciones para no usar
  `FieldValue.serverTimestamp()` dentro del array `reclamaciones`.

## Resultado esperado

Las cuentas nuevas no se crean con contrasenas demasiado cortas y el usuario
puede revisar lo que escribe antes de registrar la cuenta.

Las reclamaciones de objetos se pueden enviar sin que Firestore rechace el
array por contener un valor `serverTimestamp`.
