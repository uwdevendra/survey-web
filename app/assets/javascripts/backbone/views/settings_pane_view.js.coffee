class SurveyBuilder.Views.SettingsPaneView extends Backbone.View
  el: "#settings_pane"
  DETAILS: "#survey_details_template"

  initialize: (survey_model, @survey_frozen) =>
    @questions = []
    @add_survey_details(survey_model)

  add_element: (type, model) =>
    view = SurveyBuilder.Views.QuestionFactory.settings_view_for(type, model, @survey_frozen)
    @questions.push(view)
    model.on('destroy', this.delete_question_view, this)
    $(this.el).append($(view.render().el))
    $(view.render().el).hide()
    $("#dummy_questions").append(view.el)
    view

  add_survey_details: (survey_model) =>
    template = $(@DETAILS).html()
    question = new SurveyBuilder.Views.Questions.SurveyDetailsView({ model: survey_model, template: template })
    @questions.push(question)
    $(this.el).append($(question.render().el))
    $(question.render().el).hide()

  render: =>
    $(this.el).append($(question.render().el)) for question in @questions
    return this

  delete_question_view: (model) =>
    question = _(@questions).find((question) => question.model == model )
    @questions = _(@questions).without(question)
    question.remove()
    $(this.el).trigger("show_survey_details")

  hide_all: =>
    question.hide() for question in @questions


