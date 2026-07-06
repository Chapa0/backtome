# Reglas de Firestore

## Objetivo

Corregir el error `[cloud_firestore/permission-denied]` al consultar
`objetos_perdidos`.

## Cambios

- `firebase.json` declara `firestore.rules` para que las reglas del repositorio
  puedan desplegarse con Firebase CLI.
- Se desplegaran solo reglas de Firestore al proyecto `back-to-me-48f22`.
