"use strict";

function requireString(value, fieldName) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${fieldName} es requerido.`);
  }
  return value.trim();
}

function buildLostObject(payload, requester, fieldValue) {
  const descripcion = requireString(payload.descripcion, "descripcion");
  const tipoObjeto = requireString(payload.tipoObjeto, "tipoObjeto");
  const lugarEncontrado = requireString(payload.lugarEncontrado, "lugarEncontrado");
  const imageUrls = Array.isArray(payload.imageUrls) ? payload.imageUrls : [];

  if (imageUrls.length === 0) {
    throw new Error("Debe existir al menos una imagen del objeto.");
  }

  return {
    descripcion,
    tipoObjeto,
    tipoObjetoBusqueda: (payload.tipoObjetoBusqueda || tipoObjeto).toLowerCase(),
    lugarEncontrado,
    estadoReclamacion: "No reclamado",
    imagenUrl: imageUrls[0],
    aprobado: requester.tipoUsuario === "admin",
    imageUrls,
    nombreEncontrado: requester.nombre,
    uidEncontrado: requester.id,
    timestamp: fieldValue.serverTimestamp(),
    latitud: typeof payload.latitud === "number" ? payload.latitud : null,
    longitud: typeof payload.longitud === "number" ? payload.longitud : null,
    custodiaEstado: "con_usuario",
    custodiaUid: requester.id,
    custodiaNombre: requester.nombre,
    puntoCustodiaId: null,
    puntoCustodiaNombre: null,
    puntoCustodiaLatitud: null,
    puntoCustodiaLongitud: null,
    fechaRecepcionPunto: null,
    reclamaciones: [],
    reclamacionesUids: [],
  };
}

function buildClaim(existingObject, claimPayload, requester, timestamp) {
  const textoReclamacion = requireString(
      claimPayload.textoReclamacion,
      "textoReclamacion",
  );
  const reclamaciones = Array.isArray(existingObject.reclamaciones) ?
    existingObject.reclamaciones :
    [];

  if (existingObject.uidEncontrado === requester.id) {
    throw new Error("No puedes reclamar un objeto que registraste.");
  }

  if (existingObject.estadoReclamacion === "Entregado") {
    throw new Error("El objeto ya fue entregado.");
  }

  if (reclamaciones.some((claim) => claim.uidReclamante === requester.id)) {
    throw new Error("Ya existe una reclamacion de este usuario.");
  }

  const nuevaReclamacion = {
    uidReclamante: requester.id,
    fotoReclamante: requester.urlimagen || "",
    nombreReclamante: requester.nombre || "",
    apellidoReclamante: requester.apellido || "",
    estadoReclamacion: "Pendiente",
    textoReclamacion,
    imagenReclamacionUrl: claimPayload.imagenReclamacionUrl || null,
    horaReclamacion: timestamp,
  };

  const nuevasReclamaciones = [...reclamaciones, nuevaReclamacion];
  const reclamacionesUids = [...new Set(
      nuevasReclamaciones.map((claim) => claim.uidReclamante),
  )];

  return {
    reclamaciones: nuevasReclamaciones,
    reclamacionesUids,
    estadoReclamacion: "Pendiente",
  };
}

function buildDelivery(existingObject, uidReclamante) {
  requireString(uidReclamante, "uidReclamante");

  const reclamaciones = Array.isArray(existingObject.reclamaciones) ?
    existingObject.reclamaciones :
    [];
  const selectedClaim = reclamaciones.find(
      (claim) => claim.uidReclamante === uidReclamante,
  );

  if (!selectedClaim) {
    throw new Error("La reclamacion seleccionada no existe.");
  }

  if (existingObject.estadoReclamacion === "Entregado") {
    throw new Error("El objeto ya fue entregado.");
  }

  const updatedReclamaciones = reclamaciones.map((claim) => ({
    ...claim,
    estadoReclamacion: claim.uidReclamante === uidReclamante ?
      "Entregado" :
      "Rechazado",
  }));

  return {
    estadoReclamacion: "Entregado",
    uidReclamado: selectedClaim.uidReclamante,
    nombreReclamado: selectedClaim.nombreReclamante,
    custodiaEstado: "entregado",
    custodiaUid: selectedClaim.uidReclamante,
    custodiaNombre: selectedClaim.nombreReclamante,
    reclamaciones: updatedReclamaciones,
  };
}

function buildPointPayload(payload) {
  const nombre = requireString(payload.nombre, "nombre");
  const tipo = requireString(payload.tipo, "tipo");

  if (!["entrega", "reclamacion", "ambos"].includes(tipo)) {
    throw new Error("tipo de punto invalido.");
  }

  if (typeof payload.latitud !== "number" ||
      typeof payload.longitud !== "number") {
    throw new Error("La ubicacion del punto es requerida.");
  }

  return {
    nombre,
    descripcion: typeof payload.descripcion === "string" ?
      payload.descripcion.trim() :
      "",
    tipo,
    latitud: payload.latitud,
    longitud: payload.longitud,
    activo: payload.activo !== false,
  };
}

function buildCustodyPointUpdate(point, timestamp) {
  if (!point || point.activo === false) {
    throw new Error("El punto seleccionado no esta activo.");
  }

  if (point.tipo !== "entrega" && point.tipo !== "ambos") {
    throw new Error("El punto seleccionado no recibe objetos perdidos.");
  }

  return {
    custodiaEstado: "en_punto",
    custodiaUid: null,
    custodiaNombre: point.nombre,
    puntoCustodiaId: point.id,
    puntoCustodiaNombre: point.nombre,
    puntoCustodiaLatitud: point.latitud,
    puntoCustodiaLongitud: point.longitud,
    fechaRecepcionPunto: timestamp,
  };
}

function buildRejection(existingObject) {
  if (existingObject.estadoReclamacion === "Entregado") {
    throw new Error("No puedes rechazar un objeto ya entregado.");
  }

  return {
    aprobado: false,
    rechazado: true,
  };
}

module.exports = {
  buildClaim,
  buildDelivery,
  buildLostObject,
  buildCustodyPointUpdate,
  buildPointPayload,
  buildRejection,
  requireString,
};
