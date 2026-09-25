# EPECUÉN - Spawn fix real

## Causa encontrada

Había **dos sistemas de spawn** con posiciones distintas:

1. `EpecuenSpawnController.server.luau` usa `PlayerSpawn.Position` + 3 studs.
2. `MainServer.server.luau` tenía un spawn V4 hardcodeado en `(-160, 240, -750)`.

Además, la captura de Roblox Studio mostró el `HumanoidRootPart` en:

- X = -180
- Y = 2.998
- Z = -780

La especificación del mapa coloca la Ruta de Acceso Norte en Y=20 en Z=-780. Por lo tanto, el personaje estaba aproximadamente 17 studs por debajo de la superficie de la ruta.

## Corrección

Los dos sistemas ahora usan **la misma fuente canónica** (`Services/EpecuenMapSpecification`) y colocan el HumanoidRootPart a:

- X = -180
- Y = 23
- Z = -780

Es decir, 3 studs por encima de la superficie de la ruta.

No se cambió la iluminación ni el mapa.

## Qué hacer

Reemplazá la carpeta/proyecto fuente por estos archivos y sincronizá con Rojo.

Después de sincronizar, en Play seleccioná:

`Players > tu jugador > Character > HumanoidRootPart`

La posición esperada es aproximadamente:

`X=-180, Y=23, Z=-780`
