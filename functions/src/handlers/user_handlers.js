"use strict";

const functions = require("firebase-functions");
const {requireString} = require("../logic/lost_objects");
const {isPending, markError, markOk} = require("../utils/requests");

function createUserHandlers({admin, db}) {
  const fieldValue = admin.firestore.FieldValue;

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

  const userPayload = (payload) => {
    const id = requireString(payload.id, "id");
    return {
      id,
      nombre: requireString(payload.nombre, "nombre"),
      apellido: requireString(payload.apellido, "apellido"),
      correo: requireString(payload.correo, "correo"),
      urlimagen: payload.urlimagen || "",
      tipoUsuario: payload.tipoUsuario || "user",
    };
  };

  const registrarUsuario = functions.firestore
      .document("solicitudes_registro_usuario/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          const user = userPayload(data.payload || {});
          await db.collection("usuarios").doc(user.id).set(user, {merge: true});
          await markOk(snapshot.ref, {usuarioId: user.id}, fieldValue);
        } catch (error) {
          console.error("registrarUsuario", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const actualizarUsuario = functions.firestore
      .document("solicitudes_actualizar_usuario/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          const requester = await getUser(data.solicitanteUid);
          const user = userPayload(data.payload || {});
          const isAdmin = requester.tipoUsuario === "admin";
          if (requester.id !== user.id && !isAdmin) {
            throw new Error("No tienes permiso para actualizar este usuario.");
          }

          if (!isAdmin) {
            user.tipoUsuario = requester.tipoUsuario || "user";
          }

          await db.collection("usuarios").doc(user.id).update(user);
          await markOk(snapshot.ref, {usuarioId: user.id}, fieldValue);
        } catch (error) {
          console.error("actualizarUsuario", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const eliminarUsuario = functions.firestore
      .document("solicitudes_eliminar_usuario/{solicitudId}")
      .onCreate(async (snapshot) => {
        const data = snapshot.data() || {};
        if (!isPending(data)) return;

        try {
          await requireAdmin(data.solicitanteUid);
          const uid = requireString(data.payload && data.payload.uid, "uid");
          await admin.auth().deleteUser(uid);
          await db.collection("usuarios").doc(uid).delete();
          await markOk(snapshot.ref, {usuarioId: uid}, fieldValue);
        } catch (error) {
          console.error("eliminarUsuario", error);
          await markError(snapshot.ref, error, fieldValue);
        }
      });

  const deleteUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
          "unauthenticated",
          "La solicitud debe provenir de un usuario autenticado.",
      );
    }

    await requireAdmin(context.auth.uid);
    const uid = requireString(data.uid, "uid");
    await admin.auth().deleteUser(uid);
    await db.collection("usuarios").doc(uid).delete();
    return {message: `Usuario ${uid} eliminado exitosamente.`};
  });

  return {
    actualizarUsuario,
    deleteUser,
    eliminarUsuario,
    registrarUsuario,
  };
}

module.exports = {
  createUserHandlers,
};
