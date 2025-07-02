// app/api/invitation/[token]/route.ts - API POUR RÉCUPÉRER LES DONNÉES D'INVITATION
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  request: NextRequest,
  { params }: { params: { token: string } }
) {
  const { token } = params;

  try {
    // ✅ Appel à votre backend API
    const backendUrl =
      process.env.BACKEND_URL || process.env.NEXT_PUBLIC_API_URL;
    const response = await fetch(
      `${backendUrl}/api/share/invitation/${token}`,
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "EpiList-Web/1.0",
        },
        // Optionnel: timeout
        signal: AbortSignal.timeout(10000), // 10s timeout
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();

    // ✅ Transformation des données pour le frontend
    const invitationData = {
      token: data.data.token,
      listName: data.data.list_name,
      ownerName: data.data.owner_name,
      ownerEmail: data.data.owner_email,
      permission: data.data.permission,
      permissionDisplayName: data.data.permission_display_name,
      expiresAt: data.data.expires_at,
      isExpired: data.data.is_expired,
      createdAt: data.data.created_at,
      shoppingList: data.data.shopping_list
        ? {
            id: data.data.shopping_list.id,
            name: data.data.shopping_list.name,
            itemsCount: data.data.shopping_list.items_count,
            purchasedItemsCount: data.data.shopping_list.purchased_items_count,
            totalPrice: data.data.shopping_list.total_price,
            createdAt: data.data.shopping_list.created_at,
          }
        : null,
      shareUrls: data.data.share_urls || {
        app: `epilist://share/${token}`,
        android_store: process.env.NEXT_PUBLIC_ANDROID_STORE_URL,
        ios_store: process.env.NEXT_PUBLIC_IOS_STORE_URL,
      },
    };

    return NextResponse.json(
      {
        success: true,
        data: invitationData,
      },
      {
        headers: {
          "Cache-Control": "private, no-cache", // Pas de cache pour les invitations
        },
      }
    );
  } catch (error) {
    console.error("Erreur API invitation:", error);

    return NextResponse.json(
      {
        success: false,
        error: "Invitation invalide ou expirée",
      },
      {
        status: 404,
        headers: {
          "Cache-Control": "private, no-cache",
        },
      }
    );
  }
}
