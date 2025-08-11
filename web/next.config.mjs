/** @type {import('next').NextConfig} */

const nextConfig = {
  // Configuration pour Vercel
  output: "standalone",

  // Headers de sécurité
  async headers() {
    return [
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
        destination: "/conditions-utilisation",
        permanent: true,
      },
      {
        source: "/privacy",
        destination: "/politique-confidentialite",
        permanent: true,
      },
      {
        source: "/download",
        destination: "/telecharger",
        permanent: true,
      },
      {
        source: "/features",
        destination: "/fonctionnalites",
        permanent: true,
      },
      {
        source: "/help",
        destination: "/aide",
        permanent: true,
      },
      {
        source: "/about",
        destination: "/a-propos",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
