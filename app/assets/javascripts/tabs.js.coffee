#class UserOwner.Tabs
  #constructor:(@container) ->
    #console.log "hello"  
    #@Tabs = @container.find('.blue_tabs ul.tab-links li a')      
    #@Tabcontainer = @container.find('.tabContainer')

    #@Tab01 = @container.find('#tabLink01')    
    #@Tabcontainer01 = @container.find('#tab01')

    #@Tab02 = @container.find('#tabLink02')    
    #@Tabcontainer02 = @container.find('#tab02')

    #@Tab03 = @container.find('#tabLink03')    
    #@Tabcontainer03 = @container.find('#tab03')

    #@Tab04 = @container.find('#tabLink04')    
    #@Tabcontainer04 = @container.find('#tab04')

    #@Tab05 = @container.find('#tabLink05')    
    #@Tabcontainer05 = @container.find('#tab05')

    #@Tab06 = @container.find('#tabLink06')    
    #@Tabcontainer06 = @container.find('#tab06')


    #@Tabcontainer.hide() 
    #@Tabcontainer01.show()
    #@Tab01.addClass('active')

    #@Tab01.click(@show01)
    #@Tab02.click(@show02)
    #@Tab03.click(@show03)
    #@Tab04.click(@show04)
    #@Tab05.click(@show05)
    #@Tab06.click(@show06)

    
  #show01: =>
    #console.log "tab01"  
    #@Tabs.removeClass('active')
    #@Tab01.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer01.show()


  #show02: =>
    #console.log "tab02"  
    #@Tabs.removeClass('active')
    #@Tab02.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer02.show()


  #show03: =>
    #console.log "tab03"  
    #@Tabs.removeClass('active')
    #@Tab03.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer03.show()


  #show04: =>
    #@Tabs.removeClass('active')
    #@Tab04.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer04.show()


  #show05: =>
    #@Tabs.removeClass('active')
    #@Tab05.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer05.show() 


  #show06: =>
    #@Tabs.removeClass('active')
    #@Tab06.addClass('active')
    #@Tabcontainer.hide()
    #@Tabcontainer06.show()                    
   