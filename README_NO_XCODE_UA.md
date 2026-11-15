# AudiBridge — збірка IPA без роботи в Xcode

## Варіант A — GitHub Actions (рекомендовано)

1. Створи порожній GitHub repository, наприклад `AudiBridge`.
2. Завантаж **вміст цієї папки** в корінь repository. У корені мають бути `AudiBridge.xcodeproj`, `AudiBridge/` та `.github/`.
3. В GitHub відкрий **Actions** → **Build unsigned AudiBridge IPA** → **Run workflow**.
4. Після завершення відкрий job і внизу в **Artifacts** скачай `AudiBridge-unsigned-ipa`.
5. Усередині буде `AudiBridge-unsigned.ipa`.
6. Встанови IPA на iPhone через Sideloadly або AltStore. Вони перепідпишуть unsigned IPA твоїм Apple ID.

Для безкоштовного Apple ID sideload-підпис зазвичай має обмежений строк і застосунок треба періодично перепідписувати. Це вже обмеження Apple, не AudiBridge.

## Варіант B — Mac командою, без відкривання Xcode

Потрібен встановлений Xcode toolchain. Запусти `build_unsigned_ipa.command`. Після збірки поруч з'явиться `AudiBridge-unsigned.ipa`.

## Що вже є у v0.2

- Google Places API (New) → Audi POI XML.
- Локальний `/poi/search` на порту 8080.
- Car Mode + background location.
- API key у Keychain.
- Preview Google POI та Audi XML.
- Каркас myAudi Destinations.
- Deployment target знижено до iOS 15.0, щоб не вимагати iOS 17.

## Важливо про MMI зі штатною SIM

Локальний HTTP server на iPhone сам по собі не доступний MMI через Internet. Для фінального варіанта ще потрібен транспорт/relay між публічним endpoint MMI та iPhone. Сам POI engine уже відокремлений від цього транспортного шару.
