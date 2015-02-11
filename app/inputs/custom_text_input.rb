class CustomTextInput < Formtastic::Inputs::TextInput
	def input_html_options
		super.merge(:class => "my-custom-class")
	end

	def input_wrapping(&block)
		template.content_tag(:div,
							 [template.capture(&block), error_html, hint_html].join("\n").html_safe,
							 wrapper_html_options
							 )
	end
end
