module Admin
  # Admins review organization accounts and verify the genuine ones.
  # Only verified organizations can publish events.
  class OrganizationsController < BaseController
    FILTERS = %w[pending verified all].freeze

    def index
      @filter = params[:filter].presence_in(FILTERS) || "pending"

      organizations = User.organization
                          .includes(:organization_profile)
                          .left_joins(:organization_profile)
                          .order(created_at: :desc)

      @organizations =
        case @filter
        when "pending" then organizations.where(organization_profiles: { verified: [false, nil] })
        when "verified" then organizations.where(organization_profiles: { verified: true })
        else organizations
        end
    end

    def update
      organization = User.organization.find(params[:id])
      profile = organization.organization_profile

      if profile.nil?
        redirect_to admin_organizations_path,
                    alert: "#{organization.name} belum melengkapi profil organisasi."
        return
      end

      verified = ActiveModel::Type::Boolean.new.cast(params[:verified])
      profile.update!(verified: verified)

      message = if verified
                  "#{profile.organization_name} telah diverifikasi."
                else
                  "Verifikasi #{profile.organization_name} dicabut."
                end
      redirect_to admin_organizations_path(filter: params[:filter].presence_in(FILTERS)), notice: message
    end
  end
end
