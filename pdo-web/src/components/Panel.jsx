export default function Panel({ title, subtitle, action, children }) {
  return (
    <section className="panel">
      <div className="head">
        <div>
          <h3>{title}</h3>
          <p>{subtitle}</p>
        </div>
        {action}
      </div>
      <div className="body">{children}</div>
    </section>
  );
}
