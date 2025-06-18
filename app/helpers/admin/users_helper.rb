module Admin::UsersHelper
  
  def filter_link(label, icon: nil, **params)
    icon_html = icon.present? ? content_tag(:i, "", class: "bi bi-#{icon} me-1") : ""
    link_to raw(icon_html + label), admin_users_path(params), class: "btn btn-outline-primary btn-sm"
  end

end
