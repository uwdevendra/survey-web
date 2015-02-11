class SurveyApp.UserOptions
	constructor: (@container) ->
		@user_options = @container.find(".profilePopUp")
		@container.click(@user_options_toggle)
	#	@overlay = @container.prev(".overlay_for_dropdown")
	#	@overlay.click(@hide_options)
		# $(window).click(@user_options.fadeOut 1000)

	user_options_toggle: =>
		# console.log "hello0"
		@user_options.fadeToggle 300
	#	@overlay.fadeToggle 300

	hide_options: =>
		@user_options.fadeOut 300
	#	@overlay.hide()