SurveyBuilder.Views.Dummies ||= {}

# Represents a dummy question on the DOM
class SurveyBuilder.Views.Dummies.QuestionView extends Backbone.View
  ORDER_NUMBER_STEP: 2

  events:
    'keyup  input[type=text]': 'handle_textbox_keyup'
    'change input[type=number]': 'handle_textbox_keyup'
    'change input[type=checkbox]': 'handle_checkbox_change'
    

  initialize: (@model, @template, @survey_frozen) =>
    @model.dummy_view = this
    @can_have_sub_questions = false
    @model.on('change', @render, this)
    @model.on('change:errors', @render, this)
    # 
    @model.actual_view = this
    @model.on('save:completed', @renderImageUploader, this)
    @model.on('change', @render, this)
    @model.on('change:id', @render, this)

  render: =>
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
    console.dir data
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
      alert "DELETE"
      @delete(e)
    $(@el).children('.dummy_question_content').children(".top_level_content").children(".copy_question").click (e) => @save_all_changes(e)
    @limit_edit() if @survey_frozen
    ##################################
    @renderImageUploader()
    ##################################
    return this

  ######################################################

  allow_identifier: =>
    !(this.model.get('parent_id') || this.model.get('has_multi_record_ancestor'))

  handle_textbox_keyup: (event) =>
    console.log event
    this.model.off('change', this.render)
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.val()
    this.model.on('change', this.render)
    @update_model(propertyHash)
    event.stopImmediatePropagation()


  handle_checkbox_change: (event) =>
    alert "and this is one is mine"
    console.log event
    # this.model.off('change', this.render)
    input = $(event.target)
    propertyHash = {}
    propertyHash[input.attr('name')] = input.is(':checked')
    @update_model(propertyHash)
    event.stopImmediatePropagation()

  update_model: (propertyHash) =>
    console.log propertyHash
    @model.set(propertyHash)

  renderImageUploader: =>
    console.log "renderImageUploader"
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

  hide : =>
    console.log "CALLING HIDE"
    $(this.el).hide()


  show: =>
    $(this.el).show()
    first_input = $($(this.el).find('input:text'))[0]
    $(first_input).select()

  limit_edit: =>
    $(this.el).find("input[name=mandatory]").parent('div').hide()
    if @model.get("finalized")
      $(this.el).find("input[name=max_length]").parent('div').hide()
      $(this.el).find("input[name=max_value]").parent('div').hide()
      $(this.el).find("input[name=min_value]").parent('div').hide()

  ######################################################

  delete: =>
    @model.destroy()

  show_actual: (event) =>
    # $(@el).trigger("dummy_click")
    # @model.actual_view.show()
    # todo : add show hide toggle here
    # $(@el).children('.dummy_question_content').children(".top_level_content").children(".settings-view").hide()
    
    $(@el).children('.dummy_question_content').addClass("active")

  unfocus: =>
    $(@el).children('.dummy_question_content').removeClass("active")

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

  limit_edit: =>
    if @model.get("finalized")
      $(this.el).find(".copy_question").remove()
      $(this.el).find(".delete_question").remove()