// lib/admin-api.ts - Client de l'espace administrateur : jeton JWT en
// localStorage, redirection vers /admin/login si la session expire.

export const ADMIN_TOKEN_KEY = 'epilist-admin-token';

const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? 'https://m2atodev.com/api.epilist/public';

export function getAdminToken(): string | null {
  try {
    return localStorage.getItem(ADMIN_TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setAdminToken(token: string | null) {
  try {
    if (token) localStorage.setItem(ADMIN_TOKEN_KEY, token);
    else localStorage.removeItem(ADMIN_TOKEN_KEY);
  } catch {}
}

export class AdminApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown
): Promise<T> {
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

  if (res.status === 401 || res.status === 403) {
    setAdminToken(null);
    if (typeof window !== 'undefined') {
      window.location.href = '/admin/login';
    }
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

  /** Étape 2 : vérifie le code et récupère les jetons. */
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
    setAdminToken(data.access_token);
  },
};
