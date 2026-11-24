# Demo data for local development: bin/rails db:seed
#
# Production never gets demo data. Create the first admin there with:
#   bin/rails admin:create EMAIL=admin@example.org PASSWORD=... NAME="Admin"

if Rails.env.production?
  puts "Skipping demo seeds in production. Use bin/rails admin:create instead."
  return
end

PASSWORD = "password123".freeze

def seed_user(email:, name:, role:)
  User.find_or_create_by!(email: email) do |user|
    user.name = name
    user.role = role
    user.password = PASSWORD
    user.password_confirmation = PASSWORD
    user.email_confirmed_at = Time.current
  end
end

admin = seed_user(email: "admin@example.com", name: "Admin VolunteerMatch", role: :admin)

verified_org = seed_user(email: "org@example.com", name: "Rina Pengelola", role: :organization)
verified_org.organization_profile || verified_org.create_organization_profile!(
  organization_name: "Yayasan Hijau Nusantara",
  city: "Bandung",
  phone: "022-1234567",
  website: "https://example.org",
  description: "Komunitas pelestarian lingkungan di Jawa Barat.",
  verified: true
)

pending_org = seed_user(email: "org-baru@example.com", name: "Budi Pengurus", role: :organization)
pending_org.organization_profile || pending_org.create_organization_profile!(
  organization_name: "Komunitas Baca Ceria",
  city: "Jakarta",
  description: "Taman baca untuk anak-anak di Jakarta Utara."
)

volunteer = seed_user(email: "relawan@example.com", name: "Sari Relawan", role: :volunteer)
volunteer.volunteer_profile || volunteer.create_volunteer_profile!(
  city: "Bandung",
  phone: "081234567890",
  skills: "Fotografi, mengajar",
  availability: "Akhir pekan"
)

events = [
  { title: "Bersih Sungai Cikapundung", category: "Lingkungan", location: "Bandung", days: 10, capacity: 25 },
  { title: "Tanam 1000 Pohon", category: "Lingkungan", location: "Lembang", days: 17, capacity: 60 },
  { title: "Kelas Membaca Anak", category: "Pendidikan", location: "Bandung", days: 7, capacity: 8 },
  { title: "Donor Darah Bersama", category: "Kesehatan", location: "Cimahi", days: 21, capacity: 40 }
]

events.each do |attrs|
  starts_at = attrs[:days].days.from_now.change(hour: 8)
  verified_org.volunteer_events.find_or_create_by!(title: attrs[:title]) do |event|
    event.description = "#{attrs[:title]} bersama #{verified_org.organization_profile.organization_name}. Terbuka untuk umum."
    event.category = attrs[:category]
    event.location = attrs[:location]
    event.starts_at = starts_at
    event.ends_at = starts_at + 4.hours
    event.registration_deadline = starts_at - 2.days
    event.capacity = attrs[:capacity]
    event.status = :published
  end
end

first_event = verified_org.volunteer_events.order(:starts_at).first
first_event.event_registrations.find_or_create_by!(volunteer: volunteer) do |registration|
  registration.motivation = "Saya ingin membantu menjaga lingkungan kota saya."
end

puts "Seeded. Log in with any of these (password: #{PASSWORD}):"
[admin, verified_org, pending_org, volunteer].each { |user| puts "  #{user.role.ljust(12)} #{user.email}" }
