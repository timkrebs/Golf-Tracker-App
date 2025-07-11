# GitHub Secrets Template

Diese Datei enthält alle erforderlichen Secrets und Environment Variables für das Golf Tracker Projekt.

## 🔐 Erforderliche GitHub Repository Secrets

Gehen Sie zu: **Repository → Settings → Secrets and variables → Actions**

### Supabase Konfiguration

| Secret Name | Beschreibung | Aktueller Wert (aus SupabaseConfig.swift) |
|-------------|--------------|-------------------------------------------|
| `SUPABASE_URL` | Supabase Projekt URL | `https://pqpgkolzkknolflmllad.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase Anonymous Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxcGdrb2x6a2tub2xmbG1sbGFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxMjk1ODcsImV4cCI6MjA2NzcwNTU4N30.Vxd_hwww3JLTpEnnLH-MSH9hpe13NSzZuvJPlrx0LsY` |

### API Konfiguration (Optional)

| Secret Name | Beschreibung | Standardwert |
|-------------|--------------|--------------|
| `GOLF_API_BASE_URL` | Golf Course API Base URL | `https://golftracker-app-service.azurewebsites.net` |

## 📋 GitHub Secrets Setup Anweisungen

### Schritt 1: Repository Settings öffnen
1. Gehen Sie zu Ihrem GitHub Repository
2. Klicken Sie auf **Settings** (Tab oben)
3. Im linken Menü: **Secrets and variables** → **Actions**

### Schritt 2: Secrets hinzufügen
Für jedes Secret:

1. Klicken Sie **"New repository secret"**
2. **Name**: Verwenden Sie den exakten Namen aus der Tabelle oben
3. **Secret**: Kopieren Sie den entsprechenden Wert
4. Klicken Sie **"Add secret"**

### Schritt 3: Secrets validieren
Nach dem Hinzufügen sollten Sie folgende Secrets sehen:
- ✅ `SUPABASE_URL`
- ✅ `SUPABASE_ANON_KEY`
- ✅ `GOLF_API_BASE_URL` (optional)

## 🏠 Lokale Development Config

Erstellen Sie eine `Config.plist` Datei im `GolfTracker/` Ordner:

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

⚠️ **WICHTIG**: Diese Datei ist bereits in `.gitignore` und wird NICHT ins Repository committed!

## 🔄 Environment-spezifische Konfiguration

### Development (Lokal)
- Config wird aus `Config.plist` geladen
- Environment: `development`

### Testing (GitHub Actions)
- Config wird aus GitHub Secrets geladen
- Environment: `testing`

### Production (Build)
- Config wird aus GitHub Secrets geladen
- Environment: `production`

## ⚠️ Sicherheitshinweise

### Supabase Keys
- **Anon Key**: Ist öffentlich sichtbar (im Client), kann sicher in GitHub Secrets gespeichert werden
- **Service Role Key**: Falls verwendet, NIEMALS committen oder öffentlich teilen!

### Best Practices
1. 🔒 Niemals Secrets direkt im Code
2. 🔄 Regelmäßige Rotation von API Keys
3. 👥 Minimale Berechtigungen für Service Keys
4. 📝 Dokumentation aller verwendeten Secrets

## 🧪 Testing der Konfiguration

### Lokal testen
1. Erstellen Sie `Config.plist` mit obigen Werten
2. Fügen Sie die Datei zu Xcode hinzu
3. Starten Sie die App → Sollte normal funktionieren

### GitHub Actions testen
1. Setzen Sie alle Secrets in GitHub
2. Erstellen Sie einen Test-Commit/PR
3. Überprüfen Sie die Actions Logs für Konfigurationsfehler

## 📞 Troubleshooting

### "Config.plist not found" Error
- Überprüfen Sie, ob die Datei in Xcode hinzugefügt wurde
- Stellen Sie sicher, dass sie zum richtigen Target gehört

### GitHub Actions Fehler
- Validieren Sie alle Secret Namen (case-sensitive!)
- Überprüfen Sie die Secrets-Syntax in der YAML-Datei

### Supabase Connection Fehler
- Testen Sie die URLs/Keys manuell in einem API-Client
- Überprüfen Sie Supabase Dashboard für Projekteinstellungen

---

**🔐 Diese Konfiguration stellt sicher, dass alle sensiblen Daten sicher verwaltet werden und sowohl lokale Entwicklung als auch CI/CD funktionieren!** 