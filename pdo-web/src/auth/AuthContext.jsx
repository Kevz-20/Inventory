import { createContext, useContext, useEffect, useMemo, useState } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;

    async function loadSession() {
      try {
        const response = await fetch('/api/pdo/session', {
          credentials: 'include',
        });
        const data = await response.json();
        if (!active) return;
        setUser(data.authenticated ? data.user : null);
      } catch (_) {
        if (active) setUser(null);
      } finally {
        if (active) setLoading(false);
      }
    }

    loadSession();
    return () => {
      active = false;
    };
  }, []);

  const value = useMemo(
    () => ({
      user,
      loading,
      async login(email, password) {
        const response = await fetch('/api/pdo/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({ email, password }),
        });
        const data = await response.json();
        if (!response.ok || data.success === false) {
          throw new Error(data.message || 'Login failed.');
        }
        const sessionResponse = await fetch('/api/pdo/session', {
          credentials: 'include',
        });
        const sessionData = await sessionResponse.json();
        setUser(sessionData.user);
      },
      async logout() {
        await fetch('/api/pdo/logout', {
          method: 'POST',
          credentials: 'include',
        });
        setUser(null);
      },
    }),
    [loading, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error('useAuth must be used inside AuthProvider');
  return value;
}
