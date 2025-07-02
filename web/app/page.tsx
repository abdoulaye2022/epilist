// app/page.tsx - VERSION SIMPLE SANS TAILWIND
export default function HomePage() {
  return (
    <div className="container">
      <div className="card">
        <div className="logo">📱</div>

        <h1 className="title">EpiList</h1>

        <p className="subtitle">
          Créez et partagez vos listes de courses facilement avec vos proches
        </p>

        <a
          href="https://play.google.com/store/apps/details?id=com.m2atech.epilist"
          className="btn"
          target="_blank"
          rel="noopener noreferrer"
        >
          📲 Télécharger sur Play Store
        </a>

        <a
          href="https://apps.apple.com/app/epilist/id123456789"
          className="btn btn-blue"
          target="_blank"
          rel="noopener noreferrer"
        >
          🍎 Télécharger sur App Store
        </a>

        <div className="features">
          <div className="feature">
            <div className="feature-icon">✓</div>
            <div>Créez vos listes de courses rapidement</div>
          </div>

          <div className="feature">
            <div className="feature-icon">✓</div>
            <div>Partagez avec famille et amis</div>
          </div>

          <div className="feature">
            <div className="feature-icon">✓</div>
            <div>Synchronisation en temps réel</div>
          </div>

          <div className="feature">
            <div className="feature-icon">✓</div>
            <div>Interface simple et intuitive</div>
          </div>
        </div>
      </div>
    </div>
  );
}
