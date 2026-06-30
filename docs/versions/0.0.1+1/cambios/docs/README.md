# Documentacion

## Resumen

Se agrego la estructura `docs/versions/` para estandarizar la preparacion de
versiones de BackToMe.

## Estructura creada

```text
docs/versions/
  README.md
  0.0.1+1/
    README.md
    cambios/
      README.md
      actualizaciones_android/
        README.md
      docs/
        README.md
    release/
      README.md
    validacion/
      README.md
      CHECKLIST.md
```

## Regla adoptada

Antes de implementar cambios de codigo para una version, se debe registrar el
cambio en `docs/versions/<version>/cambios/`. Despues se actualiza el release si
el usuario vera un cambio en la app.
