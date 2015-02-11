class SurveyApp.LanguageSelection
 constructor: (@container) ->
  # console.log @container
  @lang_selection_popup = @container.find("#lang")
  # console.log @lang_selection_popup
  @current_lang = @container.find("#current_lang")
  @current_lang.click(@lang_selection_toggle)
  # console.log @current_lang
  @close_btn = @container.find(".close_btn")
  @overlay = @container.next(".overlay")
  @close_btn.click(@hide_lang_selection)
 
 lang_selection_toggle: =>
  # console.log "HELLO"
  @lang_selection_popup.fadeToggle 500
  @overlay.fadeToggle 500
  # if @lang_selection_popup.attr('display') == 'block'
  # @hide_lang_selection
  # else 
  # @show_lang_selection
  
 show_lang_selection: =>
  # @lang_selection_popup.show()
  @lang_selection_popup.fadeIn 500
  @overlay.fadeIn 500

 hide_lang_selection: =>
  # @lang_selection_popup.hide()
  @lang_selection_popup.fadeOut 500
  @overlay.fadeOut 500
  