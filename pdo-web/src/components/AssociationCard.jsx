export default function AssociationCard({ association, selected, onOpen }) {
  return (
    <div className={`assoc ${selected ? 'selected' : ''}`}>
      <div>
        <div className="name">{association.slpa_name || 'Unnamed SLPA'}</div>
        <div className="sub">{association.server_id || '-'}</div>
        <div className="tags">
          <span className="tag">Members {association.member_count || 0}</span>
          <span className="tag">
            Synced {association.synced_at ? new Date(association.synced_at).toLocaleString() : '-'}
          </span>
        </div>
      </div>
      <button className="select-btn" onClick={() => onOpen(association.server_id)}>
        Open
      </button>
    </div>
  );
}
