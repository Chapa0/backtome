"use strict";

function storagePathFromUrl(url) {
  if (typeof url !== "string" || url.trim() === "") {
    return null;
  }

  try {
    const parsed = new URL(url);
    if (parsed.hostname === "firebasestorage.googleapis.com") {
      const match = parsed.pathname.match(/\/o\/(.+)$/);
      return match ? decodeURIComponent(match[1]) : null;
    }

    if (parsed.hostname === "storage.googleapis.com") {
      const parts = parsed.pathname.split("/").filter(Boolean);
      return parts.length >= 2 ? parts.slice(1).join("/") : null;
    }
  } catch (error) {
    return null;
  }

  return null;
}

async function deleteFilesFromUrls(bucket, urls) {
  const uniquePaths = [...new Set(
      (Array.isArray(urls) ? urls : [])
          .map(storagePathFromUrl)
          .filter(Boolean),
  )];

  await Promise.all(uniquePaths.map(async (path) => {
    try {
      await bucket.file(path).delete({ignoreNotFound: true});
    } catch (error) {
      console.error(`No se pudo eliminar Storage file ${path}`, error);
    }
  }));
}

module.exports = {
  deleteFilesFromUrls,
  storagePathFromUrl,
};
