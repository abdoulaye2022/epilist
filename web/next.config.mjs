/** @type {import('next').NextConfig} */

const nextConfig = {
  // Configuration pour Vercel
  output: "standalone",

  // Headers de sécurité
  async headers() {
    return [
      {
        // Les deux fichiers qui lient le domaine aux applications.
        // Android et iOS exigent application/json ; l'un des deux n'a
        // pas d'extension, et serait sinon servi en octet-stream puis
        // ignoré en silence. Voir docs/liens-applicatifs.md.
        source: "/.well-known/:fichier(assetlinks.json|apple-app-site-association)",
        headers: [
          { key: "Content-Type", value: "application/json" },
          { key: "Cache-Control", value: "public, max-age=3600" },
        ],
      },
      {
        source: "/(.*)",
        headers: [
          {
            key: "X-Frame-Options",
            value: "DENY",
          },
          {
            key: "X-Content-Type-Options",
            value: "nosniff",
          },
          {
            key: "Referrer-Policy",
            value: "origin-when-cross-origin",
          },
        ],
      },
    ];
  },

  // Redirections si nécessaire
  async redirects() {
    return [
      // Redirection de l'ancienne URL vers la nouvelle si besoin
      {
        source: "/terms",
        destination: "/en/terms-of-use",
        permanent: true,
      },
      {
        source: "/privacy",
        destination: "/en/privacy-policy",
        permanent: true,
      },
      {
        source: "/download",
        destination: "/en/download",
        permanent: true,
      },
      {
        source: "/features",
        destination: "/en/features",
        permanent: true,
      },
      {
        source: "/help",
        destination: "/en/help",
        permanent: true,
      },
      {
        source: "/about",
        destination: "/en/about",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
