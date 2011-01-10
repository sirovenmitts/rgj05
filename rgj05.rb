#!/usr/bin/env ruby
require 'gosu'
include Gosu
TIMELINE_HEIGHT = 50
module ZOrder
	Background = 1
	Models = 2
	Text = 4
	EndGame = 8
end
class Text
	@@fonts = {}
	def self.print message, x, y, text_size = :small
		self.method(text_size).call.draw message, x, y, ZOrder::Text, 1, 1, Color::BLACK
	end
	%w(small medium large).each_with_index do |m, i|
		define_singleton_method(m) do
			@@fonts[m] ||= Font.new RGJ05.window, 'RetroVille NC', 10 * (i + 1)
		end
	end
end
class RGJ05 < Window
	attr_accessor :score
	def self.window
		ObjectSpace.each_object(RGJ05).first
	end
	%w(width height).each {|m| define_singleton_method(m) {window.send m}}
	def initialize
		super 640, 480, false
		@actions = []
		@last_action_pushed = 0
		@reticle = Image.new self, 'reticle.png', false
		@bear = Bear.new
		@bird = Bird.new
		@tourist = Image.new self, 'tourist.png', false
		@high_five = Image.new self, 'tourist_high_five.png', false
		@hearts = []
		@action_queue = 100.times.inject([]) {|m, _| m.push [:hug, :high_five, :love_beam].sample}
		@score = 0
		@delay = 2000
		@speed = 2000.0
		@sky_blue = Color.new 255, 173, 216, 230
		@dodger_blue = Color.new 255, 30, 144, 255
		@lawn_green = Color.new 255, 124, 252, 0
		@misses = 0
	end
	def update
		@actions.each(&:update)
		@actions.delete_if {|a| a.x <= -width / 2}
		if milliseconds - @last_action_pushed > @delay && @bear.up_to_speed
			@actions.push Action.new @speed, @action_queue.shift
			@last_action_pushed = milliseconds
		end
		@bear.up_to_speed = true if @bear.pushes > 9
		@bear.update
		@delay = 1500 and @speed = 1900.0 if @score > 1000
		@delay = 1000 and @speed = 1800.0 if @score > 2000
		if @misses >= 5
			@bear.up_to_speed = false
			@misses = 0
			@bear.pushes = 0
		end
		@bird.update
		@hearts.each(&:update)
		@hearts.delete_if {|h| h.y >= height}
		@actions.each {|a| a.attempted = true if a.x <= 0}
	end
	def draw
		draw_quad(
			0, 0, @sky_blue,
			width, 0, @sky_blue,
			width, height, @dodger_blue,
			0, height, @dodger_blue,
			ZOrder::Background)
		draw_quad(
			0, height / 2, @lawn_green,
			width, height / 2, @lawn_green,
			width, height, @lawn_green,
			0, height, @lawn_green,
			ZOrder::Background)
		draw_quad(
			0, height - TIMELINE_HEIGHT - 15, Color::GRAY,
			width, height - TIMELINE_HEIGHT - 15, Color::GRAY,
			width, height - TIMELINE_HEIGHT + 15, Color::GRAY,
			0, height - TIMELINE_HEIGHT + 15, Color::GRAY,
			ZOrder::Background)
		unless @bear.up_to_speed
			msg = 'GET UP TO SPEED!'
			Text.print msg, width / 2 - Text.medium.text_width(msg) / 2, 50, :medium
			Text.print @bear.pushes, width / 2 + Text.medium.text_width(msg) / 2 + 10, 50, :medium
		end
		translate width / 2, height - TIMELINE_HEIGHT do
			scale 2, 2 do
				translate -@reticle.width / 2, -@reticle.height / 2 do
					@reticle.draw 0, 0, ZOrder::Models
				end
			end
		end
		@actions.each do |a|
			translate a.x, RGJ05.height - TIMELINE_HEIGHT do
				scale 1.5, 1.5 do
					translate -a.image.width / 2, -a.image.height / 2 do
						if a.attempted
							if a.success
								draw_quad(
									0, 0, Color::GREEN,
									20, 0, Color::GREEN,
									20, 20, Color::GREEN,
									0, 20, Color::GREEN,
									ZOrder::Models - 1)
							else
								draw_quad(
									0, 0, Color::RED,
									20, 0, Color::RED,
									20, 20, Color::RED,
									0, 20, Color::RED,
									ZOrder::Models - 1)
							end
						end
						a.image.draw 0, 0, ZOrder::Models
						text = a.action_type.to_s.tr('_', ' ')
						Text.print text, -Text.small.text_width(text) / 2 + a.image.width / 2, 5
					end
				end
			end
		end
		translate width / 2, height / 2 do
			scale 2, 2 do
				translate -@bear.image.width / 2, -@bear.image.height / 2 do
					@bear.image.draw 0, 0, ZOrder::Models + 1
				end
			end
		end
		Text.print 'h to hug', 10, 10
		Text.print 'f to high five', 10, 20
		Text.print 'z to love beam', 10, 30
		Text.print 'alternate l and r to get up to speed!', 10, 40
		Text.print "you have #{@score} points! Keep up the love!", 10, 50 if @bear.up_to_speed
		Text.print "Uh-oh, you have missed #{@misses} times!", 10, 60 if @misses > 0
		action = @actions.detect {|a| a.action_type == :love_beam}
		if action && action.action_type == :love_beam && action.attempted && action.success
			if action.x < width && action.x > 0
				draw_line RGJ05.width / 2, RGJ05.height / 2, Color::RED, RGJ05.width - rand() * 20, 0, Color::YELLOW, ZOrder::Models
				draw_line RGJ05.width / 2, RGJ05.height / 2, Color::RED, RGJ05.width - rand() * 20, 0, Color::RED, ZOrder::Models
				draw_line RGJ05.width / 2, RGJ05.height / 2, Color::RED, RGJ05.width - rand() * 30, 0, Color::BLUE, ZOrder::Models
			end
		end
		@actions.select {|a| a.action_type == :love_beam}.each do |a|
			if a.success && a.x <= width / 4
				if a.x >= 0
					translate width * 3 / 4 + @bird.image.width / 2, 100 do
						rotate milliseconds do
							translate -@bird.image.width / 2, -@bird.image.height / 2 do
								@bird.image.draw 0, 0, ZOrder::Models
								@hearts.push Heart.new width * 3 / 4 + @bird.image.width / 2 + (rand() * 10) - 5, 100 + (rand() * 10) - 5
							end
						end
					end
				end
			else
				@bird.image.draw a.x + width / 2, 100, ZOrder::Models
			end
		end
		@actions.select {|a| a.action_type == :hug}.each do |a|
			if a.success && a.x <= 0
				@bear.triggered = false
				translate a.x + width / 2, height / 2 - 20 do
					rotate 50 do
						scale 0.05, 0.05 do
							translate -@tourist.width / 2, -@tourist.height / 2 do
								@tourist.draw 0, 0, ZOrder::Models
								@hearts.push Heart.new a.x + width / 2 + (rand() * 10) - 5, height / 2 - 20 + (rand() * 10) - 5
							end
						end
					end
				end
			elsif a.success && a.x <= width / 5 && a.x > 0 && @bear.triggered == false
				@bear.triggered = true
				@bear.state = :hug
				@bear.frame = 5
			else
				translate a.x + width / 2, height / 2 - 20 do
					scale 0.05, 0.05 do
						translate -@tourist.width / 2, -@tourist.height / 2 do
							@tourist.draw 0, 0, ZOrder::Models
						end
					end
				end
			end
		end
		@actions.select {|a| a.action_type == :high_five}.each do |a|
			if a.success && a.x <= 0
				@bear.triggered = false
				translate a.x + width / 2, height / 2 - 20 do
					rotate 50 do
						scale 0.05, 0.05 do
							translate -@high_five.width / 2, -@high_five.height / 2 do
								@high_five.draw 0, 0, ZOrder::Models
								@hearts.push Heart.new a.x + width / 2 + (rand() * 10) - 5, height / 2 - 20 - 20
							end
						end
					end
				end
			elsif a.success && a.x <= width / 5 && a.x > 0 && @bear.triggered == false	
				unless @bear.state == :high_five
					@bear.triggered = true
					@bear.state = :high_five
					@bear.frame = 11
				end
			else
				translate a.x + width / 2, height / 2 - 20 do
					scale 0.05, 0.05 do
						translate -@high_five.width / 2, -@high_five.height / 2 do
							@high_five.draw 0, 0, ZOrder::Models
						end
					end
				end
			end
		end
		@hearts.each do |h|
			h.image.draw h.x, h.y, ZOrder::Models + 2
		end
		if @score >= 2000
			draw_quad(
				0, 0, Color::WHITE,
				width, 0, Color::RED,
				width, height, Color::GREEN,
				0, height, Color::BLUE,
				ZOrder::EndGame)
			rotate 10 do
				@tourist.draw 0, 0, ZOrder::EndGame
			end
			# Text.print 'GOOD JOB! I LOVE YOU!', 300, 100
			# I have to manually draw this text
			Text.small.draw 'GOOD JOB! I LOVE YOU!', 300, 100, ZOrder::EndGame + 1, 1, 1, Color::BLACK
		end
	end
	def button_down id
		if id == KbL && !@bear.up_to_speed
			if @bear.last_foot == :right
				@bear.last_foot = :left
				@bear.pushes += 1
				@bear.last_push = milliseconds
			else
				@bear.pushes = 0
			end
		end
		if id == KbR && !@bear.up_to_speed
			if @bear.last_foot == :left
				@bear.last_foot = :right
				@bear.pushes += 1
				@bear.last_push = milliseconds
			else
				@bear.pushes = 0
			end
		end
		if @bear.up_to_speed
			action = @actions.detect {|a| !a.attempted}
			if action
				action.attempted = true
				lower, upper = RGJ05.width / 2 - 20, RGJ05.width / 2 + 20
				@misses += 1
				case id
					when KbH then
						if action.action_type == :hug
							if action.x < upper && action.x > lower
								@score += 100
								action.success = true
								@misses = 0
							end
						end
					when KbF then
						if action.action_type == :high_five
							if action.x < upper && action.x > lower
								@score += 100
								action.success = true
								@misses = 0
							end
						end
					when KbZ then
						if action.action_type == :love_beam
							if action.x < upper && action.x > lower
								@score += 100
								action.success = true
								@misses = 0
							end
						end
				end
			end
		end
		close if id == KbEscape
	end
end
class Action
	attr_accessor :x, :image, :action_type, :attempted, :success, :spawned
	def initialize length, action_type
		@start, @length, @action_type = milliseconds, length, action_type
		@image = Image.new RGJ05.window, 'box.png', false
		@x = RGJ05.width
		@attempted = false
		@success = false
		@spawned = false
	end
	def update
		@x = RGJ05.width - (RGJ05.width * (milliseconds - @start) / @length)
	end
end
class Bear
	attr_accessor :up_to_speed, :last_foot, :pushes, :last_push, :state, :states, :frame, :triggered, :images
	def initialize
		@images = Image.load_tiles RGJ05.window, 'bear.png', 20, 40, false
		@up_to_speed = false
		@last_foot = :right
		@pushes = 0
		@frame = 0
		@states = {standing: 0..0, walk_left: 1...4, walk_right: 4...6, walking: 1..7, hug: 5..11, high_five: 11..15}
		@state = :standing
		@last_update = 0
		@delay = 100
		@last_push = 0
		@triggered = false
		@last_state = @state
	end
	def image
		@images[@frame]
	end
	def update
		if @up_to_speed || milliseconds  - @last_push < 400
			@state = :walking unless @state == :hug || @state == :high_five
			next_frame
		else
			@state = :standing
			@frame = 0
			@last_foot = :right
			@pushes = 0
		end
	end
	def next_frame
		animate! and @last_update = milliseconds if milliseconds - @last_update > @delay
	end
	def animate!
		(@frame >= @states[@state].max - 1 ? animation_complete : @frame += 1)
	end
	def animation_complete
		if @state == :high_five || @state == :hug
			if @up_to_speed
				@state = :walking
			else
				@state = :standing
			end
		end
		@frame = @states[@state].min
	end
end
class Bird
	def initialize
		@images = Image.load_tiles RGJ05.window, 'bird.png', 20, 20, false
		@frame = 0
		@states = {flying: 0...4}
		@state = :flying
		@last_update = 0
		@delay = 100
	end
	def image
		@images[@frame]
	end
	def update
		next_frame
	end
	def next_frame
		animate! and @last_update = milliseconds if milliseconds - @last_update > @delay
	end
	def animate!
		(@frame >= @states[@state].max - 1 ? animation_complete : @frame += 1)
	end
	def animation_complete
		@frame = @states[@state].min
	end
end
class Heart
	attr_accessor :x, :y
	attr_reader :image
	def initialize x, y
		@x, @y = x, y
		@vx, @vy = -(rand() * 10) - 20, -(rand() * 10)
		@image = Image.new RGJ05.window, 'heart.png', false
	end
	def update
		@vy += 1
		@y += @vy
		@x += @vx
		@vx *= 0.99
		@vy = 10 if @vy >= 10
	end
end
RGJ05.new.show