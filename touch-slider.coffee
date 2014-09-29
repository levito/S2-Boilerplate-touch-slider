($win, $doc) ->
  class StageSlider
    constructor: (el) ->
      @$sliderContainer = $(el)
      @$sliderContent = @$sliderContainer.find(">ul")
      @$slides = @$sliderContent.find(">li")
      @slidesCount = @$slides.length
      @transition = Modernizr.prefixed("transition")
      @transitioning = false

      # defaults
      @speed = 400
      @flickTimeout = 400
      @swipeTreshold = 10

      # events
      @transitionend = {
        "WebkitTransition" : "webkitTransitionEnd"
        "MozTransition"    : "transitionend"
        "OTransition"      : "oTransitionEnd"
        "msTransition"     : "MSTransitionEnd"
        "transition"       : "transitionend"
        "false"            : "transitionend"
      }[@transition]

      # states
      # @sliderWidth
      # @currentIndex
      # @startX
      # @startY
      # @deltaX
      # @deltaY
      # @isFlick
      # @swiping

      @createButtons()
      @bindEvents()

    createButtons: ->
      $nav = $("<div class='nav'/>")
      $pager = $("<span/>").appendTo($nav)
      @currentIndex = (@$slides.filter(".current").index() + 1 || 1) - 1
      @$sliderContent.width(100 * @slidesCount + "%")
      @$slides.width(100 / @slidesCount + "%")
      @arrange(@$slides.eq(@currentIndex))
      @$slides.each (i) =>
        $("<button>" + (i+1) + "</button>").on("click touchend", (e) =>
          e.preventDefault()
          @go(i)
        ).appendTo($pager)
      $("<button class='back'>&lt;</button>").on("click touchend", (e) =>
        e.preventDefault()
        @back()
      ).prependTo($nav)
      $("<button class='forth'>&gt;</button>").on("click touchend", (e) =>
        e.preventDefault()
        @forth()
      ).appendTo($nav)
      @$pages = $pager.find(">button")
      @$pages.eq(@currentIndex).addClass("active")
      @moveBy(0, true)
      @$sliderContainer.append($nav).addClass("ready")

    bindEvents: ->
      @$sliderContent.on "touchstart", @touchstart
      $win.on "resize orientationchange", =>
        @sliderWidth = @$sliderContainer.width()
      .trigger("resize")

    isSwipe: (treshold) ->
      Math.abs(@deltaX) > Math.max(treshold, Math.abs(@deltaY));

    touchstart: (e) =>
      return false if @transitioning
      # e.preventDefault() # for testing on desktop
      @deltaX = @deltaY = 0
      if e.originalEvent.touches.length == 1
        @startX = e.originalEvent.touches[0].pageX
        @startY = e.originalEvent.touches[0].pageY
        @$sliderContent.on("touchmove", @touchmove).one("touchend", @touchend)
        @isFlick = true
        window.setTimeout( =>
          @isFlick = false
        , @flickTimeout)

    touchmove: (e) =>
      @deltaX = @startX - e.originalEvent.touches[0].pageX
      @deltaY = @startY - e.originalEvent.touches[0].pageY
      if @isSwipe(@swipeTreshold)
        e.preventDefault()
        e.stopPropagation()
        @swiping = true
      if @swiping
        @moveBy(@deltaX / @sliderWidth, true)

    touchend: (e) =>
      treshold = if @isFlick then @swipeTreshold else @sliderWidth / 2
      if @isSwipe(treshold)
        if @deltaX < 0 then @back() else @forth()
      else
        @moveBy(0, !@deltaX)
      @swiping = false
      @$sliderContent.off("touchmove", @touchmove).one(@transitionend, => @moveBy(0, true))

    moveBy: (direction, instantly) ->
      deltaX = -(direction + @currentIndex) * 100
      speed = if instantly then 0 else @speed
      if !!@transition
        @$sliderContent.css({
          # transform: "translate3d(" + deltaX / @slidesCount + "%,0,0)"
          left: deltaX + "%"
          transition: ["all ", speed, "ms"].join("")
        })
      else
        @$sliderContent.animate({
          left: deltaX + "%"
        }, speed, =>
          speed? && @$sliderContent.trigger(@transitionend)
        )

    go: (targetIndex, direction) ->
      return if typeof targetIndex != "number" || targetIndex == @currentIndex || @transitioning
      @transitioning = true
      targetIndex = targetIndex % @slidesCount
      $target = @$slides.eq(targetIndex)
      $current = @$slides.filter(".current")
      @currentIndex = $current.index()
      if !direction then $target.addClass("target")
      direction = direction || targetIndex - @currentIndex
      @moveBy(direction)
      if $target.attr("data-img")
        $target.append($("<img/>").attr("src", $target.attr("data-img"))).removeAttr("data-img")
      @$sliderContent.one(@transitionend, =>
        @arrange(@$slides.eq(targetIndex))
        @transitioning = false
        if (direction == 1 && targetIndex == 0) || (direction == -1 && targetIndex == @slidesCount - 1)
          @moveBy(0, true)
      )
      if @$pages? then @$pages.removeClass("active").eq(targetIndex).addClass("active")

    forth: ->
      @go(@$slides.filter(".next").index(), 1)

    back: ->
      @go(@$slides.filter(".prev").index(), -1)

    arrange: ($currentSlide) ->
      $prevSlide = if $currentSlide.prev().length then $currentSlide.prev() else @$slides.last()
      $nextSlide = if $currentSlide.next().length then $currentSlide.next() else @$slides.first()
      @currentIndex = $currentSlide.index()
      @$slides.removeClass("current prev next target last-child")
      $currentSlide.addClass("current")
      $prevSlide.addClass("prev").filter(":last-child").addClass("last-child")
      $nextSlide.addClass("next")

  @initialize = ->
    @instances = []
    self = this
    $doc.find(".js_stage_slider").each ->
      self.instances.push(new StageSlider(this))

  @initialize()
)($(window), $(document))
