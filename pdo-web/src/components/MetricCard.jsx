export default function MetricCard({ label, value, note }) {
  return (
    <div className="metric">
      <b>{label}</b>
      <strong>{value}</strong>
      <span>{note}</span>
    </div>
  );
}
