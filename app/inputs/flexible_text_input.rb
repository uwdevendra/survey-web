class FlexibleTextInput < Formtastic::Inputs::StringInput
	def input_html_options
		super.merge(:class => "my-custom-class")
	end

	def to_html
		input_wrapping do
			label_html <<
				builder.text_area(method, input_html_options)
		end
	end

	def label_html
		render_label? ? builder.label(input_name, label_text, label_html_options) : "".html_safe
	end

	def label_html_options
		{
			:for => input_html_options[:id],
			:class => ['label'],
		}
	end

	def render_label?
		return false if options[:label] == false
		true
	end

	def input_wrapping(&block)
		template.content_tag(:div,
							 [template.capture(&block), error_html, hint_html].join("\n").html_safe,
							 wrapper_html_options
							 )
	end
end
