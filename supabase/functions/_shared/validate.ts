export type ValidationResult = { ok: true } | { ok: false; message: string }

// Basic email shape check — full RFC compliance is delegated to Supabase Auth
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
// Usernames: letters, digits, underscores, hyphens only
const USERNAME_RE = /^[a-zA-Z0-9_-]+$/

export function validateEmail(value: unknown): ValidationResult {
  if (typeof value !== 'string' || value.trim().length === 0) {
    return { ok: false, message: 'email is required' }
  }
  if (value.length > 254) {
    return { ok: false, message: 'email is too long' }
  }
  if (!EMAIL_RE.test(value.trim())) {
    return { ok: false, message: 'invalid email format' }
  }
  return { ok: true }
}

export function validateUsername(value: unknown): ValidationResult {
  if (typeof value !== 'string' || value.trim().length === 0) {
    return { ok: false, message: 'username is required' }
  }
  const u = value.trim()
  if (u.length < 3) return { ok: false, message: 'username must be at least 3 characters' }
  if (u.length > 30) return { ok: false, message: 'username must be at most 30 characters' }
  if (!USERNAME_RE.test(u)) {
    return { ok: false, message: 'username may only contain letters, numbers, underscores, and hyphens' }
  }
  return { ok: true }
}

/**
 * Validates a password for the login path.
 * Enforces only non-empty + max length — existing accounts may predate any
 * minimum-length policy, so min-length is only checked during signup (Dart layer).
 */
export function validatePassword(value: unknown): ValidationResult {
  if (typeof value !== 'string' || value.length === 0) {
    return { ok: false, message: 'password is required' }
  }
  if (value.length > 128) {
    return { ok: false, message: 'password is too long' }
  }
  return { ok: true }
}

/** Returns field names in `body` that are not in `allowed`. */
export function unexpectedFields(body: Record<string, unknown>, allowed: string[]): string[] {
  return Object.keys(body).filter((k) => !allowed.includes(k))
}
