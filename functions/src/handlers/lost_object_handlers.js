"use strict";

const functions = require("firebase-functions");
const {
  assertCanDeleteLostObject,
  buildClaim,
  buildCustodyPointUpdate,
  buildDelivery,
  buildLostObject,
  buildPointPayload,
  buildRejection,
  requireString,
} = require("../logic/lost_objects");
const {deleteFilesFromUrls} = require("../utils/storage");
const {isPending, markError, markOk} = require("../utils/requests");

function createLostObjectHandlers({admin, db, bucket}) {
  const fieldValue = admin.firestore.FieldValue;
  const timestamp = admin.firestore.Timestamp;

  const getUser = async (uid) => {
    const userId = requireString(uid, "solicitanteUid");
    const snap = await db.collection("usuarios").doc(userId).get();
    if (!snap.exists) {
      throw new Error("Usuario solicitante no existe.");
    }
    return {id: snap.id, ...snap.data()};
  };

  const requireAdmin = async (uid) => {
    const user = await getUser(uid);
    if (user.tipoUsuario !== "admin") {
      throw new Error("La accion requiere permisos de administrador.");
    }
    return user;
  };

  const crearObjetoPerdido = functions.firestore
      .document("solicitudes_crear_objeto_perdido/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          const requester = await getUser(data.solicitanteUid);
          const objectData = buildLostObject(
              data.payload || {},
              requester,
              fieldValue,
          );
          const objectRef = await db.collection("objetos_perdidos").add(objectData);
          await markOk(snapshot.ref, {objetoId: objectRef.id}, fieldValue);
        } catch (error) {
          console.error("crearObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const reclamarObjetoPerdido = functions.firestore
      .document("solicitudes_reclamar_objeto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          const requester = await getUser(data.solicitanteUid);
          const payload = data.payload || {};
          const objectId = requireString(payload.objetoId, "objetoId");

          await db.runTransaction(async (transaction) => {
            const objectRef = db.collection("objetos_perdidos").doc(objectId);
            const objectSnap = await transaction.get(objectRef);
            if (!objectSnap.exists) {
              throw new Error("Objeto perdido no existe.");
            }

            const update = buildClaim(
                objectSnap.data(),
                payload,
                requester,
                timestamp.now(),
            );
            transaction.update(objectRef, update);
          });

          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("reclamarObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const aprobarObjetoPerdido = functions.firestore
      .document("solicitudes_aprobar_objeto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const payload = data.payload || {};
          const objectId = requireString(payload.objetoId, "objetoId");
          const update = {aprobado: true};

          if (payload.puntoCustodiaId) {
            const pointId = requireString(payload.puntoCustodiaId, "puntoCustodiaId");
            const pointSnap = await db.collection("puntos_objetos_perdidos")
                .doc(pointId)
                .get();
            if (!pointSnap.exists) {
              throw new Error("Punto de entrega no existe.");
            }
            Object.assign(
                update,
                buildCustodyPointUpdate(
                    {id: pointSnap.id, ...pointSnap.data()},
                    timestamp.now(),
                ),
            );
          }

          await db.collection("objetos_perdidos").doc(objectId).update(update);
          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("aprobarObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const recibirObjetoEnPunto = functions.firestore
      .document("solicitudes_recibir_objeto_en_punto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const payload = data.payload || {};
          const objectId = requireString(payload.objetoId, "objetoId");
          const pointId = requireString(payload.puntoCustodiaId, "puntoCustodiaId");

          await db.runTransaction(async (transaction) => {
            const objectRef = db.collection("objetos_perdidos").doc(objectId);
            const pointRef = db.collection("puntos_objetos_perdidos").doc(pointId);
            const [objectSnap, pointSnap] = await Promise.all([
              transaction.get(objectRef),
              transaction.get(pointRef),
            ]);

            if (!objectSnap.exists) {
              throw new Error("Objeto perdido no existe.");
            }
            if (!pointSnap.exists) {
              throw new Error("Punto de entrega no existe.");
            }
            if (objectSnap.data().estadoReclamacion === "Entregado") {
              throw new Error("No puedes recibir un objeto ya entregado.");
            }

            transaction.update(
                objectRef,
                buildCustodyPointUpdate(
                    {id: pointSnap.id, ...pointSnap.data()},
                    timestamp.now(),
                ),
            );
          });

          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("recibirObjetoEnPunto", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const rechazarObjetoPerdido = functions.firestore
      .document("solicitudes_rechazar_objeto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const objectId = requireString(data.payload && data.payload.objetoId, "objetoId");
          const objectRef = db.collection("objetos_perdidos").doc(objectId);
          const objectSnap = await objectRef.get();
          if (!objectSnap.exists) {
            throw new Error("Objeto perdido no existe.");
          }

          await objectRef.update(buildRejection(objectSnap.data()));
          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("rechazarObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const entregarObjetoPerdido = functions.firestore
      .document("solicitudes_entregar_objeto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const payload = data.payload || {};
          const objectId = requireString(payload.objetoId, "objetoId");
          const uidReclamante = requireString(payload.uidReclamante, "uidReclamante");

          await db.runTransaction(async (transaction) => {
            const objectRef = db.collection("objetos_perdidos").doc(objectId);
            const objectSnap = await transaction.get(objectRef);
            if (!objectSnap.exists) {
              throw new Error("Objeto perdido no existe.");
            }

            transaction.update(
                objectRef,
                buildDelivery(objectSnap.data(), uidReclamante),
            );
          });

          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("entregarObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const eliminarObjetoPerdido = functions.firestore
      .document("solicitudes_eliminar_objeto/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          const requester = await getUser(data.solicitanteUid);
          const payload = data.payload || {};
          const objectId = requireString(payload.objetoId, "objetoId");
          const objectRef = db.collection("objetos_perdidos").doc(objectId);
          const objectSnap = await objectRef.get();

          if (!objectSnap.exists) {
            throw new Error("Objeto perdido no existe.");
          }

          const objectData = objectSnap.data();
          const isOwner = objectData.uidEncontrado === requester.id;
          const isAdmin = requester.tipoUsuario === "admin";
          if (!isOwner && !isAdmin) {
            throw new Error("No tienes permiso para eliminar este objeto.");
          }

          assertCanDeleteLostObject(objectData);

          await objectRef.delete();
          await deleteFilesFromUrls(
              bucket,
              payload.imageUrls || objectData.imageUrls || [objectData.imagenUrl],
          );

          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("eliminarObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const guardarPuntoObjetoPerdido = functions.firestore
      .document("solicitudes_guardar_punto_objeto_perdido/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const payload = data.payload || {};
          const pointData = {
            ...buildPointPayload(payload),
            updatedAt: fieldValue.serverTimestamp(),
          };
          const pointId = typeof payload.puntoId === "string" ?
            payload.puntoId.trim() :
            "";

          let pointRef;
          if (pointId) {
            pointRef = db.collection("puntos_objetos_perdidos").doc(pointId);
            await pointRef.set(pointData, {merge: true});
          } else {
            pointRef = await db.collection("puntos_objetos_perdidos").add({
              ...pointData,
              createdAt: fieldValue.serverTimestamp(),
            });
          }

          await markOk(snapshot.ref, {puntoId: pointRef.id}, fieldValue);
        } catch (error) {
          console.error("guardarPuntoObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const eliminarPuntoObjetoPerdido = functions.firestore
      .document("solicitudes_eliminar_punto_objeto_perdido/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const pointId = requireString(
              data.payload && data.payload.puntoId,
              "puntoId",
          );
          await db.collection("puntos_objetos_perdidos").doc(pointId).set({
            activo: false,
            updatedAt: fieldValue.serverTimestamp(),
          }, {merge: true});

          await markOk(snapshot.ref, {puntoId: pointId}, fieldValue);
        } catch (error) {
          console.error("eliminarPuntoObjetoPerdido", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  return {
    aprobarObjetoPerdido,
    crearObjetoPerdido,
    eliminarObjetoPerdido,
    eliminarPuntoObjetoPerdido,
    entregarObjetoPerdido,
    guardarPuntoObjetoPerdido,
    recibirObjetoEnPunto,
    reclamarObjetoPerdido,
    rechazarObjetoPerdido,
  };
}

module.exports = {
  createLostObjectHandlers,
};
