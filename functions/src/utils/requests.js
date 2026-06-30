"use strict";

async function markOk(ref, data, fieldValue) {
  await ref.set({
    estado: "ok",
    updatedAt: fieldValue.serverTimestamp(),
    ...data,
  }, {merge: true});
}

async function markError(ref, error, fieldValue) {
  const message = error instanceof Error ? error.message : String(error);
  await ref.set({
    estado: "error",
    errorMensaje: message,
    updatedAt: fieldValue.serverTimestamp(),
  }, {merge: true});
}

function isPending(data) {
  return !data.estado || data.estado === "pendiente";
}

module.exports = {
  isPending,
  markError,
  markOk,
};
