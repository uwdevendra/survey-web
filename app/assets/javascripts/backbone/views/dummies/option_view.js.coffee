# Represents a dummy option in the DOM
SurveyBuilder.Views.Dummies ||= {}

class SurveyBuilder.Views.Dummies.OptionView extends Backbone.View
  ORDER_NUMBER_STEP: 2

  initialize: (@model, @template, @survey_frozen) =>
    @sub_questions = []
    @model.on('change', @render, this)
    @model.on('change:errors', @render, this)
    @model.on('add:sub_question', @add_sub_question, this)
    @model.on('change:preload_sub_questions', @preload_sub_questions, this)
    @model.on('destroy', @remove, this)
    # @model.on('destroy', @custom_method, this)
    ################################################################
    # @sub_questions = []
    # @model.on('change:errors', @render, this)
    # @model.on('change:id', @render, this)
    # @model.on('add:sub_question', @add_sub_question, this)
    # @model.on('change:preload_sub_questions', @preload_sub_questions)
    # @model.on('destroy', @remove, this)

    ################################################################


  render: =>
    # console.log "HELLO"
    data = _.extend(@model.toJSON().option, {errors: @model.errors})
    # $(@el).html(Mustache.render(@template, data))
    ######################################################
    data = _.extend(data, { finalized: @model.get('finalized') })
    $(@el).html(Mustache.render(@template, data))
    $(@el).addClass('option')
    $(@el).children('div').children('.add_sub_question').bind('click', @add_sub_question_model)
    $(@el).children('div').children('.add_sub_category').bind('click', @add_sub_category_model)
    $(@el).children('div').children('.add_sub_multi_record').bind('click', @add_sub_category_model)
    $(@el).children('div').children('.delete_option').bind('click', @delete)
    $(@el).children('input').bind('keyup', @update_model)
    @limit_edit() if @survey_frozen
    ######################################################
    return this

  ########################################################## 
  update_model: (event) =>
    input = $(event.target)
    @model.set({content: input.val()})
    event.stopImmediatePropagation()

  delete: =>
    @model.destroy()

  add_sub_question_model: (event) =>
    type = $(event.target).prev().val()
    @model.add_sub_question(type)

  add_sub_category_model: (event) =>
    type = $(event.target).data('type')
    @model.add_sub_question(type)

  # add_sub_question: (sub_question_model) =>
  #   window.loading_overlay.show_overlay()
  #   $(@el).bind('ajaxStop.new_question', =>
  #     window.loading_overlay.hide_overlay()
  #     $(@el).unbind('ajaxStop.new_question')
  #     )
  #   sub_question_model.on('destroy', @delete_sub_question, this)
  #   type = sub_question_model.get('type')
  #   question = SurveyBuilder.Views.QuestionFactory.settings_view_for(type, sub_question_model, @survey_frozen)
  #   @sub_questions.push question
  #   $('#settings_pane').append($(question.render().el))
  #   $(question.render().el).hide()

  # preload_sub_questions: (collection) =>
  #   _.each(collection, (question) =>
  #     @add_sub_question(question)
  #   )

  # delete_sub_question: (sub_question_model) =>
  #   view = sub_question_model.actual_view
  #   @sub_questions = _(@sub_questions).without(view)
  #   view.remove()

  limit_edit: =>
    if @model.get("finalized")
      $(@el).find(".delete_option").hide()

  ###########################################################

  add_sub_question: (sub_question_model) =>
    window.loading_overlay.show_overlay()
    $(@el).bind('ajaxStop.new_question', =>
      window.loading_overlay.hide_overlay()
      $(@el).unbind('ajaxStop.new_question')
    )
    console.log "I AM HERE"
    sub_question_model.on('destroy', @delete_sub_question, this)
    type = sub_question_model.get('type')
    question = SurveyBuilder.Views.QuestionFactory.dummy_view_for(type, sub_question_model, @survey_frozen)
    @sub_questions.push question
    
    @render()

    #################################################
    
    # sub_question_model.on('destroy', @delete_sub_question, this)
    # type = sub_question_model.get('type')
    # question_settings = SurveyBuilder.Views.QuestionFactory.settings_view_for(type, sub_question_model, @survey_frozen)
    # @sub_questions.push question_settings
    # $('#settings_pane').append($(question.render().el))
    # $(question.render().el).hide()
    @trigger('render_added_sub_question')

    # $(question).append(question_settings.render().el)
    ###################################################
    

  preload_sub_questions: (sub_question_models) =>
    _.each(sub_question_models, (sub_question_model) =>
      @add_sub_question(sub_question_model)
    )
    @trigger('render_preloaded_sub_questions')

  delete_sub_question: (sub_question_model) =>
    view = sub_question_model.dummy_view
    @sub_questions = _(@sub_questions).without(view)
    view.remove()
    @trigger('destroy:sub_question')

  last_sub_question_order_number: =>
    _.chain(@sub_questions)
      .map((sub_question) => sub_question.model.get('order_number'))
      .max().value()

  set_sub_question_order_numbers: =>
    last_order_number = @last_sub_question_order_number()
    for sub_question in @sub_questions
      index = sub_question.set_order_number(last_order_number)
      @model.sub_question_order_counter = last_order_number + (index * @ORDER_NUMBER_STEP)

  has_no_sub_questions: =>
    @sub_questions.length == 0

  custom_method: =>
    console.log "custom_method"
    view.remove()