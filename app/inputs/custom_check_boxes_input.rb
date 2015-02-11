class CustomCheckBoxesInput < Formtastic::Inputs::CheckBoxesInput
	def input_html_options
		super.merge(:class => "mycustomnclashere regular-checkbox")
	end

	def input_wrapping(&block)
		template.content_tag(:div,
							 [template.capture(&block), error_html, hint_html].join("\n").html_safe,
							 wrapper_html_options
							 )
	end

	def to_html
		input_wrapping do
			hidden_field_for_all <<
				legend_html <<
			choices_group_wrapping do
				collection.map { |choice|
					custom_choice_wrapping(choice_wrapping_html_options(choice)) do
						choice_html(choice)
					end
				}.join("\n").html_safe
			end
		end
	end

	def legend_html
		if render_label?
			template.content_tag(:label, label_text,:class => "label")
		else
			"".html_safe
		end
	end


	def custom_choice_wrapping(html_options, &block)
		template.content_tag(:li,
							 template.capture(&block),
							 html_options
							 )
	end

	def choice_html(choice)
		checkbox_input(choice) + custom_choice_label(choice) + template.content_tag(:span,choice.first)
	end

	def custom_choice_label(choice)
		if choice.is_a?(Array)
			template.content_tag(:label," ",
								 label_html_options.merge(:for => choice_input_dom_id(choice), :class => nil))

		else
			choice
		end.to_s
	end

	def hidden_field_for_all
		if hidden_fields?
			''
		else
			options = {}
			options[:class] = [method.to_s.singularize, 'default'].join('_') if value_as_class?
			options[:id] = [object_name, method, 'none'].join('_')
			template.hidden_field_tag(input_name, '', options)
		end
	end

	def hidden_fields?
		options[:hidden_fields]
	end

	def check_box_with_hidden_input(choice)
		value = choice_value(choice)
		builder.check_box(
			association_primary_key || method,
			extra_html_options(choice).merge(:id => choice_input_dom_id(choice), :name => input_name, :disabled => disabled?(value), :required => false),
			value,
			unchecked_value
		)
	end

	def check_box_without_hidden_input(choice)
		value = choice_value(choice)
		template.check_box_tag(
			input_name,
			value,
			checked?(value),
			extra_html_options(choice).merge(:id => choice_input_dom_id(choice), :disabled => disabled?(value), :required => false)
		)
	end

	def extra_html_options(choice)
		input_html_options.merge(custom_choice_html_options(choice))
	end

	def checked?(value)
		selected_values.include?(value)
	end

	def disabled?(value)
		disabled_values.include?(value)
	end

	def selected_values
		@selected_values ||= make_selected_values
	end

	def disabled_values
		vals = options[:disabled] || []
		vals = [vals] unless vals.is_a?(Array)
		vals
	end

	def unchecked_value
		options[:unchecked_value] || ''
	end

	def input_name
		if builder.options.key?(:index)
			"#{object_name}[#{builder.options[:index]}][#{association_primary_key || method}][]"
		else
			"#{object_name}[#{association_primary_key || method}][]"
		end
	end

	protected

	def checkbox_input(choice)
		if hidden_fields?
			check_box_with_hidden_input(choice)
		else
			check_box_without_hidden_input(choice)
		end
	end

	def make_selected_values
		if object.respond_to?(method)
			selected_items = object.send(method)

			# Construct an array from the return value, regardless of the return type
			selected_items = [*selected_items].compact.flatten

			[*selected_items.map { |o| send_or_call_or_object(value_method, o) }].compact
		else
			[]
		end
	end

end
