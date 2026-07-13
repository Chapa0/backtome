"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  assertCanDeleteLostObject,
  buildClaim,
  buildCustodyPointUpdate,
  buildDelivery,
  buildLostObject,
  buildPointPayload,
  buildRejection,
} = require("../src/logic/lost_objects");

const fieldValue = {
  serverTimestamp: () => "SERVER_TIMESTAMP",
};

test("buildLostObject creates the final object from request payload", () => {
  const result = buildLostObject(
      {
        descripcion: "Mochila negra",
        tipoObjeto: "Mochila",
        lugarEncontrado: "Biblioteca",
        imageUrls: ["https://example.com/1.jpg"],
      },
      {
        id: "u1",
        nombre: "Ana",
        tipoUsuario: "user",
      },
      fieldValue,
  );

  assert.equal(result.aprobado, false);
  assert.equal(result.estadoReclamacion, "No reclamado");
  assert.equal(result.uidEncontrado, "u1");
  assert.equal(result.custodiaEstado, "con_usuario");
  assert.equal(result.custodiaUid, "u1");
  assert.equal(result.custodiaNombre, "Ana");
  assert.deepEqual(result.reclamaciones, []);
});

test("buildClaim rejects duplicate claims by same user", () => {
  assert.throws(
      () => buildClaim(
          {
            uidEncontrado: "owner",
            reclamaciones: [{uidReclamante: "u1"}],
          },
          {textoReclamacion: "Es mio"},
          {id: "u1"},
          "NOW",
      ),
      /Ya existe/,
  );
});

test("buildClaim appends claim and marks object pending", () => {
  const result = buildClaim(
      {
        uidEncontrado: "owner",
        reclamaciones: [],
      },
      {textoReclamacion: "Tiene una etiqueta", imagenReclamacionUrl: null},
      {
        id: "u1",
        nombre: "Ana",
        apellido: "Lopez",
        urlimagen: "",
      },
      "NOW",
  );

  assert.equal(result.estadoReclamacion, "Pendiente");
  assert.deepEqual(result.reclamacionesUids, ["u1"]);
  assert.equal(result.reclamaciones[0].estadoReclamacion, "Pendiente");
  assert.equal(result.reclamaciones[0].horaReclamacion, "NOW");
});

test("buildDelivery marks selected claim delivered and others rejected", () => {
  const result = buildDelivery(
      {
        estadoReclamacion: "Pendiente",
        reclamaciones: [
          {uidReclamante: "u1", nombreReclamante: "Ana"},
          {uidReclamante: "u2", nombreReclamante: "Luis"},
        ],
      },
      "u2",
  );

  assert.equal(result.estadoReclamacion, "Entregado");
  assert.equal(result.uidReclamado, "u2");
  assert.equal(result.nombreReclamado, "Luis");
  assert.equal(result.custodiaEstado, "entregado");
  assert.equal(result.custodiaUid, "u2");
  assert.deepEqual(
      result.reclamaciones.map((claim) => claim.estadoReclamacion),
      ["Rechazado", "Entregado"],
  );
});

test("buildPointPayload validates and normalizes a delivery point", () => {
  const result = buildPointPayload({
    nombre: "Prefectura",
    descripcion: "Ventanilla principal",
    tipo: "ambos",
    latitud: 19.1,
    longitud: -96.1,
  });

  assert.equal(result.nombre, "Prefectura");
  assert.equal(result.tipo, "ambos");
  assert.equal(result.activo, true);
});

test("buildCustodyPointUpdate marks object custody at a point", () => {
  const result = buildCustodyPointUpdate(
      {
        id: "p1",
        nombre: "Biblioteca",
        tipo: "entrega",
        activo: true,
        latitud: 19.2,
        longitud: -96.2,
      },
      "NOW",
  );

  assert.equal(result.custodiaEstado, "en_punto");
  assert.equal(result.puntoCustodiaId, "p1");
  assert.equal(result.puntoCustodiaNombre, "Biblioteca");
  assert.equal(result.fechaRecepcionPunto, "NOW");
});

test("buildRejection marks an object as rejected", () => {
  const result = buildRejection({
    estadoReclamacion: "No reclamado",
  });

  assert.equal(result.aprobado, false);
  assert.equal(result.rechazado, true);
});

test("buildRejection rejects delivered objects", () => {
  assert.throws(
      () => buildRejection({estadoReclamacion: "Entregado"}),
      /entregado/,
  );
});

test("assertCanDeleteLostObject allows deleting an object without custody or claims", () => {
  assert.doesNotThrow(() => assertCanDeleteLostObject({
    estadoReclamacion: "No reclamado",
    custodiaEstado: "con_usuario",
    reclamaciones: [],
  }));
});

test("assertCanDeleteLostObject rejects objects at a custody point", () => {
  assert.throws(
      () => assertCanDeleteLostObject({
        estadoReclamacion: "No reclamado",
        custodiaEstado: "en_punto",
        reclamaciones: [],
      }),
      /punto de entrega/,
  );
});

test("assertCanDeleteLostObject rejects objects with claims or delivered", () => {
  assert.throws(
      () => assertCanDeleteLostObject({
        estadoReclamacion: "Pendiente",
        custodiaEstado: "con_usuario",
        reclamaciones: [{uidReclamante: "u1"}],
      }),
      /reclamaciones/,
  );
  assert.throws(
      () => assertCanDeleteLostObject({
        estadoReclamacion: "Entregado",
        custodiaEstado: "entregado",
        reclamaciones: [{uidReclamante: "u1"}],
      }),
      /ya entregado/,
  );
});
