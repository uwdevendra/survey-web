class CustomBooleanInput < Formtastic::Inputs::BooleanInput

	def to_html
		input_wrapping do
			hidden_field_html <<
				label_with_nested_checkbox
		end
	end

	def input_wrapping(&block)
		template.content_tag(:div,
							 [template.capture(&block), error_html, hint_html].join("\n").html_safe,
							 wrapper_html_options
							 )
	end
end
