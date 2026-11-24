module ApplicationHelper
  # Translated label for an enum value, e.g. status_label(event) => "Dipublikasikan".
  def enum_label(record, attribute = :status)
    value = record.public_send(attribute)
    return "" if value.blank?

    I18n.t(
      "activerecord.enums.#{record.model_name.i18n_key}.#{attribute}.#{value}",
      default: value.to_s.humanize
    )
  end
  alias status_label enum_label

  def status_badge(record)
    tag.span(status_label(record), class: "badge badge--#{record.status}")
  end

  def status_options_for(model_class)
    model_class.statuses.keys.map do |status|
      [I18n.t("activerecord.enums.#{model_class.model_name.i18n_key}.status.#{status}"), status]
    end
  end

  def role_label(user)
    I18n.t("activerecord.enums.user.role.#{user.role}")
  end
end
