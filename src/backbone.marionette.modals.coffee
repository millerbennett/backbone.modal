((root, factory) ->
  if typeof define is "function" and define.amd
    define [
      "exports"
      "underscore"
      "backbone"
      "backbone.marionette"
    ], factory
  else if typeof exports is "object"
    factory(exports, require("underscore"), require("backbone"), require("backbone.marionette"))
  else
    root.Backbone.Marionette.Modals = factory((root.commonJsStrict = {}), root._, root.Backbone, root.Backbone.Marionette)
) this, (exports, _, Backbone, Marionette) ->
  class Modals extends Marionette.Region
    modals: []
    zIndex: 0

    show: (view, options = {}) ->
      @_ensureElement()

      if @modals.length > 0
        lastModal = _.last(@modals)
        lastModal.modalEl.addClass("#{lastModal.prefix}-view--stacked")
        secondLastModal = @modals[@modals.length-1]
        secondLastModal?.modalEl.removeClass("#{secondLastModal.prefix}-modal--stacked-reverse")

      view.render()
      view.regionEnabled = true

      @triggerMethod('before:swap', view)
      @triggerMethod('before:show', view)
      Marionette.triggerMethodOn(view, 'before:show')
      @triggerMethod('swapOut', @currentView)

      @$el.append view.el
      @currentView = view

      @triggerMethod('swap', view)
      @triggerMethod('show', view)
      Marionette.triggerMethodOn(view, 'show')

      modalView.$el.css(background: 'none') for modalView in @modals if @modals.length > 0
      modalView.undelegateModalEvents() for modalView in @modals

      view.on('modal:destroy', @destroy)
      @modals.push(view)
      @zIndex++

    destroy: =>
      view = @currentView
      return unless view

      if view.destroy and !view.isDestroyed
        view.destroy()
      else if view.remove
        view.remove()

      view.off('modal:destroy', @destroy)

      @modals.splice(_.indexOf(@modals, view), 1)

      @zIndex--

      @currentView  = @modals[@zIndex-1]
      lastModal     = _.last(@modals)

      if lastModal
        lastModal.$el.removeAttr('style')
        lastModal.modalEl.addClass("#{lastModal.prefix}-modal--stacked-reverse")
        _.delay =>
          lastModal.modalEl.removeClass("#{lastModal.prefix}-modal--stacked")
        , 300

        lastModal.delegateModalEvents() if @zIndex isnt 0

    destroyAll: ->
      @destroy() for view in @modals
