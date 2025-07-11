// app/.well-known/apple-app-site-association/route.js

import { NextResponse } from "next/server";

export async function GET() {
  // Configuration Universal Links avec votre Team ID
  const association = {
    applinks: {
      apps: [], // Toujours vide selon Apple
      details: [
        {
          appIDs: ["79F8TZGAPL.com.m2atech.epilist"],
          components: [
            {
              "/": "/share/*",
              comment: "Liens de partage de listes EpiList",
            },
          ],
        },
      ],
    },
    webcredentials: {
      apps: ["79F8TZGAPL.com.m2atech.epilist"],
    },
  };

  // Retourner la réponse JSON avec les bons headers
  return NextResponse.json(association, {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=86400",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
