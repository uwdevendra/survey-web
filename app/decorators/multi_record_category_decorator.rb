class MultiRecordCategoryDecorator < CategoryDecorator
  decorates :multi_record_category
  delegate_all

  def create_record_link(response_id)
    h.link_to I18n.t('responses.edit.create_record'),
              h.records_path(:record => { :category_id => model.id, :response_id => response_id  }),
              :method => :post, :class => "create_record Btn colrBtn"
  end

  def category_name(record_id, response_id, cache, disabled)
    # TODO: Refactor
    # Don't show the multi-record title once per record. Only once total.
    unless cache.map { |model_id, record_id| model_id }.include?(model.id)
      cache << [model.id, record_id]

      string = ERB.new "
        <%= model.category.decorate.category_name(nil, response_id, cache, disabled) if model.category %>
        <div class='clear'></div>
        <div class='category  <%= 'hidden sub_question' if model.sub_question? %>'
             data-nesting-level='<%= model.nesting_level %>'
             data-parent-id='<%= model.parent_id %>'
             data-id='<%= model.id %>'
             data-category-id='<%= model.category_id %>'>
          <label class='label'>
            <%= question_number %>)
            <%= model.content %>
            
          </label>
          <%= model.decorate.create_record_link(response_id) unless disabled %>
        </div>
      "
      string.result(binding).force_encoding('utf-8').html_safe
    end
  end
end
