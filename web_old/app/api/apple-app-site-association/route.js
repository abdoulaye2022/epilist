// app/api/apple-app-site-association/route.ts - IOS UNIVERSAL LINKS API
import { NextResponse } from "next/server";

export async function GET() {
  const appleAssociation = {
    applinks: {
      apps: [],
      details: [
        {
          appID:
            process.env.IOS_TEAM_ID +
            "." +
            (process.env.NEXT_PUBLIC_IOS_BUNDLE_ID || "com.m2atech.epilist"),
          paths: ["/share/*"],
        },
      ],
    },
    webcredentials: {
      apps: [
        process.env.IOS_TEAM_ID +
          "." +
          (process.env.NEXT_PUBLIC_IOS_BUNDLE_ID || "com.m2atech.epilist"),
      ],
    },
  };

  return NextResponse.json(appleAssociation, {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=86400", // Cache 24h
    },
  });
}
