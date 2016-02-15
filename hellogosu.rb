require 'chipmunk'
require 'gosu'

SCREEN_WIDTH = 1200
SCREEN_HEIGHT = 700
STREAM_LEFT_BORDER = 150
STREAM_RIGHT_BORDER = 700
HOW_MANY_BALLS = 2000
HOW_MANY_BOXES = 100

GRID = true

RED = Gosu::Color.argb(0xff_ff0000)
CYAN = Gosu::Color.argb(0xff_00ffff)
GREY = Gosu::Color.argb(0xff_111111)
WHITE = Gosu::Color.argb(0xff_ffffff)

class Ball

  attr_reader :body, :shape
  def initialize(mass, friction, scale=1, moment_mod=1)
    @scale = scale.to_f
    @radius = 5 * @scale
    @delete = false
    @mass = mass.to_f
    @moment = CP.moment_for_circle(@mass, 0, @radius, CP::Vec2::ZERO) * moment_mod
    @body = CP::Body.new(@mass, @moment)
    @body.p = vec2(0, 0)
    @shape = CP::Shape::Circle.new(@body, @radius, CP::Vec2::ZERO)
    @shape.u = friction
    @image = Gosu::Image.new('circle10px.png')
  end

  def delete?
    @delete
  end

  def update
    @delete = true if @body.p.y > SCREEN_HEIGHT
  end

  def draw
    @image.draw_rot(@body.p.x, @body.p.y, 1, @body.a.radians_to_gosu, 0.5, 0.5, @scale, @scale)
  end

end

class StaticLine

  attr_reader :shape
  def initialize(begin_point, end_point, friction=1)
    @begin_point = begin_point
    @end_point = end_point
    @body = CP::Body.new_static()
    @shape = CP::Shape::Segment.new(@body, @begin_point, @end_point, 3)
    @shape.u = friction
  end

  def draw
    Gosu.draw_line(@begin_point.x, @begin_point.y, CYAN, @end_point.x, @end_point.y, RED)
  end

end

class Box
  attr_reader :body, :shape

  def initialize(width, height, color=WHITE, mass=2, moment_mod=1)
    @width = width.to_f
    @height = height.to_f
    @delete = false
    @mass = mass.to_f
    @moment = CP.moment_for_box(@mass, @width, @height) * moment_mod
    @body = CP::Body.new(@mass, @moment)
    @body.p = vec2(100, 100)
    # verts = [ vec2(-@width/2, -@height), vec2(-@width/2, @height/2), vec2(@width/2, @height/2), vec2(@width/2, -@height/2) ]
    verts = [ vec2(-@height/2, -@width/2), vec2(-@height/2, @width/2), vec2(@height/2, @width/2), vec2(@height/2, -@width/2) ]

    @shape = CP::Shape::Poly.new(@body, verts, CP::Vec2::ZERO)
    @shape.u = 0.5
    @image = Gosu::Image.new('line10x10px.png')
    @body.a = (3*Math::PI/2.0)
  end

  def update
    @delete = true if @body.p.y > SCREEN_HEIGHT
  end

  def delete?
    @delete
  end

  def draw
    @image.draw_rot(@body.p.x, @body.p.y, 1, @body.a.radians_to_gosu, 0.5, 0.5, @width/10, @height/10)
  end

end

class Game < Gosu::Window

  def initialize
    super SCREEN_WIDTH, SCREEN_HEIGHT
    @gravity = vec2(0, 90)
    @space = CP::Space.new
    @space.gravity = @gravity
    @space.iterations = 15

    @objects = []
    @static_lines = []

    new_static_line StaticLine.new( vec2(250, 420), vec2(400, 400) )
    new_static_line StaticLine.new( vec2(700, 340), vec2(250, 580) )
    new_static_line StaticLine.new( vec2(200, 340), vec2(150, 480) )
    new_static_line StaticLine.new( vec2(290, 50), vec2(310, 280) )
    new_static_line StaticLine.new( vec2(610, 50), vec2(590, 280) )

    HOW_MANY_BALLS.times do
      new_ball Ball.new( rand(0.1..0.2), rand(0.5..0.7), rand(0.75..1.2) ), vec2(rand(STREAM_LEFT_BORDER..STREAM_RIGHT_BORDER), rand(-5000..50))
    end
    HOW_MANY_BOXES.times do
      new_ball Box.new( rand(20.0..40.0), rand(20.0..40.0), mass=rand(0.75..10.0) ), vec2(rand(STREAM_LEFT_BORDER..STREAM_RIGHT_BORDER), rand(-5000..50))
    end

    test_box = Box.new( 5, 80 )
    new_box test_box, vec2(400, 450)

    pin = CP::Constraint::PinJoint.new(test_box.body, CP::Body.new_static(), vec2(40.0, 0.0), vec2(400, 405))
    @space.add_constraint pin

    @timeStep = 1.0/60.0
  end

  def new_ball(ball, position)
    @space.add_body ball.body
    ball.body.p = position
    @space.add_shape ball.shape
    @objects << ball
  end

  def new_box(box, position)
    @space.add_body box.body
    box.body.p = position
    @space.add_shape box.shape
    @objects << box
  end

  def new_static_line(line)
    @space.add_shape(line.shape)
    @static_lines << line

  end

  def update
    objects_to_delete = []
    @space.step(@timeStep)
    @objects.each do |object|
      object.update
      if object.delete?
        objects_to_delete << object
        @space.remove_body object.body
        @space.remove_shape object.shape
      end
    end
    @objects -= objects_to_delete
    puts "#{@objects.size} - nonstatic objects"
  end

  def draw
    if GRID
      (0..SCREEN_WIDTH).step(100) do |x|
        Gosu.draw_line(x, -0 + SCREEN_HEIGHT, GREY, x, -SCREEN_HEIGHT + SCREEN_HEIGHT, GREY)
      end
      (0..SCREEN_HEIGHT).step(100) do |y|
        Gosu.draw_line(0, -y + SCREEN_HEIGHT, GREY, SCREEN_WIDTH, -y + SCREEN_HEIGHT, GREY)
      end
    end
    @objects.each { |object| object.draw }

    @static_lines.each { |line| line.draw }
  end

end

g = Game.new
g.show
