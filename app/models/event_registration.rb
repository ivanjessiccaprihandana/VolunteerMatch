class EventRegistration < ApplicationRecord
  belongs_to :volunteer,
             class_name: "User",
             inverse_of: :event_registrations
  belongs_to :volunteer_event

  enum status: {
    pending: 0,
    accepted: 1,
    rejected: 2,
    cancelled: 3
  }

  validates :motivation, presence: true, length: { maximum: 1_000 }
  validates :status, presence: true
  validates :volunteer_id,
            uniqueness: {
              scope: :volunteer_event_id,
              message: "sudah terdaftar pada kegiatan ini"
            }

  validate :volunteer_account_required
  validate :event_must_accept_registrations, on: :create
  validate :capacity_must_be_available, if: :being_accepted?

  private

  def volunteer_account_required
    return if volunteer.nil? || volunteer.volunteer?

    errors.add(:volunteer, "harus menggunakan akun relawan")
  end

  def event_must_accept_registrations
    return if volunteer_event.nil? || volunteer_event.registration_open?

    errors.add(:volunteer_event, "tidak menerima pendaftaran")
  end

  def capacity_must_be_available
    accepted_count = volunteer_event.event_registrations
                                    .accepted
                                    .where.not(id: id)
                                    .count
    return if accepted_count < volunteer_event.capacity

    errors.add(:status, "tidak dapat diterima karena kapasitas sudah penuh")
  end

  def being_accepted?
    accepted? && will_save_change_to_status?
  end
end
