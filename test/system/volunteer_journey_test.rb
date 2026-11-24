require "application_system_test_case"

# Full journey through the real pages: an organization publishes an event,
# a volunteer signs up, confirms their email, registers, and gets accepted.
class VolunteerJourneyTest < ApplicationSystemTestCase
  test "organization publishes and volunteer gets accepted" do
    organization = create_user(name: "Yayasan Pantai", email: "pantai@example.com", role: :organization)

    # Organization creates an event through the form.
    log_in(organization.email)
    visit new_volunteer_event_path
    start = 14.days.from_now.change(hour: 8, min: 0)
    fill_in "Nama kegiatan", with: "Bersih Pantai Ancol"
    fill_in "Deskripsi", with: "Memungut sampah di sepanjang pantai."
    select "Lingkungan", from: "Kategori"
    fill_in "Lokasi", with: "Jakarta Utara"
    fill_in "Waktu mulai", with: start.strftime("%Y-%m-%dT%H:%M")
    fill_in "Waktu selesai", with: (start + 4.hours).strftime("%Y-%m-%dT%H:%M")
    fill_in "Batas pendaftaran", with: (start - 2.days).strftime("%Y-%m-%dT%H:%M")
    fill_in "Kapasitas relawan", with: "10"
    select "Dipublikasikan", from: "Status publikasi"
    click_button "Buat kegiatan"
    assert_text "Kegiatan berhasil dibuat."
    click_on "Keluar"

    # Volunteer signs up and must confirm their email first.
    visit new_user_path
    fill_in "Nama lengkap", with: "Sari Relawan"
    fill_in "Email", with: "sari@example.com"
    fill_in "Password", with: "password123"
    fill_in "Konfirmasi password", with: "password123"
    click_on "Buat akun"
    assert_text "tautan konfirmasi"

    log_in("sari@example.com")
    assert_text "belum dikonfirmasi"

    volunteer = User.find_by!(email: "sari@example.com")
    visit email_confirmation_path(token: volunteer.generate_token_for(:email_confirmation))
    assert_text "Email berhasil dikonfirmasi"

    # Volunteer finds the event and registers.
    log_in("sari@example.com")
    visit volunteer_events_path
    fill_in "Cari kegiatan", with: "pantai"
    click_on "Terapkan filter"
    click_on "Bersih Pantai Ancol"
    fill_in "Alasan ingin mengikuti kegiatan", with: "Saya ingin pantai bersih."
    click_on "Daftar sebagai relawan"
    assert_text "Pendaftaran berhasil dikirim."
    assert_text "Menunggu"
    click_on "Keluar"

    # Organization accepts; the volunteer's contact details become visible.
    log_in(organization.email)
    visit volunteer_event_path(VolunteerEvent.find_by!(title: "Bersih Pantai Ancol"))
    assert_no_text "sari@example.com"
    click_on "Terima"
    assert_text "Pendaftar berhasil diterima."
    assert_text "sari@example.com"
  end

  private

  def log_in(email)
    visit login_path
    fill_in "Email", with: email
    fill_in "Password", with: TestDataHelpers::PASSWORD
    click_button "Masuk"
  end
end
