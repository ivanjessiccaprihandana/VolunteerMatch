namespace :admin do
  desc "Create or promote an admin account. Usage: bin/rails admin:create EMAIL=you@example.org PASSWORD=... NAME=..."
  task create: :environment do
    email = ENV.fetch("EMAIL") { abort "Set EMAIL=..." }
    password = ENV["PASSWORD"]

    user = User.find_or_initialize_by(email: email)
    user.name = ENV.fetch("NAME", user.name.presence || "Admin")
    user.role = :admin
    user.email_confirmed_at ||= Time.current

    if user.new_record?
      abort "Set PASSWORD=... (minimal 8 karakter) for a new admin" if password.blank?
      user.password = password
      user.password_confirmation = password
    elsif password.present?
      user.password = password
      user.password_confirmation = password
    end

    user.save!
    puts "Admin ready: #{user.email}"
  end
end
