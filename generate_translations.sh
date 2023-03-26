rm lib/l10n/app_it.arb
rm lib/l10n/app_pt.arb

cp lib/l10n/forced_translations/* lib/l10n

flutter pub run auto_translator