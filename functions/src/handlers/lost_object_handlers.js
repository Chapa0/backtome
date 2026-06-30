"use strict";

const functions = require("firebase-functions");
const {
  buildClaim,
  buildDelivery,
  buildLostObject,
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
          const objectId = requireString(data.payload && data.payload.objetoId, "objetoId");
          await db.collection("objetos_perdidos").doc(objectId).update({
            aprobado: true,
          });
          await markOk(snapshot.ref, {objetoId: objectId}, fieldValue);
        } catch (error) {
          console.error("aprobarObjetoPerdido", error);
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

  return {
    aprobarObjetoPerdido,
    crearObjetoPerdido,
    eliminarObjetoPerdido,
    entregarObjetoPerdido,
    reclamarObjetoPerdido,
    rechazarObjetoPerdido,
  };
}

module.exports = {
  createLostObjectHandlers,
};
