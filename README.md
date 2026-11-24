# VolunteerMatch

Aplikasi web Ruby on Rails yang mempertemukan relawan dengan organisasi
penyelenggara kegiatan sosial. Organisasi yang telah diverifikasi admin
mempublikasikan kegiatan, relawan mendaftar, dan kedua pihak diberi kabar
lewat email di setiap langkah.

> Mau belajar Ruby dan Rails dari proyek ini? Baca
> [docs/PANDUAN-BELAJAR.md](docs/PANDUAN-BELAJAR.md).

## Fitur

| Peran | Yang bisa dilakukan |
|---|---|
| Pengunjung | Melihat landing page, mencari dan memfilter kegiatan (kategori, lokasi, tanggal), membuka detail kegiatan |
| Relawan | Daftar akun dan konfirmasi email, mengisi profil, mendaftar kegiatan dengan motivasi, membatalkan lalu mendaftar ulang, memantau status di dashboard, menghapus akun |
| Organisasi | Membuat kegiatan sebagai draf, **mempublikasikannya setelah diverifikasi admin**, menerima atau menolak pendaftar, membatalkan kegiatan (relawan diberi tahu otomatis) |
| Admin | Meninjau organisasi baru, memberi atau mencabut verifikasi |

**Email otomatis:** konfirmasi akun, reset password, pendaftar baru (ke
organisasi), diterima atau ditolak (ke relawan), relawan membatalkan (ke
organisasi), dan kegiatan dibatalkan (ke relawan).

### Aturan bisnis

- Password 8 sampai 72 karakter. Email dinormalisasi ke huruf kecil dan harus unik.
- Login hanya bisa dilakukan setelah email dikonfirmasi.
- Kategori kegiatan berasal dari daftar tetap: Lingkungan, Pendidikan,
  Kesehatan, Sosial, Bencana, Hewan, Lainnya.
- Kegiatan baru harus dimulai di masa mendatang. Waktu selesai harus setelah
  waktu mulai, dan batas pendaftaran harus sebelum waktu mulai.
- Semua waktu dimasukkan dan ditampilkan dalam **WIB (Asia/Jakarta)** dan
  disimpan sebagai UTC.
- Kapasitas tidak bisa terlampaui, termasuk saat dua orang menekan "Terima"
  bersamaan (row lock di database), dan tidak bisa diturunkan di bawah jumlah
  relawan yang sudah diterima.
- Satu relawan hanya punya satu pendaftaran aktif per kegiatan. Setelah
  membatalkan, relawan boleh mendaftar lagi.
- Pendaftaran tidak bisa dibatalkan setelah kegiatan dimulai.
- Kegiatan yang sudah punya pendaftar tidak bisa dihapus, hanya dibatalkan.
- Email dan telepon relawan baru terlihat oleh organisasi setelah pendaftaran
  **diterima**.

## Teknologi

Ruby 3.3 · Rails 8.1 · PostgreSQL · Puma · Hotwire (Turbo/Stimulus) ·
Sprockets · Minitest · rails-i18n (Bahasa Indonesia) · Sentry (opsional) ·
Docker · GitHub Actions

## Menjalankan di komputer lokal (Windows)

Prasyarat: Ruby 3.3 (disarankan 3.3.14 atau lebih baru, karena 3.3.2 memiliki
celah keamanan), PostgreSQL, dan Git.

```powershell
# 1. Simpan password PostgreSQL sekali saja, lalu tutup dan buka ulang terminal/VS Code
[Environment]::SetEnvironmentVariable('VOLUNTEERMATCH_DATABASE_PASSWORD', '<password>', 'User')

# 2. Install gem dan siapkan database
bundle install
bin/rails db:prepare
bin/rails db:seed      # data demo: admin, organisasi, relawan, dan beberapa kegiatan

# 3. Jalankan server
bin/rails server
```

Buka http://localhost:3000. Akun demo (password `password123`):

| Peran | Email |
|---|---|
| Admin | admin@example.com |
| Organisasi (terverifikasi) | org@example.com |
| Organisasi (belum diverifikasi) | org-baru@example.com |
| Relawan | relawan@example.com |

Di development, email tidak benar-benar dikirim. Setiap email disimpan sebagai
file di `tmp/mails/<alamat-penerima>`. Buka file itu untuk mengambil tautan
konfirmasi atau reset password.

Variabel opsional untuk koneksi lokal: `VOLUNTEERMATCH_DATABASE_HOST`
(default `127.0.0.1`), `VOLUNTEERMATCH_DATABASE_PORT` (5432), dan
`VOLUNTEERMATCH_DATABASE_USERNAME` (postgres).

## Testing

```powershell
bin/rails test:all                      # unit, controller, mailer, dan system test
bundle exec brakeman --no-pager         # analisis keamanan kode
bundle exec bundler-audit check --update  # gem dengan celah keamanan yang diketahui
```

System test memakai driver `rack_test`, jadi tidak butuh Chrome. Ketiga
perintah di atas juga dijalankan otomatis oleh GitHub Actions
([.github/workflows/ci.yml](.github/workflows/ci.yml)) di setiap pull request,
ditambah build image Docker.

## Deploy ke production

Aplikasi dikemas sebagai image Docker dan bisa dijalankan di VPS, Render,
Railway, Fly.io, atau platform container lain.

### 1. Siapkan konfigurasi

```bash
cp .env.example .env
```

Isi `.env`. Penjelasan lengkap setiap variabel ada di
[.env.example](.env.example).

| Variabel | Wajib | Keterangan |
|---|---|---|
| `SECRET_KEY_BASE` | ya | Buat dengan `bin/rails secret` |
| `APP_HOST` | ya | Domain publik, misalnya `volunteermatch.org`. Dipakai untuk tautan email dan pemblokiran host lain |
| `DATABASE_URL` / `POSTGRES_PASSWORD` | ya | Koneksi PostgreSQL |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` | ya | Server SMTP (Brevo, Mailgun, SendGrid, SES, Gmail app password, dan sejenisnya) |
| `MAIL_FROM` | ya | Alamat pengirim email |
| `PRIVACY_CONTACT_EMAIL` | disarankan | Ditampilkan di halaman Kebijakan Privasi |
| `SENTRY_DSN` | opsional | Monitoring error. Data pribadi tidak dikirim ke Sentry |
| `WEB_CONCURRENCY`, `RAILS_MAX_THREADS` | opsional | Jumlah proses dan thread Puma |

### 2. Jalankan

Dengan docker-compose (aplikasi dan PostgreSQL sekaligus):

```bash
docker compose up -d --build
docker compose exec web bin/rails admin:create EMAIL=admin@domainanda.org PASSWORD='...' NAME="Admin"
```

Atau di platform yang menyediakan PostgreSQL terkelola: build dari
`Dockerfile` lalu set environment variable di atas. Migrasi database
dijalankan otomatis saat container start (`bin/docker-entrypoint`).

### 3. HTTPS

Aplikasi memaksa HTTPS (`force_ssl`, HSTS, dan cookie `secure`) dan
mengasumsikan ada proxy TLS di depannya, misalnya load balancer platform,
Caddy, NGINX, atau Cloudflare. Endpoint `/up` dipakai sebagai health check.

### Checklist sebelum launch

- [ ] `.env` terisi, `SECRET_KEY_BASE` unik, dan file `.env` tidak ikut di-commit
- [ ] Domain dan sertifikat TLS aktif, serta `APP_HOST` sesuai domain
- [ ] Email uji terkirim: daftar akun baru lalu cek email konfirmasinya
- [ ] Akun admin pertama sudah dibuat dengan `bin/rails admin:create`
- [ ] Backup database harian sudah berjalan (lihat bawah)
- [ ] `SENTRY_DSN` terisi agar error production terlihat
- [ ] Teks [Kebijakan Privasi](app/views/pages/privacy.html.erb) dan
      [Syarat Penggunaan](app/views/pages/terms.html.erb) sudah ditinjau
      oleh pihak yang memahami UU PDP

## Backup database

Gunakan backup otomatis dari penyedia database jika ada (Render, Railway, RDS,
dan sejenisnya). Untuk docker-compose di VPS, jadwalkan dump harian dengan cron:

```bash
# /etc/cron.d/volunteermatch-backup: setiap hari 02:00, simpan 14 hari
0 2 * * * root cd /srv/volunteermatch && docker compose exec -T db pg_dump -U volunteermatch -Fc volunteermatch_production > backups/vm-$(date +\%F).dump && find backups -name 'vm-*.dump' -mtime +14 -delete
```

Pulihkan dengan:

```bash
docker compose exec -T db pg_restore -U volunteermatch -d volunteermatch_production --clean < backups/vm-YYYY-MM-DD.dump
```

Simpan salinan backup di luar server (object storage) dan uji proses restore
secara berkala.

## Keamanan

- Password di-hash dengan bcrypt. Login memakai `authenticate_by` sehingga
  waktu responsnya sama, baik email terdaftar maupun tidak.
- Token konfirmasi email dan reset password ditandatangani dan kedaluwarsa
  sendiri (2 hari dan 30 menit). Token reset tidak berlaku lagi begitu
  password diganti.
- Rate limiting untuk login, registrasi, reset password, dan kirim ulang
  konfirmasi.
- Form lupa password dan kirim ulang konfirmasi selalu memberi jawaban yang
  sama, sehingga tidak bisa dipakai untuk mengecek apakah sebuah email terdaftar.
- Session di-reset saat login. CSRF aktif.
- Content Security Policy ketat dengan nonce. HTTPS dan HSTS dipaksa di production.
- Email dan nomor telepon disaring dari log.
- Otorisasi: organisasi hanya bisa mengelola kegiatan miliknya, dan role
  admin tidak bisa dipilih saat registrasi.

## Struktur singkat

```
app/controllers/
  admin/organizations_controller.rb  verifikasi organisasi
  volunteer_events_controller.rb     CRUD kegiatan, pencarian, pagination
  event_registrations_controller.rb  daftar, terima, tolak, batal
  sessions / users / password_resets / email_confirmations / accounts
app/models/
  user.rb                 akun, role, token email dan password
  volunteer_event.rb      aturan kegiatan, notifikasi pembatalan
  event_registration.rb   aturan pendaftaran, lock kapasitas, notifikasi
app/mailers/              UserMailer, RegistrationMailer
config/locales/id.yml     label dan pesan validasi Bahasa Indonesia
lib/tasks/admin.rake      bin/rails admin:create
```

## Keterbatasan yang diketahui

- Email dikirim lewat Active Job adapter `:async` (di dalam proses web). Ini
  cukup untuk skala kecil, tetapi email yang masih antre akan hilang jika
  server restart. Untuk skala lebih besar, pindahkan ke Solid Queue atau
  Sidekiq.
- Rate limit disimpan di file cache lokal, sehingga hanya berlaku per server.
  Jika menjalankan lebih dari satu server, gunakan Redis atau Solid Cache.
- Belum ada fitur moderasi kegiatan atau laporan penyalahgunaan dari pengguna.
