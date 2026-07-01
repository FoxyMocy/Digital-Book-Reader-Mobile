import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  bool get _id => locale.languageCode == 'id';

  String get appTitle => 'Digital Book Reader';
  String get library => _id ? 'Perpustakaan' : 'Library';
  String get sources => _id ? 'Sumber' : 'Sources';
  String get settings => _id ? 'Pengaturan' : 'Settings';
  String get readingSettings => _id ? 'Pengaturan Baca' : 'Reading Settings';
  String get language => _id ? 'Bahasa' : 'Language';
  String get english => _id ? 'Inggris' : 'English';
  String get indonesian => _id ? 'Indonesia' : 'Indonesian';
  String get theme => _id ? 'Tema' : 'Theme';
  String get totalBooks => _id ? 'Total buku' : 'Total books';
  String get lastRead => _id ? 'Terakhir dibaca' : 'Last read';
  String get previousBookHint => _id ? 'Buku yang terakhir kamu buka' : 'Book you opened last';
  String get continueReading => _id ? 'Lanjut Baca' : 'Continue Reading';
  String get noBookInFilter => _id ? 'Tidak ada buku pada filter ini.' : 'No books in this filter.';
  String get addFiles => 'Add Files';
  String get addFolder => 'Add Folder';
  String get scan => _id ? 'Pindai' : 'Scan';
  String get noSources => _id ? 'Belum ada sumber' : 'No sources configured';
  String get noSourcesHelp => _id ? 'Gunakan Add Files di Android, atau Add Folder di desktop.' : 'Use Add Files on Android, or Add Folder on desktop.';
  String get booksInLibrary => _id ? 'buku di perpustakaan' : 'books in library';
  String booksFromFolder(int count) => _id ? '$count buku dari folder ini' : '$count books from this folder';
  String get removeSourceTitle => _id ? 'Hapus folder sumber?' : 'Remove source folder?';
  String removeSourceMessage(int count) {
    final base = _id
        ? 'Buku dari folder ini akan dihapus dari daftar perpustakaan lokal. File asli di perangkat tidak dihapus. Progress baca tetap tersimpan dan tetap dipakai lagi jika kamu menambahkan ulang file yang sama.'
        : 'Books from this folder will be removed from the local library list. Original files on the device are not deleted. Reading progress stays saved and is reused if you add the same file again.';
    if (count <= 0) return base;
    return _id ? '$base\n\nJumlah buku terkait: $count' : '$base\n\nRelated books: $count';
  }
  String get cancel => _id ? 'Batal' : 'Cancel';
  String get remove => _id ? 'Hapus' : 'Remove';
  String get sourceRemoved => _id ? 'Folder sumber dihapus dari library.' : 'Source folder removed from library.';
  String get folderPermissionMessage => _id
      ? 'Folder scan butuh All files access. Pakai Add Files jika tidak ingin memberi izin ini.'
      : 'Folder scan needs All files access. Use Add Files if you do not want to grant this permission.';
  String fontSize(double value) => _id ? 'Ukuran font: ${value.toStringAsFixed(0)}' : 'Font size: ${value.toStringAsFixed(0)}';
  String lineHeight(double value) => _id ? 'Tinggi baris: ${value.toStringAsFixed(1)}' : 'Line height: ${value.toStringAsFixed(1)}';
  String page(int page) => _id ? 'Halaman $page' : 'Page $page';
  String get listMode => _id ? 'Mode list' : 'List mode';
  String get gridMode => _id ? 'Mode grid' : 'Grid mode';
}
