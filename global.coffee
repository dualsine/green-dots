window.onload = =>
  window.graphics = new Graphics()

  document.addEventListener("keydown", (e) ->
    if e.keyCode == 37 #left arrow
      graphics.prevSlide()
    else if e.keyCode == 39 #right arrow
      graphics.nextSlide()
  , false)

  new Hammer( document.body ).on 'swipeleft swiperight', (e) ->
    if e.type=='swiperight' then graphics.prevSlide()
    else if e.type=='swipeleft' then graphics.nextSlide()
  return

class Graphics
  constructor: ->
    @spheres = []
    @gray_image = []
    @count = 0
    @settings = {
      slide: 0,
      slide_max: 4,
      scale: 0.01,
      pinch_x: 0,
      pinch_y: 0,
      ease: Power2.easeOut,
      camera_x: 0,
      camera_y: 50,
      camera_z: 1000,
      space: 100,
      amount_x: 60,
      amount_z: 40,
      img_scale: 0,
      stop: false,
      color: "#91e70b",
      clear_color: "#000000",
      play_animation: false,
      frame: 0
    }
    
    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera( 75, window.innerWidth/window.innerHeight, 0.1, 10000 )
    @camera.position.z = @settings.camera_z
    @camera.position.y = @settings.camera_y

    @renderer= new THREE.CanvasRenderer()
    @context = @renderer.domElement.getContext('2d')
        
    @renderer.setClearColor( @settings.clear_color )
    @renderer.setSize( window.innerWidth, window.innerHeight )
    @renderer.setPixelRatio( window.devicePixelRatio )
    @renderer.shadowMapEnabled = true
    @renderer.shadowMapType = THREE.PCFSoftShadowMap

    @renderer.domElement.id = "dots"
    document.body.appendChild( @renderer.domElement )

    @insertDots()

    @gray_image = @grayImage('anim')

    setTimeout =>
      @changeSlide()
    , 100

    window.addEventListener 'resize', =>
      @resize()
    , false

    @render()
    return

  resize: =>
    @renderer.setSize( window.innerWidth, window.innerHeight )
    @camera.aspect = window.innerWidth / window.innerHeight
    @camera.updateProjectionMatrix()
    return

  render: =>
    requestAnimationFrame( @render )
    
    @context.clearRect(0, 0, window.innerWidth, window.innerHeight)

    @camera.position.x = @settings.camera_x
    @camera.position.y = @settings.camera_y
    @camera.position.z = @settings.camera_z
    @camera.lookAt( @scene.position )

    @renderAnimation( @gray_image )

    @counter = 0
    for x in [0..@settings.amount_x]
      for z in [0..@settings.amount_z]
        sphere_all = @spheres[ @counter++ ]
        sphere = sphere_all.obj
        sphere.position.y = ( Math.sin( ( x + @count ) * 0.3 ) * 50 ) * @settings.pinch_x + ( Math.sin( ( z + @count ) * 0.5 ) * 50 ) * @settings.pinch_y
        sphere.scale.x = sphere.scale.y = (sphere_all.fixed_scale * @settings.img_scale) + ( Math.sin( ( x + @count ) * 0.3 ) + 1 ) * 4 * @settings.scale + ( Math.sin( ( z + @count ) * 0.5 ) + 1 ) * 4 * @settings.scale
    
    @renderer.render(@scene, @camera)

    @count += 0.1

    return

  nextSlide: ->
    if @settings.slide < @settings.slide_max then @settings.slide++; @changeSlide()

  prevSlide: ->
    if @settings.slide > 0 then @settings.slide--; @changeSlide()

  changeSlide: ->
    if @settings.slide == 0
      TweenMax.to('.info', 2, {opacity:1})
      TweenMax.to(@settings, 5, {scale:0.01})
    else if @settings.slide == 1
      TweenMax.to('.info', 0.4, {opacity:0})
      TweenMax.to(@settings, 5, {scale:1})
      TweenMax.to(@settings, 1, {pinch_x:0, ease: @settings.ease})
    else if @settings.slide == 2
      TweenMax.to(@settings, 1, {pinch_x:1, pinch_y:0,ease: @settings.ease})
      TweenMax.to(@settings, 4, {camera_y: 200, camera_z: 1000})
    else if @settings.slide == 3
      TweenMax.to(@settings, 1, {pinch_y:1, ease: @settings.ease})
      TweenMax.to(@settings, 4, {camera_y: 200})
      
      TweenMax.to(@settings, 4, {img_scale: 0, camera_z: 1000})
    else if @settings.slide == 4      
      @settings.play_animation = true
      TweenMax.to(@settings, 1, {pinch_x:1, pinch_y:1, ease: @settings.ease})
      TweenMax.to(@settings, 4, {camera_y: 1850, camera_z: 2900, img_scale: 1, onComplete: =>
        TweenMax.to(@settings, 4, {camera_y: 5000, camera_z: 100})
      })
    return

  grayImage: (id) ->
    array = []
    img = document.getElementById(id)
    canvas = document.createElement('canvas')
    canvas.width = img.width
    canvas.height = img.height
    canvas.getContext('2d').drawImage(img, 0, 0, img.width, img.height)
    for x in [0..img.width-1]
      for y in [0..img.height-1]
        pixelData = canvas.getContext('2d').getImageData(x, y, 1, 1).data
        array.push (pixelData[0]/255 + pixelData[1]/255 + pixelData[2]/255) / 3

    img_height = img.height
    row_array = []
    normalized = []
    counter = 1
    for p in array
      row_array.push p
      if counter++ >= img_height
        normalized.push row_array
        counter = 1
        row_array = []
    return normalized

  insertDots: ->
    @material = new THREE.SpriteCanvasMaterial {
      color: @settings.color,
      program: () =>
        @context.beginPath()
        @context.arc(0, 0, 0.5, 0, Math.PI*2, true)
        @context.fill()
        return
    }

    for x in [0..@settings.amount_x]
      for z in [0..@settings.amount_z]
        sphere = new THREE.Sprite( @material )
        @spheres.push {
          obj: sphere,
          fixed_scale: null
        }
        sphere.position.x = x * @settings.space - ( ( @settings.amount_x * @settings.space ) / 2 )
        sphere.position.z = z * @settings.space - ( ( @settings.amount_z * @settings.space ) / 2 )
        @scene.add sphere
    return

  renderAnimation: (array) ->
    if !@settings.play_animation then return
    
    frame_array = []
    start = @settings.frame++
    limit = (array.length - @settings.amount_x)
    if start > limit
      diff = start - limit
      temp_array = array.slice( start, start+@settings.amount_x ).concat array.slice( 0, 0+diff )
      if diff > @settings.amount_x
        return @settings.frame=0
    else
      temp_array = array.slice( start, start+@settings.amount_x )
      
    for row in temp_array
      for pixel in row
        frame_array.push pixel

    counter=0
    for x in [0..@settings.amount_x]
      for z in [0..@settings.amount_z]
        sphere = @spheres[counter]
        sphere.fixed_scale = frame_array[counter++] * 50
    return
