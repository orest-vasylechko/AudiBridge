# AudiBridge iOS v0.1

Перший прототип одного iPhone-застосунку для старого Audi MMI 3G+ P1001.

## Що вже є

- SwiftUI застосунок для iPhone.
- Car Mode + Core Location background mode.
- Google Places API (New) Text Search.
- API key зберігається в iOS Keychain, а не в source code.
- Генерація того самого `PoiResults` XML, який уже був прийнятий тестовою MMI P1001.
- Локальний HTTP listener `:8080`:
  - `GET /health`
  - `GET /poi/search?...`
- Google POI preview прямо на iPhone.
- XML preview "Що отримає MMI".
- Черга myAudi destinations як каркас для наступного етапу.
- URL scheme `audibridge://car-mode` для Shortcuts.

## Критичне мережеве обмеження

Якщо MMI працює **тільки через штатну SIM**, а Wi-Fi MMI вимкнений, то MMI фізично не бачить локальну IP iPhone. Тому `LocalHTTPServer` у v0.1 потрібен для лабораторного/локального тесту.

Для реального сценарію потрібен наступний шар:

`MMI → штатна SIM → PUBLIC RELAY → iPhone app → Google Places → iPhone app → PUBLIC RELAY → MMI`

Public Relay буде наступним модулем. Це не змінює POI/XML/MyAudi логіку в застосунку.

## Як відкрити

1. На Mac встановити Xcode 16+.
2. Відкрити `AudiBridge.xcodeproj`.
3. Target `AudiBridge` → Signing & Capabilities → вибрати свій Team.
4. Переконатися, що `Background Modes` містить `Location updates` (Info.plist уже має `UIBackgroundModes=location`).
5. Підключити iPhone і Run.
6. У Settings застосунку вставити **новий** Google Places API key та натиснути `Зберегти ключ у Keychain`.

> Ключ, який був показаний на скріншоті в чаті, краще відкликати та створити новий.

## Shortcuts після першого запуску

Створити Personal Automation:

- Trigger: Bluetooth → конкретний Audi MMI.
- Action: Open URLs → `audibridge://car-mode` (або Open App → AudiBridge).
- Увімкнути автоматичний запуск без підтвердження, якщо iOS дозволяє для цієї automation.

## Про фон

Застосунок використовує background location тільки в Car Mode. Це дає iOS підставу продовжувати роботу під час поїздки після блокування екрана. Сам по собі довільний HTTP listener не є окремим background mode, тому реальну стабільність listener + location треба перевірити на фізичному iPhone. Для фінальної схеми з MMI-only-SIM все одно використовуватиметься outbound relay connection.

## Наступні кроки

1. Зібрати/запустити v0.1 на iPhone.
2. Перевірити Google Places і XML preview.
3. Перевірити Car Mode після lock screen.
4. Додати Public Relay transport зі стабільною адресою, яку один раз впишемо у `de.audi.poisearch.proxyHost.eu`.
5. Підключити myAudi `AudiConnectorWS` до вкладки Destinations.
