import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import Shell from '../components/Shell';
import MetricCard from '../components/MetricCard';
import Panel from '../components/Panel';
import AssociationCard from '../components/AssociationCard';

function fmtDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
}

function startOfToday() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return today;
}

function daysSince(value) {
  if (!value) return Number.POSITIVE_INFINITY;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return Number.POSITIVE_INFINITY;
  return Math.floor((Date.now() - date.getTime()) / (1000 * 60 * 60 * 24));
}

function fullName(row) {
  return [row?.first_name, row?.middle_name, row?.last_name]
    .filter(Boolean)
    .join(' ');
}

export default function DashboardPage() {
  const { user, logout } = useAuth();
  const [screen, setScreen] = useState('overview');
  const [lastRefresh, setLastRefresh] = useState('-');
  const [associations, setAssociations] = useState([]);
  const [members, setMembers] = useState([]);
  const [activity, setActivity] = useState([]);
  const [syncStatus, setSyncStatus] = useState({ recent_batches: [], table_totals: [] });
  const [selectedAssociation, setSelectedAssociation] = useState(null);
  const [details, setDetails] = useState(null);
  const [search, setSearch] = useState('');
  const [memberSearch, setMemberSearch] = useState('');
  const [associationFilter, setAssociationFilter] = useState('');
  const [moduleFilter, setModuleFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [resettingTestData, setResettingTestData] = useState(false);

  const headerTitleByScreen = {
    overview: 'Dashboard',
    associations: 'Associations',
    members: 'Members',
    activity: 'Activity Log',
    sync: 'Sync Health',
  };

  async function fetchJson(url, options = {}) {
    const response = await fetch(url, {
      credentials: 'include',
      ...options,
    });
    const data = await response.json();
    if (!response.ok || data.success === false) {
      throw new Error(data.message || 'Request failed');
    }
    return data;
  }

  async function loadAssociations() {
    const data = await fetchJson('/api/pdo/associations');
    setAssociations(data.associations || []);
  }

  async function loadMembers() {
    const data = await fetchJson('/api/pdo/members');
    setMembers(data.members || []);
  }

  async function loadActivity() {
    const data = await fetchJson('/api/pdo/activity?limit=40');
    setActivity(data.activity || []);
  }

  async function loadSyncStatus() {
    const data = await fetchJson('/api/pdo/sync-status');
    setSyncStatus(data);
  }

  async function loadAssociationDetails(serverId) {
    setSelectedAssociation(serverId);
    const data = await fetchJson(`/api/pdo/associations/${encodeURIComponent(serverId)}`);
    setDetails(data);
  }

  async function reloadAll() {
    await Promise.all([loadAssociations(), loadMembers(), loadActivity(), loadSyncStatus()]);
    setLastRefresh(new Date().toLocaleString());
  }

  async function resetTestData() {
    const confirmed = window.confirm(
      'This will delete all synced testing data in the PDO database. Continue?',
    );
    if (!confirmed) return;

    setResettingTestData(true);
    try {
      await fetchJson('/api/pdo/testing/reset-sync-data', {
        method: 'POST',
      });
      setSelectedAssociation(null);
      setDetails(null);
      await reloadAll();
    } catch (error) {
      window.alert(error.message || 'Failed to reset test data.');
    } finally {
      setResettingTestData(false);
    }
  }

  useEffect(() => {
    reloadAll().catch(() => {});
    const handle = window.setInterval(() => {
      reloadAll().catch(() => {});
    }, 10000);
    return () => window.clearInterval(handle);
  }, []);

  const filteredAssociations = associations.filter((item) =>
    (item.slpa_name || '').toLowerCase().includes(search.toLowerCase()),
  );

  const filteredMembers = members.filter((member) => {
    const row = member.row_data || {};
    const name = fullName(row).toLowerCase();
    const matchesSearch =
      !memberSearch ||
      name.includes(memberSearch.toLowerCase()) ||
      (row.mobile_number || '').toLowerCase().includes(memberSearch.toLowerCase());
    const matchesAssociation =
      !associationFilter || member.slpa_name === associationFilter;
    return matchesSearch && matchesAssociation;
  });

  const moduleOptions = [...new Set(activity.map((entry) => entry.row_data?.module).filter(Boolean))];
  const actionOptions = [...new Set(activity.map((entry) => entry.row_data?.action).filter(Boolean))];
  const activityAssociationOptions = [...new Set(activity.map((entry) => entry.row_data?.slpa_name).filter(Boolean))];

  const [activityAssociationFilter, setActivityAssociationFilter] = useState('');

  const filteredActivity = activity.filter((entry) => {
    const row = entry.row_data || {};
    const matchModule = !moduleFilter || row.module === moduleFilter;
    const matchAction = !actionFilter || row.action === actionFilter;
    const matchAssociation =
      !activityAssociationFilter || row.slpa_name === activityAssociationFilter;
    return matchModule && matchAction && matchAssociation;
  });

  const today = startOfToday();
  const activeAssociationNames = new Set(
    activity
      .filter((entry) => {
        const syncedAt = new Date(entry.synced_at || 0);
        return !Number.isNaN(syncedAt.getTime()) && syncedAt >= today;
      })
      .map((entry) => entry.row_data?.slpa_name)
      .filter(Boolean),
  );

  const associationsActiveToday = activeAssociationNames.size;
  const notSyncingAssociations = associations.filter((item) => daysSince(item.synced_at) > 0);

  const selectedAssociationName =
    details?.association?.row_data?.slpa_name || 'No association selected';
  const selectedAssociationMembers = details?.members || [];
  const selectedAssociationActivity = details?.recent_activity || [];
  const selectedRow = details?.association?.row_data || {};
  const missingContact = !selectedRow.mobile_number;
  const noMembers = selectedAssociationMembers.length === 0;
  const noRecentActivity = selectedAssociationActivity.length === 0;

  const tableTotals = syncStatus.table_totals || [];
  const simplifiedSyncStatus = associations
    .map((association) => ({
      ...association,
      syncState:
        daysSince(association.synced_at) === 0
          ? 'Up to date'
          : daysSince(association.synced_at) <= 3
            ? 'Needs attention'
            : 'Not syncing',
    }))
    .sort((a, b) => daysSince(b.synced_at) - daysSince(a.synced_at));

  const dashboardAttentionItems = useMemo(() => {
    return associations
      .map((association) => {
        const issues = [];
        if ((association.member_count || 0) === 0) issues.push('No members');
        if (!association.mobile_number) issues.push('No contact number');
        if (daysSince(association.synced_at) > 0) issues.push('Not synced today');
        return {
          ...association,
          issues,
        };
      })
      .filter((item) => item.issues.length > 0)
      .slice(0, 6);
  }, [associations]);

  return (
    <Shell
      title={headerTitleByScreen[screen] || 'PDO Monitoring Dashboard'}
      subtitle=""
      activeScreen={screen}
      onScreenChange={setScreen}
      onRefreshAll={() => reloadAll().catch(() => {})}
      onResetTestData={() => resetTestData().catch(() => {})}
      resettingTestData={resettingTestData}
      onLogout={logout}
      lastRefresh={lastRefresh}
    >
      <section className="metrics">
        <MetricCard label="Total Associations" value={associations.length} note="" />
        <MetricCard label="Total Members" value={members.length} note="" />
        <MetricCard label="Active Today" value={associationsActiveToday} note="" />
        <MetricCard label="Not Syncing" value={notSyncingAssociations.length} note="" />
      </section>

      {screen === 'overview' && (
        <>
          <div className="grid">
            <Panel
              title="Association Snapshot"
              subtitle=""
              action={<button className="ghost" onClick={() => loadAssociations().catch(() => {})}>Reload</button>}
            >
              <div className="list">
                {associations.slice(0, 4).map((association) => (
                  <AssociationCard
                    key={association.server_id}
                    association={association}
                    selected={association.server_id === selectedAssociation}
                    onOpen={(serverId) => loadAssociationDetails(serverId).catch(() => {})}
                  />
                ))}
                {associations.length === 0 && <div className="empty">No synced associations yet.</div>}
              </div>
            </Panel>

            <Panel
              title="Needs Attention"
              subtitle=""
              action={<button className="ghost" onClick={() => setScreen('sync')}>Open Sync Health</button>}
            >
              <div className="stack">
                {dashboardAttentionItems.map((item) => (
                  <div key={item.server_id} className="card">
                    <div className="rowtitle">{item.slpa_name}</div>
                    <div className="tags">
                      {item.issues.map((issue) => (
                        <span key={issue} className="tag tag-warning">{issue}</span>
                      ))}
                    </div>
                    <div className="sub">Last synced {fmtDate(item.synced_at)}</div>
                  </div>
                ))}
                {dashboardAttentionItems.length === 0 && (
                  <div className="empty">No associations currently require attention.</div>
                )}
              </div>
            </Panel>
          </div>

          <Panel title="Association Details" subtitle="Profile, members, recent activity, and sync condition">
            {!details && (
              <div className="empty">
                Select an association from any list to inspect its profile, members, and recent activity.
              </div>
            )}
            {details && (
              <>
                <div className="summary-banner">
                  <div className="summary-item">
                    <span className="summary-label">Association</span>
                    <strong>{selectedAssociationName}</strong>
                  </div>
                  <div className="summary-item">
                    <span className="summary-label">Members</span>
                    <strong>{selectedAssociationMembers.length}</strong>
                  </div>
                  <div className="summary-item">
                    <span className="summary-label">Sync Status</span>
                    <strong>{daysSince(details.association?.synced_at) === 0 ? 'Up to date' : 'Needs attention'}</strong>
                  </div>
                  <div className="summary-item">
                    <span className="summary-label">Data Quality</span>
                    <strong>
                      {[missingContact ? 'No contact' : '', noMembers ? 'No members' : '', noRecentActivity ? 'No recent activity' : '']
                        .filter(Boolean)
                        .join(', ') || 'Good'}
                    </strong>
                  </div>
                </div>

                <div className="detail-grid detail-grid-2">
                  <div className="block">
                    <div className="label">Profile</div>
                    <div className="value">{selectedAssociationName}</div>
                    <div className="sub">Contact number: {selectedRow.mobile_number || 'Not provided'}</div>
                  </div>
                  <div className="block">
                    <div className="label">Sync Status</div>
                    <div className="value">{fmtDate(details.association?.synced_at)}</div>
                    <div className="sub">
                      {daysSince(details.association?.synced_at) === 0
                        ? 'This association synced today.'
                        : 'This association has not synced today.'}
                    </div>
                  </div>
                </div>

                <div className="split">
                  <div className="card">
                    <div className="rowtitle">Members</div>
                    <div className="sub">Registered member accounts under this association</div>
                    <div className="stack top-space">
                      {selectedAssociationMembers.map((member) => {
                        const row = member.row_data || {};
                        return (
                          <div key={member.server_id} className="block">
                            <div className="rowtitle">{fullName(row) || 'Unnamed member'}</div>
                            <div className="sub">{row.mobile_number || '-'} / synced {fmtDate(member.synced_at)}</div>
                          </div>
                        );
                      })}
                      {selectedAssociationMembers.length === 0 && (
                        <div className="empty">No members synced yet.</div>
                      )}
                    </div>
                  </div>

                  <div className="card">
                    <div className="rowtitle">Recent Activity</div>
                    <div className="sub">Important actions logged under this association</div>
                    <div className="stack top-space">
                      {selectedAssociationActivity.map((entry) => (
                        <div key={entry.server_id} className="block">
                          <div className="rowtitle">{entry.row_data?.member_name || 'Unknown member'}</div>
                          <div className="sub">
                            {entry.row_data?.module || '-'} / {entry.row_data?.action || '-'} / {fmtDate(entry.synced_at)}
                          </div>
                        </div>
                      ))}
                      {selectedAssociationActivity.length === 0 && (
                        <div className="empty">No recent activity found for this association.</div>
                      )}
                    </div>
                  </div>
                </div>
              </>
            )}
          </Panel>
        </>
      )}

      {screen === 'associations' && (
        <Panel title="Associations" subtitle="">
          <div className="toolbar">
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search association name" />
            <select disabled value="">
              <option>Municipality filter not available yet</option>
            </select>
            <select disabled value="">
              <option>Barangay filter not available yet</option>
            </select>
            <div className="meta">{filteredAssociations.length} association(s)</div>
          </div>
          <div className="list">
            {filteredAssociations.map((association) => (
              <AssociationCard
                key={association.server_id}
                association={association}
                selected={association.server_id === selectedAssociation}
                onOpen={(serverId) => loadAssociationDetails(serverId).catch(() => {})}
              />
            ))}
            {filteredAssociations.length === 0 && <div className="empty">No associations matched the current search.</div>}
          </div>
        </Panel>
      )}

      {screen === 'members' && (
        <Panel title="Members" subtitle="">
          <div className="toolbar">
            <input value={memberSearch} onChange={(event) => setMemberSearch(event.target.value)} placeholder="Search member name or mobile number" />
            <select value={associationFilter} onChange={(event) => setAssociationFilter(event.target.value)}>
              <option value="">All associations</option>
              {associations.map((association) => (
                <option key={association.server_id} value={association.slpa_name}>
                  {association.slpa_name}
                </option>
              ))}
            </select>
            <div className="meta">{filteredMembers.length} member(s)</div>
          </div>
          <div className="list">
            {filteredMembers.map((member) => {
              const row = member.row_data || {};
              return (
                <div key={member.server_id} className="card">
                  <div className="rowtitle">{fullName(row) || 'Unnamed member'}</div>
                  <div className="sub">{member.slpa_name || 'Unnamed SLPA'}</div>
                  <div className="sub">Mobile: {row.mobile_number || '-'}</div>
                  <div className="sub">Last synced: {fmtDate(member.synced_at)}</div>
                </div>
              );
            })}
            {filteredMembers.length === 0 && <div className="empty">No members matched the current filters.</div>}
          </div>
        </Panel>
      )}

      {screen === 'activity' && (
        <Panel
          title="Activity Log"
          subtitle=""
          action={<button className="ghost" onClick={() => loadActivity().catch(() => {})}>Reload</button>}
        >
          <div className="toolbar">
            <select value={moduleFilter} onChange={(event) => setModuleFilter(event.target.value)}>
              <option value="">All modules</option>
              {moduleOptions.map((module) => (
                <option key={module} value={module}>
                  {module}
                </option>
              ))}
            </select>
            <select value={actionFilter} onChange={(event) => setActionFilter(event.target.value)}>
              <option value="">All actions</option>
              {actionOptions.map((action) => (
                <option key={action} value={action}>
                  {action}
                </option>
              ))}
            </select>
            <select
              value={activityAssociationFilter}
              onChange={(event) => setActivityAssociationFilter(event.target.value)}
            >
              <option value="">All associations</option>
              {activityAssociationOptions.map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
            <div className="meta">{filteredActivity.length} activity record(s)</div>
          </div>
          <div className="list">
            {filteredActivity.map((entry) => {
              const row = entry.row_data || {};
              return (
                <div key={entry.server_id} className="card">
                  <div className="rowtitle">{row.member_name || 'Unknown member'}</div>
                  <div className="sub">{row.slpa_name || '-'}</div>
                  <div className="tags">
                    <span className="tag">{row.module || '-'}</span>
                    <span className="tag">{row.action || '-'}</span>
                  </div>
                  <div className="sub">Logged {fmtDate(entry.synced_at)}</div>
                </div>
              );
            })}
            {filteredActivity.length === 0 && <div className="empty">No activity matched the current filters.</div>}
          </div>
        </Panel>
      )}

      {screen === 'sync' && (
        <Panel
          title="Sync Health"
          subtitle=""
          action={<button className="ghost" onClick={() => reloadAll().catch(() => {})}>Refresh</button>}
        >
          <div className="summary-banner">
            <div className="summary-item">
              <span className="summary-label">Synced Today</span>
              <strong>{associations.length - notSyncingAssociations.length}</strong>
            </div>
            <div className="summary-item">
              <span className="summary-label">Not Syncing</span>
              <strong>{notSyncingAssociations.length}</strong>
            </div>
            <div className="summary-item">
              <span className="summary-label">Latest Batch</span>
              <strong>
                {syncStatus.recent_batches[0]
                  ? fmtDate(syncStatus.recent_batches[0].received_at)
                  : 'No batch recorded'}
              </strong>
            </div>
            <div className="summary-item">
              <span className="summary-label">Tables Synced</span>
              <strong>{tableTotals.length}</strong>
            </div>
          </div>

          <div className="list">
            {simplifiedSyncStatus.map((association) => (
              <div key={association.server_id} className="card">
                <div className="rowtitle">{association.slpa_name}</div>
                <div className="tags">
                  <span className={`tag ${association.syncState === 'Up to date' ? 'tag-good' : 'tag-warning'}`}>
                    {association.syncState}
                  </span>
                  <span className="tag">Members {association.member_count || 0}</span>
                </div>
                <div className="sub">Last sync: {fmtDate(association.synced_at)}</div>
              </div>
            ))}
            {simplifiedSyncStatus.length === 0 && (
              <div className="empty">No association sync records are available yet.</div>
            )}
          </div>
        </Panel>
      )}
    </Shell>
  );
}
