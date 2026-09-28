// lib/admin-api.ts - Client de l'espace administrateur : jetons JWT en
// localStorage. La session survit à l'expiration du jeton d'accès grâce
// au refresh token (rotation côté serveur) ; redirection vers
// /admin/login seulement quand le refresh lui-même est refusé.

export const ADMIN_TOKEN_KEY = 'epilist-admin-token';
export const ADMIN_REFRESH_KEY = 'epilist-admin-refresh';

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'https://m2atodev.com/api.epilist/public';

export function getAdminToken(): string | null {
  try {
    return localStorage.getItem(ADMIN_TOKEN_KEY);
  } catch {
    return null;
  }
}

function getAdminRefreshToken(): string | null {
  try {
    return localStorage.getItem(ADMIN_REFRESH_KEY);
  } catch {
    return null;
  }
}

export function setAdminTokens(access: string | null, refresh?: string | null) {
  try {
    if (access) localStorage.setItem(ADMIN_TOKEN_KEY, access);
    else localStorage.removeItem(ADMIN_TOKEN_KEY);
    if (refresh !== undefined) {
      if (refresh) localStorage.setItem(ADMIN_REFRESH_KEY, refresh);
      else localStorage.removeItem(ADMIN_REFRESH_KEY);
    }
  } catch {}
}

/** Compat : les appels existants (déconnexion) passent par setAdminToken. */
export function setAdminToken(token: string | null) {
  setAdminTokens(token, token === null ? null : undefined);
}

export class AdminApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

function redirectToLogin() {
  setAdminTokens(null, null);
  if (typeof window !== 'undefined') {
    window.location.href = '/admin/login';
  }
}

// Un seul refresh à la fois : avec la ROTATION serveur, deux refresh
// concurrents feraient partir le second avec un jeton déjà révoqué.
let refreshInFlight: Promise<boolean> | null = null;

async function tryRefresh(): Promise<boolean> {
  refreshInFlight ??= (async () => {
    const refreshToken = getAdminRefreshToken();
    if (!refreshToken) return false;
    try {
      const res = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: refreshToken }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok || !data?.access_token) return false;
      setAdminTokens(data.access_token, data.refresh_token ?? undefined);
      return true;
    } catch {
      return false;
    } finally {
      // Libéré après coup : le prochain 401 pourra retenter un refresh.
      setTimeout(() => {
        refreshInFlight = null;
      }, 0);
    }
  })();
  return refreshInFlight;
}

async function rawRequest(method: string, path: string, body?: unknown) {
  const token = getAdminToken();
  const res = await fetch(`${API_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => null);
  return { res, data };
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown
): Promise<T> {
  let { res, data } = await rawRequest(method, path, body);

  // Jeton d'accès expiré : on tente UN refresh puis on rejoue la requête.
  if (res.status === 401) {
    const refreshed = await tryRefresh();
    if (refreshed) {
      ({ res, data } = await rawRequest(method, path, body));
    }
  }

  if (res.status === 401 || res.status === 403) {
    redirectToLogin();
    throw new AdminApiError(data?.message ?? 'Session expirée', res.status);
  }
  if (!res.ok || data?.success === false) {
    throw new AdminApiError(data?.message ?? `Erreur ${res.status}`, res.status);
  }
  return data as T;
}

export const adminApi = {
  get: <T>(path: string) => request<T>('GET', path),
  put: <T>(path: string, body: unknown) => request<T>('PUT', path, body),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, body),
  del: <T>(path: string) => request<T>('DELETE', path),

  /** Étape 1 de la connexion admin : envoie le code OTP par email. */
  async requestOtp(email: string, password: string): Promise<void> {
    const res = await fetch(`${API_URL}/auth/admin/otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok || !data?.success) {
      throw new AdminApiError(data?.message ?? 'Connexion refusée', res.status);
    }
  },

  /** Étape 2 : vérifie le code et récupère les jetons (accès + refresh). */
  async verifyOtp(email: string, code: string): Promise<void> {
    const res = await fetch(`${API_URL}/auth/admin/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, code }),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok || !data?.success) {
      throw new AdminApiError(
        data?.message ?? 'Code invalide ou expiré',
        res.status
      );
    }
    setAdminTokens(data.access_token, data.refresh_token ?? null);
  },
};
