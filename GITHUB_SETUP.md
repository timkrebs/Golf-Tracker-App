# GitHub Repository Setup für Golf Tracker App

Diese Anleitung führt Sie durch die Einrichtung Ihres GitHub Repositories mit allen notwendigen Konfigurationen für CI/CD und sichere Entwicklung.

## 🔧 Vorbereitende Schritte (Bereits erledigt)

✅ `.gitignore` für iOS/Swift erstellt  
✅ Sensitive Daten aus dem Code entfernt  
✅ Environment-System mit `ConfigLoader` implementiert  
✅ GitHub Actions Workflow erstellt  
✅ SwiftLint Konfiguration hinzugefügt  

## 📋 Setup Checkliste

### 1. GitHub Repository erstellen

```bash
# Im Projekt-Verzeichnis
git init
git add .
git commit -m "Initial commit: Golf Tracker iOS App"
git branch -M main
git remote add origin https://github.com/IHR_USERNAME/GolfTracker.git
git push -u origin main
```

### 2. GitHub Secrets konfigurieren

Gehen Sie zu Ihrem Repository → Settings → Secrets and variables → Actions

Erstellen Sie folgende **Repository Secrets**:

| Secret Name | Beschreibung | Beispiel |
|-------------|-------------|----------|
| `SUPABASE_URL` | Ihre Supabase Projekt URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Ihr Supabase Anon Key | `eyJhbGciOiJIUzI1NiIs...` |
| `GOLF_API_BASE_URL` | Golf API Base URL (optional) | `https://your-api.com` |

⚠️ **Wichtig**: Verwenden Sie die echten Werte aus Ihrer ursprünglichen `SupabaseConfig.swift` Datei!

### 3. Lokale Entwicklung konfigurieren

1. **Config.plist erstellen:**
   ```bash
   cp GolfTracker/Config.plist.template GolfTracker/Config.plist
   ```

2. **Config.plist ausfüllen:**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>SUPABASE_URL</key>
   	<string>https://pqpgkolzkknolflmllad.supabase.co</string>
   	<key>SUPABASE_ANON_KEY</key>
   	<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxcGdrb2x6a2tub2xmbG1sbGFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxMjk1ODcsImV4cCI6MjA2NzcwNTU4N30.Vxd_hwww3JLTpEnnLH-MSH9hpe13NSzZuvJPlrx0LsY</string>
   	<key>GOLF_API_BASE_URL</key>
   	<string>https://golftracker-app-service.azurewebsites.net</string>
   	<key>ENVIRONMENT</key>
   	<string>development</string>
   </dict>
   </plist>
   ```

3. **Config.plist zu Xcode hinzufügen:**
   - Öffnen Sie das Projekt in Xcode
   - Rechtsklick auf "GolfTracker" Ordner → "Add Files to GolfTracker"
   - Wählen Sie `Config.plist` aus
   - Stellen Sie sicher, dass "Add to target: GolfTracker" ausgewählt ist

### 4. Branch Protection konfigurieren

Gehen Sie zu Repository → Settings → Branches → "Add rule"

**Konfiguration für `main` Branch:**
- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging
  - Wählen Sie: `test`, `build`, `lint`
- ✅ Require conversation resolution before merging
- ✅ Include administrators

## 🚀 CI/CD Pipeline

Die GitHub Actions Pipeline führt automatisch aus:

1. **Tests** (`test` job):
   - Unit Tests mit iOS Simulator
   - Test-Ergebnisse als Artifact

2. **Build** (`build` job):
   - Erstellt iOS Archive
   - Läuft nur nach erfolgreichen Tests

3. **Linting** (`lint` job):
   - SwiftLint Code-Qualitätsprüfung
   - Parallel zu Tests

### Pipeline Trigger

- **Push** zu `main` oder `develop` Branch
- **Pull Requests** zu `main` oder `develop` Branch

## 🧪 Testing Setup

### Unit Tests hinzufügen (falls noch nicht vorhanden)

1. In Xcode: File → New → Target → "Unit Testing Bundle"
2. Target Name: "GolfTrackerTests"
3. Erstellen Sie Test-Dateien in `GolfTrackerTests/` Ordner

### UI Tests hinzufügen (optional)

1. In Xcode: File → New → Target → "UI Testing Bundle"
2. Target Name: "GolfTrackerUITests"

### Testing locally: 
- Run Tests
```bash
xcodebuild test -project GolfTracker.xcodeproj -scheme GolfTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```
- Run UI Tests
```bash
   xcodebuild test -project GolfTracker.xcodeproj -scheme GolfTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:GolfTrackerUITests
```

## 📁 Empfohlene Ordnerstruktur

```
GolfTracker/
├── .github/
│   └── workflows/
│       └── ci.yml
├── GolfTracker/
│   ├── Config.plist          # (lokal, nicht im Git)
│   ├── Config.plist.template # (im Git)
│   ├── ConfigLoader.swift    # (neu)
│   ├── SupabaseConfig.swift  # (aktualisiert)
│   └── ... (bestehende Dateien)
├── GolfTrackerTests/         # (falls Tests hinzugefügt)
├── .gitignore               # (neu)
├── .swiftlint.yml           # (neu)
├── GITHUB_SETUP.md          # (diese Datei)
└── README.md                # (bestehend)
```

## 🔒 Sicherheit

### Was ist jetzt sicher?

✅ **API Keys** sind nicht mehr im Code  
✅ **Secrets** werden über GitHub Secrets verwaltet  
✅ **Environment-spezifische** Konfiguration möglich  
✅ **Lokale Config** ist in `.gitignore` ausgeschlossen  

### Was Sie beachten sollten:

⚠️ Teilen Sie niemals die echten Werte aus `Config.plist`  
⚠️ Commiten Sie niemals `Config.plist` ins Repository  
⚠️ Überprüfen Sie regelmäßig Ihre GitHub Secrets  

## 🔄 Entwicklungsworkflow

1. **Feature Branch erstellen:**
   ```bash
   git checkout -b feature/neue-funktion
   ```

2. **Entwickeln und testen lokal**

3. **Änderungen committen:**
   ```bash
   git add .
   git commit -m "feat: Neue Funktion hinzugefügt"
   git push origin feature/neue-funktion
   ```

4. **Pull Request erstellen:**
   - GitHub automatisch → Tests laufen
   - Code Review anfordern
   - Nach Approval → Merge

5. **Deployment:**
   - Merge zu `main` → Automatischer Build
   - Archive wird als Artifact gespeichert

## 🚨 Troubleshooting

### Build fails mit "Config.plist not found"
- Überprüfen Sie GitHub Secrets
- Stellen Sie sicher, dass alle erforderlichen Secrets gesetzt sind

### Tests schlagen fehl
- Prüfen Sie Supabase-Verbindung
- Validieren Sie Test-spezifische Konfiguration

### SwiftLint Fehler
- Lokaler Check: `swiftlint lint`
- Automatische Korrektur: `swiftlint autocorrect`

## 📞 Support

Bei Problemen:
1. Überprüfen Sie die GitHub Actions Logs
2. Validieren Sie Ihre Secrets-Konfiguration
3. Testen Sie lokale Builds vor dem Push

---

**🎉 Nach dieser Einrichtung haben Sie ein vollständig konfiguriertes Repository mit automatischen Tests, Builds und Sicherheitsfeatures!** 