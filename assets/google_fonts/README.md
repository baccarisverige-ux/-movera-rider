# Bundled fonts (UI-15)

Put these Poppins files here (fonts.google.com, SIL Open Font License; keep
`OFL.txt` next to them):

Poppins-Light.ttf, Poppins-Regular.ttf, Poppins-Medium.ttf,
Poppins-SemiBold.ttf, Poppins-Bold.ttf, Poppins-ExtraBold.ttf,
Poppins-Black.ttf

google_fonts loads them from the bundle. When all seven are present,
`configureBundledFonts` (lib/app/bundled_fonts.dart) turns runtime fetching
off, so the app never downloads fonts. Until then it keeps downloading them.
