"use strict";

const admin = require("firebase-admin");
const {createLostObjectHandlers} = require("./src/handlers/lost_object_handlers");
const {createUserHandlers} = require("./src/handlers/user_handlers");

admin.initializeApp({
  storageBucket: "back-to-me-48f22.firebasestorage.app",
});

const db = admin.firestore();
db.settings({ignoreUndefinedProperties: true});

const bucket = admin.storage().bucket();

const lostObjectHandlers = createLostObjectHandlers({admin, db, bucket});
const userHandlers = createUserHandlers({admin, db});

exports.crearObjetoPerdido = lostObjectHandlers.crearObjetoPerdido;
exports.reclamarObjetoPerdido = lostObjectHandlers.reclamarObjetoPerdido;
exports.aprobarObjetoPerdido = lostObjectHandlers.aprobarObjetoPerdido;
exports.rechazarObjetoPerdido = lostObjectHandlers.rechazarObjetoPerdido;
exports.entregarObjetoPerdido = lostObjectHandlers.entregarObjetoPerdido;
exports.eliminarObjetoPerdido = lostObjectHandlers.eliminarObjetoPerdido;

exports.registrarUsuario = userHandlers.registrarUsuario;
exports.actualizarUsuario = userHandlers.actualizarUsuario;
exports.eliminarUsuario = userHandlers.eliminarUsuario;
exports.deleteUser = userHandlers.deleteUser;
