module ApplicationHelper
  def crewbase_credit_badge(variant: :blue, compact: false)
    classes = [ "crewbase-credit-badge", "crewbase-credit-badge-#{variant}" ]
    options = { class: classes.join(" ") }
    options[:aria] = { label: "Verified Crewbase Credit" } if compact

    content_tag(:span, **options) do
      image_tag("crewbase-credit-badge-#{variant}.svg", alt: "", aria: { hidden: true }) +
        (compact ? "" : "Crewbase Credit")
    end
  end

  include Pagy::Frontend

  def remote_modal(title = nil, &block)
    turbo_frame_tag("remote_modal") do
      render("application/remote_modal", title: title, &block)
    end
  end

  def bootstrap_pagy_nav(pagy)
    return if pagy.pages <= 1

    content_tag(:nav, aria: { label: "Jobs pagination" }) do
      content_tag(:ul, class: "pagination mb-0") do
        safe_join([
          bootstrap_pagy_prev_link(pagy),
          safe_join(pagy.series.map { |item| bootstrap_pagy_page_item(pagy, item) }),
          bootstrap_pagy_next_link(pagy)
        ])
      end
    end
  end

  def job_application_status_badge_class(status)
    case status.to_s
    when "accepted" then "status-badge status-completed"
    when "rejected", "withdrawn" then "status-badge status-unavailable"
    when "in_review", "shortlisted" then "status-badge status-warning"
    else "status-badge status-unknown"
    end
  end

  def project_status_badge_class(status)
    case status.to_s
    when "active" then "status-badge status-open"
    when "completed" then "status-badge status-completed"
    else "status-badge status-draft"
    end
  end

  def job_status_badge_class(status)
    case status.to_s
    when "published" then "status-badge status-open"
    when "filled", "completed" then "status-badge status-completed"
    when "archived", "closed" then "status-badge status-unavailable"
    else "status-badge status-draft"
    end
  end

  private

  def bootstrap_pagy_prev_link(pagy)
    classes = [ "page-item" ]
    classes << "disabled" unless pagy.prev

    content_tag(:li, class: classes.join(" ")) do
      if pagy.prev
        link_to("Previous", pagy_url_for(pagy, pagy.prev), class: "page-link")
      else
        content_tag(:span, "Previous", class: "page-link")
      end
    end
  end

  def bootstrap_pagy_next_link(pagy)
    classes = [ "page-item" ]
    classes << "disabled" unless pagy.next

    content_tag(:li, class: classes.join(" ")) do
      if pagy.next
        link_to("Next", pagy_url_for(pagy, pagy.next), class: "page-link")
      else
        content_tag(:span, "Next", class: "page-link")
      end
    end
  end

  def bootstrap_pagy_page_item(pagy, item)
    case item
    when Integer
      content_tag(:li, class: "page-item") do
        link_to(item, pagy_url_for(pagy, item), class: "page-link")
      end
    when String
      content_tag(:li, class: "page-item active", aria: { current: "page" }) do
        content_tag(:span, item, class: "page-link")
      end
    else
      content_tag(:li, class: "page-item disabled") do
        content_tag(:span, item.to_s, class: "page-link")
      end
    end
  end
end
