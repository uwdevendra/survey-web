##= require ./question_view
SurveyBuilder.Views.Dummies ||= {}

# Represents a dummy radio question on the DOM
class SurveyBuilder.Views.Dummies.QuestionWithOptionsView extends Backbone.View 
  # extends SurveyBuilder.Views.Dummies.QuestionView

  ########################################################
  events:
    'keyup  .sub_question_group input[type=text]': 'handle_textbox_keyup'
    'change .sub_question_group input[type=checkbox]': 'handle_checkbox_change'
    
    'keyup  input[type=text]': 'handle_textbox_keyup_deep'
    'change input[type=checkbox]': 'handle_checkbox_change_deep'
    'click button.add_option': 'add_new_option_model' # This one for adding new option
    'click button.add_options_in_bulk': 'add_options_in_bulk' # This one for adding new options in bulk
  ########################################################

  initialize: (@model, @template, @survey_frozen) =>
    # super
    # console.log @model
    @model.dummy_view = this
    @can_have_sub_questions = false
    @model.on('change', @render, this)
    @model.on('change:errors', @render, this)
    # 
    @model.actual_view = this
    @model.on('save:completed', @renderImageUploader, this)
    # @model.on('change', @render, this)
    @model.on('change:id', @render, this)
    @options = []
    # @can_have_sub_questions = true
    @model.get('options').on('destroy', @delete_option_view, this)
    @model.on('add:options', @add_new_option, this)
    @model.on('preload_options', @preload_options, this)
    ############################################
    @model.on('change', @render, this)
    ############################################

  render: =>
    # super
    $(@el).html('<div class="dummy_question_content"><div class="top_level_content"></div></div>') if $(@el).is(':empty')
    @model.set('content', I18n.t('js.untitled_question')) if _.isEmpty(@model.get('content'))
    # json = _.extend(@model.toJSON())
    # console.dir json
    data = _.extend(@model.toJSON().question, {errors: @model.errors, image_url: @model.get('image_url')})
    data = _(data).extend({question_number: @model.question_number})
    data = _(data).extend({duplicate_url: @model.duplicate_url()})
    data = _(data).extend({image_upload_url: @model.image_upload_url()})
    

    ####################################################
    data.question = _.extend(@model.toJSON().question)
    data.allow_identifier = @allow_identifier()
    # console.log "DATA =>"
    # console.dir data
    # $(this.el).html(Mustache.render(this.template, json))
    
    ####################################################


    $(@el).children('.dummy_question_content').children(".top_level_content").html(Mustache.render(@template, data))
    $(@el).addClass("dummy_question")
    $(@el).find('abbr').show() if @model.get('mandatory')
    $(@el).find('.star').raty({
      readOnly: true,
      number: @model.get('max_length') || 5
    })

    $(@el).children(".dummy_question_content").click (e) =>
      @show_actual(e)

    $(@el).children('.dummy_question_content').children(".top_level_content").children(".delete_question").click (e) => 
      alert "DELTE ME"
      @delete(e)

    $(@el).children('.dummy_question_content').children(".top_level_content").children(".copy_question").click (e) => @save_all_changes(e)
    @limit_edit() if @survey_frozen
    ##################################
    @renderImageUploader()
    ##################################
    $(@el).children(".dummy_question_content:not(:has(div.children_content))").append('<div class="children_content"></div>')
    # $(@el).children(".dummy_question_content").click (e) =>
    #   @show_actual(e)

    # $(@el).children('.dummy_question_content').children(".delete_question").click (e) => @delete(e)

    $(@el).children(".sub_question_group").html('')
    console.dir @options
    # return this
    _(@options).each (option) =>
      console.log "OPTION HERE " 
      console.dir option
      group = $("<div class='sub_question_group'>")
      group.sortable({
        items: "> div",
        update: ((event, ui) =>
          window.loading_overlay.show_overlay("Reordering Questions")
          _.delay(=>
            @reorder_questions(event,ui)
          , 10)
        )
      })
      group.append("<p class='sub_question_group_message'> #{I18n.t('js.questions_for')} #{option.model.get('content')}</p>")
      _(option.sub_questions).each (sub_question) =>
        console.log " sub_question"
        console.log sub_question.render().el
        group.append(sub_question.render().el)
      $(@el).append(group) unless _(option.sub_questions).isEmpty()

    @render_dropdown()
    @limit_edit() if @survey_frozen
    return this


  allow_identifier: =>
    !(this.model.get('parent_id') || this.model.get('has_multi_record_ancestor'))

  handle_textbox_keyup: (event) =>
    alert "HERE HERE BUDDY"
    this.model.off('change', this.render)
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.val()
    this.model.on('change', this.render)
    @update_model(propertyHash)
    event.stopImmediatePropagation();

  handle_checkbox_change: (event) =>
    alert "HERE HERE BUDDY AGAIN"
    console.log event.target.closest(".dummy_question")
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.is(':checked')
    @update_model(propertyHash)
    event.stopImmediatePropagation();

  handle_textbox_keyup_deep: (event) =>
    # console.log event
    this.model.off('change', this.render)
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.val()
    this.model.on('change', this.render)
    @update_model(propertyHash)
    event.stopImmediatePropagation();


  handle_checkbox_change_deep: (event) =>
    alert "I am handling this one"
    # console.log event
    # this.model.off('change', this.render)
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.is(':checked')
    @update_model(propertyHash)
    event.stopImmediatePropagation();

  update_model: (propertyHash) =>
    # console.log propertyHash
    @model.set(propertyHash)

  renderImageUploader: =>
    # console.log "renderImageUploader"
    loading_overlay = new SurveyBuilder.Views.LoadingOverlayView
    # console.dir $(this.el).children(".upload_files").children(".fileupload").fileupload 
    $(this.el).children('.dummy_question_content').children(".top_level_content").children(".upload_files").children(".fileupload").fileupload
      dataType: "json"
      url: @model.image_upload_url()
      submit: =>
        loading_overlay.show_overlay(I18n.t("js.uploading_image"))
      done: (e, data) =>
        this.model.set('image', { thumb: { url: data.result.image_url }})
        loading_overlay.hide_overlay()
        @renderImageUploader()

  hide: =>
    # console.log "CALLING HIDE"
    $(this.el).hide()


  show: =>
    $(this.el).show()
    first_input = $($(this.el).find('input:text'))[0]
    $(first_input).select()


  preload_options: (collection) =>
    collection.each( (model) =>
      @add_new_option(model)
    )

  render_dropdown: () =>
    if @model.has_drop_down_options()
      option_value = @model.get_first_option_value()
      $(@el).find('option').text(option_value)



  add_new_option: (model, options={}) =>
    window.loading_overlay.show_overlay()
    $(this.el).bind('ajaxStop.new_question', =>
      window.loading_overlay.hide_overlay()
      $(this.el).unbind('ajaxStop.new_question')
      )

    switch @model.get('type')
      when 'RadioQuestion'
        template = $('#dummy_radio_option_template').html()
      when 'MultiChoiceQuestion'
        template = $('#dummy_multi_choice_option_template').html()
      when 'DropDownQuestion'
        template = $('#dummy_drop_down_option_template').html()

    # console.log "TEMPLATE " +  template

    view = new SurveyBuilder.Views.Dummies.OptionView(model, template, @survey_frozen)
    @options.push view
    view.on('render_preloaded_sub_questions', @render, this)
    view.on('render_added_sub_question', @render, this)
    view.on('destroy:sub_question', @reorder_questions, this)
    $(@el).children('.dummy_question_content').children('.children_content').append(view.render().el)

    ########################################################
    # option = new SurveyBuilder.Views.Questions.OptionView(model, template, @survey_frozen)
    # @options.push option
    # $(view).append($(option.render().el))
    # console.log option.el
    ########################################################
    
    @render_dropdown()

  ##############################################################
  
  confirm_if_frozen: =>
    if @survey_frozen
      confirm(I18n.t("js.confirm_add_option_to_finalized_survey"))
    else
      true

  limit_edit: =>
    # super
    $(this.el).find("input[name=mandatory]").parent('div').hide()
    if @model.get("finalized")
      $(this.el).find("input[name=max_length]").parent('div').hide()
      $(this.el).find("input[name=max_value]").parent('div').hide()
      $(this.el).find("input[name=min_value]").parent('div').hide()
    # if @model.get("finalized")
      $(this.el).find("div.add_options_in_bulk").hide()
      $(this.el).find("textarea.add_options_in_bulk").hide()
      $(this.el).find(".add_option").attr("disabled", false)
    # if @model.get("finalized")
      $(this.el).find(".copy_question").remove()
      $(this.el).find(".delete_question").remove()
  ##############################################################

  delete: =>
    @model.destroy()

  show_actual: (event) =>
    # $(@el).trigger("dummy_click")
    # @model.actual_view.show()
    # todo : add show hide toggle here
    # $(@el).children('.dummy_question_content').children(".top_level_content").children(".settings-view").hide()
    
    $(@el).children('.dummy_question_content').addClass("active")

  # unfocus: =>
  #   $(@el).children('.dummy_question_content').removeClass("active")

  set_order_number: (last_order_number) =>
    index = $(@el).index() + 1
    @model.set({order_number: last_order_number + (index * @ORDER_NUMBER_STEP)})
    index

  reset_question_number: =>
    index = $(@el).index()
    @model.question_number = index + 1

  save_all_changes: =>
    $(@el).trigger("copy_question.save_all_changes", this)

  copy_question: =>
    $(@el).children('.dummy_question_content').children(".top_level_content").children(".copy_question_hidden").click()

  add_options_in_bulk: =>
    csv = $(this.el).children('textarea.add_options_in_bulk').val()
    return if csv == ""
    try
      parsed_csv = $.csv.toArray(csv)
    catch error
      alert I18n.t("js.require_csv_format")
      return

    window.loading_overlay.show_overlay("Adding your options. Please wait.")
    _.delay(=>
      @model.destroy_options()
      for content in parsed_csv
        @add_new_option_model(content.trim()) if content && content.trim().length > 0
      window.loading_overlay.hide_overlay()
    , 10)

  add_new_option_model: (content) =>
    this.model.create_new_option(content) if @confirm_if_frozen()

  delete_option_view: (model) =>
    option = _(@options).find((option) => option.model == model )
    @options = _(@options).without(option)
    @render()

  unfocus: =>
    # super
    $(@el).children('.dummy_question_content').removeClass("active")

    _(@options).each (option) =>
      _(option.sub_questions).each (sub_question) =>
        sub_question.unfocus()

  reorder_questions: (event, ui) =>
    for option_view in @options
      break if option_view.has_no_sub_questions()
      option_view.set_sub_question_order_numbers()
      @sort_sub_question_views_by_order_number(option_view)

    @reset_sub_question_numbers()
    @hide_overlay(event)

  sort_sub_question_views_by_order_number: (option_view) =>
    option_view.sub_questions = _(option_view.sub_questions).sortBy (sub_question) =>
      sub_question.model.get('order_number')

  hide_overlay: (event) =>
    window.loading_overlay.hide_overlay() if event

  reset_sub_question_numbers: =>
    for option in @options
      for sub_question in option.sub_questions
        index = $(sub_question.el).index()
        parent_question_number = option.model.get('question').question_number
        sub_question.model.question_number = '' + parent_question_number + @parent_option_character(option) + '.' + index

        sub_question.reset_sub_question_numbers() if sub_question.can_have_sub_questions
    @render()

  parent_is_multichoice: (option) =>
    option.model.get('question').get('type') == "MultiChoiceQuestion"

  parent_option_character: (option) =>
    return '' unless @parent_is_multichoice(option)
    first_order_number = option.model.get('question').first_order_number()
    parent_option_number = option.model.get('order_number') - first_order_number
    String.fromCharCode(65 + parent_option_number)