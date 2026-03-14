import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

export default function LoginPage() {
  const { user, login, loading } = useAuth();
  const [email, setEmail] = useState('pdo@inventory.local');
  const [password, setPassword] = useState('ChangeMe123!');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  if (!loading && user) {
    return <Navigate to="/" replace />;
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message || 'Login failed.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-layout">
        <section className="login-hero">
          <div className="login-hero-center">
            <div className="login-hero-badge">PDO Portal</div>
            <h1>Association Monitoring Portal</h1>
          </div>
        </section>

        <section className="login-form-panel">
          <div className="auth-card">
            <div className="auth-kicker">Staff Sign In</div>
            <h2>Sign In to Continue</h2>
            <form onSubmit={handleSubmit}>
              <label>Email Address</label>
              <input
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                type="email"
                autoComplete="username"
                required
              />
              <label>Password</label>
              <input
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                type="password"
                autoComplete="current-password"
                required
              />
              <button type="submit" disabled={submitting}>
                {submitting ? 'Signing In...' : 'Open Dashboard'}
              </button>
            </form>
            <div className="status-text">{error}</div>
          </div>
        </section>
      </div>
    </div>
  );
}
