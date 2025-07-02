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
      // {
      //   source: '/old-share/:token',
      //   destination: '/share/:token',
      //   permanent: true,
      // },
    ];
  },
};

export default nextConfig;
