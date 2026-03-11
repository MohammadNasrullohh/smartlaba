import 'legal_document_page.dart';

const String termsDocumentTitle = 'Syarat & Ketentuan';
const String termsDocumentSubtitle =
    'Aturan dasar penggunaan akun dan layanan SmartLaba.';
const String privacyDocumentTitle = 'Kebijakan Privasi';
const String privacyDocumentSubtitle =
    'Ringkasan penggunaan data akun dan operasional toko.';

const List<LegalDocumentSection> termsDocumentSections = [
  LegalDocumentSection(
    title: '1. Persetujuan Penggunaan',
    paragraphs: [
      'Dengan membuat akun atau memakai SmartLaba, Anda menyetujui bahwa aplikasi ini dipakai untuk membantu operasional toko, pencatatan transaksi, dan pengelolaan akun owner maupun kasir.',
    ],
  ),
  LegalDocumentSection(
    title: '2. Tanggung Jawab Akun',
    paragraphs: [
      'Owner bertanggung jawab menjaga keamanan email, kata sandi, serta akses kasir yang dibuat di dalam akun tokonya. Aktivitas dari akun yang sah menjadi tanggung jawab pemegang akses tersebut.',
    ],
  ),
  LegalDocumentSection(
    title: '3. Penggunaan yang Dilarang',
    paragraphs: [
      'Pengguna tidak diperbolehkan memakai SmartLaba untuk penipuan, manipulasi data, akses tanpa izin, atau tindakan yang melanggar hukum dan merugikan pihak lain.',
    ],
  ),
  LegalDocumentSection(
    title: '4. Pengelolaan Data dan Layanan',
    paragraphs: [
      'SmartLaba dapat menyimpan data akun, toko, produk, dan transaksi untuk menjalankan fitur aplikasi. Kami dapat melakukan pembaruan sistem untuk menjaga keamanan dan stabilitas layanan.',
    ],
  ),
];

const List<LegalDocumentSection> privacyDocumentSections = [
  LegalDocumentSection(
    title: '1. Data yang Dikumpulkan',
    paragraphs: [
      'Kami dapat menyimpan nama, email, role akun, data toko, data produk, data transaksi, dan informasi profil lain yang Anda isi di dalam aplikasi.',
    ],
  ),
  LegalDocumentSection(
    title: '2. Tujuan Penggunaan Data',
    paragraphs: [
      'Data digunakan untuk autentikasi akun, sinkronisasi antar perangkat, pengelolaan owner dan kasir, serta penyajian fitur SmartLaba secara aman dan konsisten.',
    ],
  ),
  LegalDocumentSection(
    title: '3. Keamanan dan Penyimpanan',
    paragraphs: [
      'Kami berupaya menjaga data menggunakan layanan autentikasi dan database yang terintegrasi. Pengguna tetap perlu menjaga kerahasiaan akun dan perangkat yang digunakan.',
    ],
  ),
  LegalDocumentSection(
    title: '4. Hak Pengguna',
    paragraphs: [
      'Anda dapat memperbarui data akun, menonaktifkan akses kasir, atau berhenti memakai layanan. Pertanyaan terkait data dapat disampaikan melalui kanal dukungan internal yang tersedia.',
    ],
  ),
];
