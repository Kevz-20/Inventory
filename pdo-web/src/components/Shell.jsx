export default function Shell({
  title,
  subtitle,
  activeScreen,
  onScreenChange,
  onRefreshAll,
  onResetTestData,
  resettingTestData,
  onLogout,
  lastRefresh,
  children,
}) {
  const navItems = [
    { id: 'overview', label: 'Dashboard' },
    { id: 'associations', label: 'Associations' },
    { id: 'members', label: 'Members' },
    { id: 'activity', label: 'Activity Log' },
    { id: 'sync', label: 'Sync Health' },
  ];

  return (
    <div className="shell">
      <header className="appbar">
        <div className="brand">
          <div className="mark">PDO</div>
          <div className="brand-title">PDO-DSWD</div>
        </div>

        <nav className="nav nav-top">
          {navItems.map((item) => (
            <button
              key={item.id}
              className={activeScreen === item.id ? 'active' : ''}
              onClick={() => onScreenChange(item.id)}
            >
              {item.label}
            </button>
          ))}
        </nav>

        <div className="topactions">
          <div className="pill">Backend Connected</div>
          <button className="danger" onClick={onResetTestData} disabled={resettingTestData}>
            {resettingTestData ? 'Resetting...' : 'Reset Test Data'}
          </button>
          <button className="ghost" onClick={onRefreshAll}>
            Refresh All
          </button>
          <div className="stamp">Last refresh: {lastRefresh}</div>
          <button className="logout logout-danger" onClick={onLogout}>
            Logout
          </button>
        </div>
      </header>

      <main className="content">
        <div className="top">
          <div>
            <h2>{title}</h2>
            <p>{subtitle}</p>
          </div>
        </div>

        {children}
      </main>
    </div>
  );
}
