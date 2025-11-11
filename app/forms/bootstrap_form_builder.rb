class BootstrapFormBuilder < ActionView::Helpers::FormBuilder
  # NOT CURRENTLY USED
  #
  # Generates a styled form field for each of the following field helpers:
  #   * text_field
  #   * text_area
  #   * email_field
  #   * number_field
  #   * password_field
  #   * search_field
  #   * telephone_field
  #   * url_field
  #
  # If the :styled option is set to true, the original field helper is called. Otherwise, the field is styled with Tailwind CSS.
  #
  # Returns a string containing the HTML for the label and the field
  #
  text_like_fields = field_helpers - [ :label, :check_box, :radio_button, :fields_for, :fields, :hidden_field, :file_field ]
  text_like_fields.each do |field_method|
    class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
      def #{field_method}(method, options = {})
        if options.delete(:styled)
          super
        else
          styled_text_field(#{field_method.inspect}, method, options)
        end
      end
    RUBY_EVAL
  end

  def styled_text_field(field_method, object_method, options = {})
    wrapper_classes = "form-control"
    wrapper_classes += " is-invalid" if errors_for(object_method).any?
    options[:class] = wrapped_class_list(wrapper_classes, provided_classes: options[:class])

    if errors_for(object_method).any?
      error_message = "<div class='invalid-feedback d-block' id='#{object_method}-error'>Please provide a valid #{object_method}.</div>".html_safe
      options.merge!({ aria: { describedby: "#{object_method}-error" } })
    else
      error_message = ""
    end

    label = options[:label] == false ? "" : styled_label(object_method, options)
    field = send(field_method, object_method, options.merge({ styled: true }))

    label + field + error_message
  end

  def styled_label(method, options = {}, field_specific_classes: nil)
    wrapper_classes = "form-label"
    wrapper_classes += " #{field_specific_classes}" if field_specific_classes.present?

    options[:label] ||= {}
    if options[:label].is_a?(String)
      label_text = { text: options[:label] }
      options[:label] = label_text
    end
    options[:label][:class] = wrapped_class_list(wrapper_classes, provided_classes: options[:label][:class])

    text = options[:label][:text] || method.to_s.humanize
    label(method, text, options.delete(:label))
  end

  def check_box(method, options = {})
    wrapper_classes = "form-check-input me-2"
    options[:class] = wrapped_class_list(wrapper_classes, provided_classes: options[:class])

    label = options[:label] == false ? "" : styled_label(method, options, field_specific_classes: "form-check-label")
    field = super

    field + label
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    style = "form-select"
    html_options[:class] ||= ""
    html_options[:class].prepend style + " "

    label = options[:label] == false ? "" : styled_label(method, options)
    field = super

    label + field
  end

  def submit(value = nil, options = {})
    wrapper_classes = "btn btn-primary"
    options[:class] = wrapped_class_list(wrapper_classes, provided_classes: options[:class])

    super
  end

  def errors_for(object_method)
    return unless @object.present? && object_method.present?

    @object.errors[object_method]
  end

  def wrapped_class_list(wrapper_classes, provided_classes:)
    [ wrapper_classes, provided_classes ].join(" ").strip
  end
end
